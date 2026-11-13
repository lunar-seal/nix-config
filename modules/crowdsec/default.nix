{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.crowdsecProtection;
  bouncer = config.services.crowdsec-firewall-bouncer.settings;
  ports = lib.concatMapStringsSep ", " toString cfg.protectedTCPPorts;
in
{
  options.services.crowdsecProtection = {
    protectedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        22
        80
        443
      ];
      description = "TCP ports subject to CrowdSec decisions; VPN transport remains reachable.";
    };
    staticMediaPaths = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Per-domain path regexes for missing static media, excluded from HTTP probing counts.";
    };
  };
  config = {
    services.openssh.settings.LogLevel = lib.mkDefault "VERBOSE";
    services.crowdsec = {
      enable = lib.mkDefault true;
      autoUpdateService = true;
      hub.collections = [
        "crowdsecurity/linux"
        "crowdsecurity/sshd"
        "crowdsecurity/traefik"
      ];
      settings = {
        config.api.server = {
          listen_uri = "127.0.0.1:8080";
          online_client.credentials_path = "${config.services.crowdsec.settings.config.config_paths.data_dir}/online_api_credentials.yaml";
        };
        parsers.s02Enrich = lib.mapAttrsToList (domain: paths: {
          name = "local/static-media-${builtins.hashString "sha256" domain}";
          description = "Ignore missing application images, not general missing pages";
          filter =
            "evt.Meta.service == 'http' && evt.Meta.http_status == '404' && evt.Meta.target_fqdn == ${builtins.toJSON domain} && ("
            + lib.concatMapStringsSep " || " (path: "evt.Meta.http_path matches ${builtins.toJSON path}") paths
            + ")";
          # Exempt only this matching event, never the client's other requests.
          whitelist = {
            reason = "missing application image";
            expression = [ "true" ];
          };
        }) cfg.staticMediaPaths;
        acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=traefik.service" ];
            # journalctl adds a syslog envelope; strip it before parsing JSON.
            labels.type = "syslog";
          }
        ];
      };
    };
    # Registration generates the API key at runtime, outside the Nix store.
    services.crowdsec-firewall-bouncer = {
      enable = true;
      createRulesets = false;
      settings.mode = "nftables";
    };
    networking.nftables.tables = {
      ${bouncer.nftables.ipv4.table} = {
        family = "ip";
        content = ''
          set crowdsec-blacklists {
            type ipv4_addr
            flags timeout
          }
          chain ${bouncer.nftables.ipv4.chain} {
            type filter hook input priority filter; policy accept;
            tcp dport { ${ports} } ip saddr @crowdsec-blacklists drop
          }
        '';
      };
      ${bouncer.nftables.ipv6.table} = {
        family = "ip6";
        content = ''
          set crowdsec6-blacklists {
            type ipv6_addr
            flags timeout
          }
          chain ${bouncer.nftables.ipv6.chain} {
            type filter hook input priority filter; policy accept;
            tcp dport { ${ports} } ip6 saddr @crowdsec6-blacklists drop
          }
        '';
      };
    };
    # The upstream module writes settings via tmpfiles; restart to load changes.
    systemd.services.crowdsec.restartTriggers = [
      (pkgs.writeText "crowdsec-settings.json" (builtins.toJSON config.services.crowdsec.settings))
    ];
  };
}

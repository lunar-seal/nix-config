{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.crowdsecProtection;
  traefikLogFile = config.services.traefik.staticConfigOptions.accessLog.filePath or "";
  traefikLogsToFile = config.services.traefik.enable && traefikLogFile != "";
in
{
  options.services.crowdsecProtection = {
    staticMediaPaths = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Per-domain path regexes for missing static media, excluded from HTTP probing counts.";
    };
  };
  config = lib.mkIf config.services.crowdsec.enable {
    services.openssh.settings.LogLevel = lib.mkIf config.services.openssh.enable (
      lib.mkDefault "VERBOSE"
    );
    services.traefik.staticConfigOptions.accessLog = lib.mkIf config.services.traefik.enable {
      format = lib.mkDefault "json";
      bufferingSize = lib.mkDefault 0;
      fields.headers = {
        defaultMode = lib.mkDefault "drop";
        names.User-Agent = lib.mkDefault "keep";
      };
    };
    users.users.${config.services.crowdsec.user}.extraGroups =
      lib.optional traefikLogsToFile config.services.traefik.group;
    services.crowdsec = {
      autoUpdateService = true;
      readOnlyPaths = lib.optional traefikLogsToFile traefikLogFile;
      hub.collections = [
        "crowdsecurity/linux"
      ]
      ++ lib.optional config.services.openssh.enable "crowdsecurity/sshd"
      ++ lib.optional config.services.traefik.enable "crowdsecurity/traefik";
      settings = {
        config.api.server = {
          listen_uri = "127.0.0.1:8080";
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
        acquisitions =
          lib.optional config.services.openssh.enable {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
          ++ lib.optional config.services.traefik.enable (
            if traefikLogsToFile then
              {
                source = "file";
                filenames = [ traefikLogFile ];
                labels.type = "traefik";
              }
            else
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=traefik.service" ];
                # journalctl adds a syslog envelope; strip it before parsing JSON.
                labels.type = "syslog";
              }
          );
      };
    };
    # The deployment supplies existing credentials via the native secret options.
    services.crowdsec-firewall-bouncer = {
      enable = true;
      createRulesets = true;
      settings.mode = "nftables";
    };
    # Fail before upstream setup can generate replacement deployment credentials.
    systemd.services.crowdsec-setup.preStart = ''
      test -s ${lib.escapeShellArg config.services.crowdsec.settings.config.api.client.credentials_path}
      ${lib.optionalString
        (config.services.crowdsec.settings.config.api.server.online_client.credentials_path != null)
        ''
          test -s ${lib.escapeShellArg config.services.crowdsec.settings.config.api.server.online_client.credentials_path}
        ''
      }
    '';
    # The upstream module writes settings via tmpfiles; restart to load changes.
    systemd.services.crowdsec.restartTriggers = [
      (pkgs.writeText "crowdsec-settings.json" (builtins.toJSON config.services.crowdsec.settings))
    ];
  };
}

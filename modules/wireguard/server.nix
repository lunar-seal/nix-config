{ config, lib, ... }:
let
  interfaces = config.services.wireguardHub.interfaces;
  names = lib.concatMapStringsSep ", " builtins.toJSON (builtins.attrNames interfaces);
in
{
  options.services.wireguardHub.interfaces = lib.mkOption {
    type = lib.types.attrs;
    description = "WireGuard server interfaces and peers supplied by the deployment.";
  };
  options.services.wireguardHub.uplink = lib.mkOption {
    type = lib.types.str;
    description = "Interface accepting WireGuard connections.";
  };
  config = {
    networking.wg-quick.interfaces = interfaces;
    systemd.services = lib.mapAttrs' (
      name: value:
      lib.nameValuePair "wg-quick-${name}" {
        unitConfig.ConditionPathExists = value.privateKeyFile;
      }
    ) interfaces;

    services.openssh.reachableOn = builtins.attrNames interfaces;
    networking.firewall.interfaces.${config.services.wireguardHub.uplink}.allowedUDPPorts = map (
      interface: interface.listenPort
    ) (builtins.attrValues interfaces);
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    networking.nftables.enable = true;
    # Run before the normal firewall's established/DNAT accepts. A drop here
    # cannot be overridden by an accept in another forward chain.
    networking.nftables.tables.wireguard-no-uplink = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority -10; policy accept;
          iifname { ${names} } oifname ${builtins.toJSON config.services.wireguardHub.uplink} counter drop
        }
      '';
    };
    networking.firewall = {
      filterForward = true;
      # Permit peer routing; the separate chain above prohibits uplink egress.
      extraForwardRules = ''
        iifname { ${names} } oifname { ${names} } accept
      '';
    };
  };
}

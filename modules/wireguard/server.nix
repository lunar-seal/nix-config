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
    systemd.tmpfiles.rules = [
      "d /var/lib/wireguard 0700 root root - -"
    ]
    ++ lib.concatMap (
      value:
      [ "z ${value.privateKeyFile} 0600 root root - -" ]
      ++ map (peer: "z ${peer.presharedKeyFile} 0600 root root - -") (
        builtins.filter (peer: peer ? presharedKeyFile) value.peers
      )
    ) (builtins.attrValues interfaces);
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
    networking.firewall = {
      filterForward = true;
      # Retain VPN peer-to-peer routing, without opening a new internet exit.
      extraForwardRules = ''
        iifname { ${names} } oifname { ${names} } accept
      '';
    };
  };
}

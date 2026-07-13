{ config, lib, ... }:
let
  isVoices = config.networking.hostName == "voices";
in
{
  config = lib.mkIf isVoices {
    # Serve the local store as a binary cache: zstd on the wire, signed
    # narinfos, no separate storage. LAN-only via the firewall below.
    services.harmonia.cache = {
      enable = true;
      signKeyPaths = [ "/var/lib/nix-signing/secret" ];
      settings = {
        bind = "[::]:5000";
        # Preferred over cache.nixos.org (priority 40).
        priority = 30;
      };
    };

    # Also sign at build time so paths carry signatures independent of the
    # serving layer. Provisioned out-of-band: run0 install -D -m 400 \
    #   ~/nix-signing/secret /var/lib/nix-signing/secret
    nix.settings.secret-key-files = [ "/var/lib/nix-signing/secret" ];

    networking.firewall.interfaces.eno2.allowedTCPPorts = [ 5000 ];
  };
}

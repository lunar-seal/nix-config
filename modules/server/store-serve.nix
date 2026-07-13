{ config, lib, ... }:
let
  isVoices = config.networking.hostName == "voices";
in
{
  config = lib.mkIf isVoices {
    # Read-only ssh-ng store access for the other hosts; they authenticate
    # with their host keys (the client side lives in common/core.nix).
    nix.sshServe = {
      enable = true;
      protocol = "ssh-ng";
      keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnN3I/OL9M5oevQ93Cb8fIe6UVo+C/xKLRODt/hi1bq root@moonshield"
        # TODO: decemberflower /etc/ssh/ssh_host_ed25519_key.pub
      ];
    };

    # Sign everything built here so clients can verify substituted paths.
    # Provisioned out-of-band: run0 install -D -m 400 ~/nix-signing/secret \
    #   /var/lib/nix-signing/secret
    nix.settings.secret-key-files = [ "/var/lib/nix-signing/secret" ];
  };
}

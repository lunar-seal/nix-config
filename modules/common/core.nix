{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  # voices serves its store read-only over ssh; it is the binary cache.
  isStoreHost = config.networking.hostName == "voices";
  storeUrl = "ssh-ng://nix-ssh@${config.private.storeHost}";
in
{
  system.stateVersion = "24.05";

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  nix = {
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than 60d";
    };
    settings = {
      auto-optimise-store = true;
      cores = 0;
      max-jobs = "auto";
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = lib.optional (!isStoreHost) storeUrl ++ [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "voices-1:jYqlk3kV3BY58jbWu9uWKO+ieLqVNmN5T/j/4H5VNIc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # The daemon substitutes as root: authenticate to the store host with this
  # machine's host key and pin the server's host key declaratively.
  programs.ssh = lib.mkIf (!isStoreHost) {
    knownHosts.${config.private.storeHost}.publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0rfMYiaYBTgP21DnV5h0y7mePdSqayBfCIlOBfpxWb";
    extraConfig = ''
      Match host ${config.private.storeHost} localuser root
        IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';
  };

  nixpkgs.config.allowUnfree = true;

  documentation.dev.enable = true;

  environment.systemPackages = [ pkgs.git ];

  security = {
    sudo.enable = false;
    doas = {
      enable = true;
      extraRules = [
        {
          persist = true;
          users = [ user ];
        }
      ];
    };
  };
}

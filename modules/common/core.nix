{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  # voices serves its store via harmonia; it is the binary cache. Signed
  # narinfos make plain http fine, and the port is LAN-only anyway.
  isStoreHost = config.networking.hostName == "voices";
  storeUrl = "http://${config.private.storeHost}:5000";
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

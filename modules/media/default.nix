{ pkgs, ... }:
let
  kodi = pkgs.kodi-gbm.withPackages (addons: [
    addons.youtube
    (pkgs.callPackage ./tubecast.nix { inherit addons; })
  ]);
in
{
  # Run directly on DRM/GBM: no desktop, compositor, or sound server.
  environment.systemPackages = [ kodi ];
  # greetd otherwise enables the generic desktop defaults (including PipeWire).
  services.displayManager.enable = false;
  hardware.alsa.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  users.users.kodi = {
    isNormalUser = true;
    extraGroups = [
      "audio"
      "video"
      "render"
      "input"
    ];
  };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${kodi}/bin/kodi-standalone --windowing=gbm";
      user = "kodi";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/kodi/.kodi 0700 kodi users - -"
    "d /home/kodi/.kodi/userdata 0700 kodi users - -"
  ];

  # Kodi publishes its remote-control service for Android/Kore discovery.
  services.avahi = {
    enable = true;
    publish.enable = true;
    openFirewall = false;
  };
}

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bluez
    iw
    wirelesstools
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    IPv6.Enabled = true;
    Settings.AutoConnect = true;
    Station = {
      RoamThreshold = -75;
      RoamThreshold5G = -80;
      EnableNetworkConfigurationControl = true;
    };
  };
}

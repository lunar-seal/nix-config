{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.brightnessctl
    pkgs.upower
  ];

  services.upower.enable = true;
}

{ config, ... }:
{
  # Expose external monitor brightness through the standard backlight interface
  # used by brightnessctl and Waybar. Import on hosts that need DDC/CI support.
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [ "ddcci_backlight" ];
}

{ config, ... }:
{
  # Expose external monitor brightness through the standard backlight interface
  # used by brightnessctl and Waybar, including monitors connected to laptops.
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [ "ddcci_backlight" ];
}

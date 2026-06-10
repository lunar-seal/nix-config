{ pkgs, user, ... }:
{
  users.users.${user}.extraGroups = [ "adbusers" ];

  environment.systemPackages = [ pkgs.android-tools ];

  home-manager.users.${user}.home.packages = with pkgs; [
    android-studio
    apktool
    apksigner
    android-studio-tools
  ];
}

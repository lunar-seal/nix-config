{ pkgs, user, ... }:
{
  users.users.${user}.extraGroups = [ "adbusers" ];

  environment.systemPackages = [ pkgs.android-tools ];

  home-manager.users.${user}.home.packages = with pkgs; [
    apktool
    apksigner
  ];
}

{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;

  xdg.portal.extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
}

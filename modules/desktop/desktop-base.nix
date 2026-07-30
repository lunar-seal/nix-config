{ pkgs, user, ... }:
{
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    autoLogin = {
      enable = false;
      inherit user;
    };
  };
  hardware.graphics.enable = true;

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services.swaylock = { };
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    fira-mono
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    hack-font
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    font-awesome
  ];

  environment.systemPackages = [ pkgs.xwayland-satellite ];

  xdg.portal = {
    enable = true;
    config.common = {
      default = [ "gtk" ];
      # qtile is wlroots-based and sets no XDG_CURRENT_DESKTOP, so screencast
      # must be pinned to the wlr backend or kde/gtk grab it and see no outputs.
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    wlr.enable = true;
  };
}

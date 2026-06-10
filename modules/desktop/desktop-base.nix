{ pkgs, user, ... }:
{
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    autoLogin = {
      enable = true;
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
    config.common.default = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    wlr.enable = true;
  };
}

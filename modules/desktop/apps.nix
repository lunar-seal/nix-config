{ pkgs, user, ... }:
{
  home-manager.users.${user}.home.packages = with pkgs; [
    audacity
    alacritty
    libva-utils
    pavucontrol

    chromium
    discord
    firefox
    signal-desktop
    spotify
    thunderbird

    calibre
    feh
    ffmpeg
    geeqie
    gimp-with-plugins
    handbrake
    imagemagick
    jellyfin-mpv-shim
    jftui
    libreoffice
    mpv
    mupdf
    obsidian
    vlc
    zotero

    jetbrains.clion
    jetbrains.goland
    jetbrains.idea
    jetbrains.pycharm
    jetbrains.rider
    jetbrains.rust-rover
    jetbrains.webstorm

    vscodium
    zed-editor

    osu-lazer-bin
    supertuxkart
  ];
}

{
  pkgs,
  pkgs-stable,
  user,
  ...
}:
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
    pkgs-stable.handbrake
    imagemagick
    jellyfin-mpv-shim
    jftui
    libreoffice
    mpv
    mupdf
    obs-studio
    obsidian
    vlc
    zotero

    jetbrains.goland
    jetbrains.pycharm
    jetbrains.rust-rover
    jetbrains.webstorm
    wireshark

    vscodium
    zed-editor

    osu-lazer-bin
    supertuxkart

    quickemu
  ];
}

{ pkgs, user, ... }:
{
  environment.systemPackages = with pkgs; [
    cacert
    doas-sudo-shim
    fwupd
    lm_sensors
    networkmanager
    ntfs3g
    sbctl
    sox
  ];
  services.fwupd.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home-manager.users.${user}.home.packages = with pkgs; [
    at
    arduino-ide
    binwalk
    borgbackup
    bluetuith
    bubblewrap
    checkmake
    claude-code
    cloc
    cmake
    codex
    comma
    conda
    coreutils-full
    direnv
    file
    fzf
    gcc
    gdu
    gnupg
    git-lfs
    gnumake
    go
    htop
    iftop
    inetutils
    jq
    keyutils
    kubectl
    libarchive
    lolcat
    lz4
    man-pages
    maven
    ncdu
    ninja
    nix-index
    nixpkgs-fmt
    nodejs
    openssl
    pi-coding-agent
    powertop
    python3
    reptyr
    ripgrep
    s3cmd
    squashfsTools
    sshuttle
    tmux
    unzip
    usbutils
    valgrind
    virtualenv
    wget
    wireguard-tools
    xz
    zip
  ];
}

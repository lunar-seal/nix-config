{ pkgs, user, ... }:
{
  environment.systemPackages = with pkgs; [
    cacert
    dig
    doas-sudo-shim
    ethtool
    fwupd
    iperf3
    lm_sensors
    lsof
    networkmanager
    nixd
    ntfs3g
    sbctl
    socat
    sox
    sysstat
    tcpdump
  ];
  services.fwupd.enable = true;
  programs.mtr.enable = true;

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
    fd
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
    lazygit
    libarchive
    lolcat
    lz4
    man-pages
    maven
    mise
    ncdu
    ninja
    nix-index
    nixpkgs-fmt
    nodejs
    openssl
    pi-coding-agent
    powertop
    python3
    rclone
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

{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Default nix-ld list.
      zlib
      zstd
      stdenv.cc.cc
      curl
      openssl
      attr
      libssh
      bzip2
      libxml2
      acl
      libsodium
      util-linux
      xz
      systemd

      # Node/npm native binaries.
      brotli
      c-ares
      icu
      libuv
      nghttp2

      # Desktop/Electron/AppImage compatibility.
      libxcomposite
      libxtst
      libxrandr
      libxext
      libx11
      libxfixes
      libGL
      libva
      pipewire
      libxcb
      libxdamage
      libxshmfence
      libxxf86vm
      libelf
      glib
      gtk2
      networkmanager
      vulkan-loader
      libgbm
      libdrm
      libxcrypt
      coreutils
      pciutils
      zenity

      # Without these some foreign binaries silently fail.
      libxinerama
      libxcursor
      libxrender
      libxscrnsaver
      libxi
      libsm
      libice
      gnome2.GConf
      nspr
      nss
      cups
      libcap
      SDL2
      libusb1
      dbus-glib
      ffmpeg
      libudev0-shim

      # Unity/editor style binaries.
      gtk3
      libnotify
      gsettings-desktop-schemas

      # Game/runtime compatibility.
      libxt
      libxmu
      libogg
      libvorbis
      SDL
      SDL2_image
      glew_1_10
      libidn
      tbb
      flac
      freeglut
      libjpeg
      libpng
      libpng12
      libsamplerate
      libmikmod
      libtheora
      libtiff
      pixman
      speex
      SDL_image
      SDL_ttf
      SDL_mixer
      SDL2_ttf
      SDL2_mixer
      libappindicator-gtk2
      libdbusmenu-gtk2
      libindicator-gtk2
      libcaca
      libcanberra
      libgcrypt
      libvpx
      librsvg
      libxft
      libvdpau

      # Common GUI/audio/system libraries.
      pango
      cairo
      atk
      gdk-pixbuf
      fontconfig
      freetype
      dbus
      alsa-lib
      expat
      libxkbcommon
      libxcrypt-legacy
      libGLU
      fuse
      e2fsprogs
      gmp
      harfbuzz
      libgpg-error
      fribidi

      # GDK pixbuf SVG loader compatibility.
      (runCommand "librsvg-pixbuf-loader" { } ''
        mkdir -p $out/lib/gdk-pixbuf-2.0/2.10.0/loaders
        ln -s "${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader_svg.so" "$out/lib/libpixbufloader-svg.so"
      '')

      # pdfmastereditor and Qt6-style binaries.
      sane-backends
      pkcs11helper
      libpulseaudio
      krb5
      libxcb-cursor
      libxcb-wm
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util

      # Uncomment if you want to use the libraries provided by default in the
      # Steam distribution, but this is quite far from being exhaustive.
      # https://github.com/NixOS/nixpkgs/issues/354513
      (pkgs.runCommand "steamrun-lib" { } "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };
}

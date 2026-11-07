{
  config,
  lib,
  pkgs,
  palette,
  user,
  ...
}:
let
  bar = config.home-manager.users.${user}.programs.waybar;
  template = pkgs.writeText "desktop-waybar-template.json" (
    builtins.toJSON (
      lib.filterAttrs (_: value: value != null) (removeAttrs bar.settings.mainBar [ "modules" ])
    )
  );
  style = pkgs.writeText "desktop-waybar.css" bar.style;
  desktop-bar = pkgs.writeShellApplication {
    name = "desktop-bar";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.niri
      pkgs.systemd
      pkgs.util-linux
      pkgs.waybar
    ];
    text = ''
      export BAR_TEMPLATE=${template} BAR_STYLE=${style}
      export MEDIA_FILTER_DIR=${pkgs.writeTextDir "media_layout.jq" (builtins.readFile ./_helpers/media_layout.jq)}
    ''
    + builtins.readFile ./_helpers/desktop_bar.sh;
  };
in
{
  home-manager.users.${user} = {
    home.packages = [ desktop-bar ];
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      # Layout lives here; feature modules own their settings, styling and hotkeys.
      settings.mainBar = {
        spacing = 4;
        modules-left = [
          "niri/workspaces"
        ];
        modules-center = [
          "mpris"
          "niri/window"
        ];
        modules-right = [
          "custom/local-failures"
          "memory#warning"
          "custom/cpu-pressure"
          "network"
          "privacy"
          "pulseaudio#microphone"
          "pulseaudio"
          "backlight"
          "battery"
          "custom/notifications"
          "clock"
          "tray"
        ];
        tray = {
          spacing = 10;
        };
        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        backlight = {
          format = "{percent}% {icon}";
        };
        network = {
          format = "";
          format-disabled = "";
          tooltip-format-disabled = "Wi-Fi disabled";
          format-wifi = "";
          format-ethernet = "";
          format-linked = "";
          format-disconnected = "⚠";
          tooltip-format = "{ifname}\n{ipaddr}/{cidr}\nGateway: {gwaddr}";
          tooltip-format-wifi = "{essid} · {signalStrength}%\n{ifname} · {ipaddr}/{cidr}\nGateway: {gwaddr}";
          tooltip-format-disconnected = "Network disconnected";
        };
        pulseaudio = {
          format = "{volume}% {icon}";
          format-muted = "muted";
          on-click = "pavucontrol";
        };
      };
      style = ''
        @define-color bar_background ${palette.background};
        @define-color bar_foreground ${palette.bar.foreground};
        @define-color bar_hover ${palette.bar.hover};
        @define-color bar_empty ${palette.bar.empty};
        @define-color bar_border ${palette.bar.border};
        @define-color bar_blink ${palette.bar.blink};
        @define-color status_alert ${palette.alert};
        @define-color status_warning ${palette.warning};
        @define-color status_positive ${palette.positive};
        @define-color status_muted ${palette.muted};
        @define-color status_active ${palette.active};
      ''
      + builtins.readFile ./waybar-style.css;
    };
    systemd.user.services.waybar.Service = {
      # Prefer the adaptive supervisor over Home Manager's fixed bar command.
      ExecStart = lib.mkForce "${desktop-bar}/bin/desktop-bar";
      RuntimeDirectory = "desktop-waybar";
      RuntimeDirectoryMode = "0700";
    };
  };
}

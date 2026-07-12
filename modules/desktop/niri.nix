{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  isMoonshield = config.networking.hostName == "moonshield";
  xwaylandSatellite = lib.getExe pkgs.xwayland-satellite;
in
{
  programs.niri.enable = true;

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    TERMINAL = "alacritty";
  };

  environment.systemPackages = with pkgs; [
    cage
    gamescope
    libsecret
    xwayland-satellite
  ];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      alacritty
      brightnessctl
      fuzzel
      grim
      jq
      libnotify
      playerctl
      slurp
      swaylock
      swaynotificationcenter
      waybar
      wayland-utils
      wl-clipboard
      warpd
    ];

    home.sessionVariables.TERMINAL = "alacritty";

    programs.alacritty = {
      enable = true;
      settings.window.decorations = "None";
    };

    programs.fuzzel = {
      enable = true;
      settings.main = {
        launch-prefix = "niri msg action spawn --";
        terminal = "alacritty -e";
      };
    };

    services.swaync.enable = true;

    # This is the hand-written niri setup from ../nix history, adapted to this
    # repo's built-in NixOS niri module. Keep Alacritty as the terminal anchor.
    xdg.configFile."niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "no"
                  ${lib.optionalString isMoonshield ''options "compose:rwin"''}
              }
              numlock
          }

          mouse {
              accel-speed 1.0
          }

          touchpad {
              tap
              dwt
              natural-scroll
              click-method "clickfinger"
          }

          tablet {
              map-to-output "eDP-1"
          }

          touch {
              map-to-output "eDP-1"
          }
      }

      ${lib.optionalString isMoonshield ''
        output "HDMI-A-1" {
            off
            mode "3840x2160@60"
            position x=0 y=-2160
        }

        output "DisplayPort-0" {
            mode "5120x1440"
            position x=0 y=0
        }
      ''}

      layout {
          gaps 16
          always-center-single-column
          empty-workspace-above-first

          preset-column-widths {
              proportion 0.16667
              proportion 0.25
              proportion 0.33333
              proportion 0.5
              proportion 0.66667
              proportion 0.75
              proportion 0.83333
          }

          default-column-width { proportion 0.33333; }

          focus-ring {
              width 10000
              active-color "#00000055"
          }

          border {
              on
              width 4
          }

          shadow {
              on
          }

          tab-indicator {
              position "top"
              gaps-between-tabs 10
          }

          struts {
              left 64
              right 64
          }
      }

      spawn-at-startup "waybar"

      hotkey-overlay {
          skip-at-startup
      }

      prefer-no-csd
      screenshot-path "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png"

      clipboard {
          disable-primary
      }

      overview {
          zoom 0.5
      }

      xwayland-satellite {
          path "${xwaylandSatellite}"
      }

      switch-events {
          tablet-mode-on { spawn "notify-send" "tablet-mode-on"; }
          tablet-mode-off { spawn "notify-send" "tablet-mode-off"; }
          lid-open { spawn "notify-send" "lid-open"; }
          lid-close { spawn "notify-send" "lid-close"; }
      }

      window-rule {
          draw-border-with-background false
          geometry-corner-radius 8
          clip-to-geometry true
      }

      window-rule {
          match app-id="^Alacritty$" title=r#"^\[oxygen\]"#
          border {
              active-color "#8ec07c"
          }
      }

      window-rule {
          match app-id="^firefox$" title="Private Browsing"
          border {
              active-color "#d3869b"
          }
      }

      window-rule {
          match app-id="^signal$"
          block-out-from "screencast"
      }

      window-rule {
          match app-id="^signal$" title="^Sharing screen$"
          border {
              inactive-color "red"
          }
          open-focused false
          open-floating true
          default-floating-position x=0 y=-60 relative-to="bottom"
      }

      gestures {
          dnd-edge-view-scroll {
              trigger-width 64
              delay-ms 250
              max-speed 12000
          }
      }

      layer-rule {
          match namespace="^swaync-notification-window$"
          block-out-from "screencast"
      }

      layer-rule {
          match namespace="^swww-daemonoverview$"
          place-within-backdrop true
      }

      binds {
          Mod+Return { spawn "alacritty"; }
          Mod+U { spawn "firefox"; }
          Mod+D { spawn "discord"; }
          Mod+G { spawn "steam"; }
          Mod+Space { spawn "fuzzel"; }

          Mod+O { show-hotkey-overlay; }

          Mod+W { close-window; }
          Mod+Shift+W { close-window; }

          Mod+H { focus-column-left; }
          Mod+J { focus-window-down; }
          Mod+K { focus-window-up; }
          Mod+L { focus-column-right; }

          Mod+Shift+H { move-column-left; }
          Mod+Shift+J { move-window-down; }
          Mod+Shift+K { move-window-up; }
          Mod+Shift+L { move-column-right; }

          Mod+Alt+H { set-column-width "-10%"; }
          Mod+Alt+J { set-window-height "+10%"; }
          Mod+Alt+K { set-window-height "-10%"; }
          Mod+Alt+L { set-column-width "+10%"; }

          Mod+M { toggle-column-tabbed-display; }
          Mod+F { fullscreen-window; }
          Mod+S { toggle-window-floating; }
          Mod+N { spawn "warpd" "--hint"; }

          Mod+Alt+Q { quit; }
          Mod+Alt+R { spawn-sh "niri msg action load-config-file"; }

          Mod+F8 { spawn-sh "brightnessctl set 8%+"; }
          Mod+F7 { spawn-sh "brightnessctl set 8%-"; }
          Mod+F1 { spawn-sh "wpctl set-mute @DEFAULT_SINK@ toggle"; }
          Mod+F2 { spawn-sh "wpctl set-volume @DEFAULT_SINK@ 3%-"; }
          Mod+F3 { spawn-sh "wpctl set-volume @DEFAULT_SINK@ 3%+"; }

          Mod+Shift+S { spawn-sh "grim -g \"$(slurp)\" - | wl-copy"; }
          Print { screenshot-screen; }
          Mod+Print { screenshot-window; }

          Mod+Insert { set-dynamic-cast-window; }
          Mod+Shift+Insert { set-dynamic-cast-monitor; }
          Mod+Delete { clear-dynamic-cast-target; }

          ${lib.optionalString isMoonshield ''
            Mod+Pause { spawn-sh "if [ \"$(niri msg --json outputs | jq '.\"HDMI-A-1\".logical == null')\" = \"true\" ]; then niri msg output HDMI-A-1 on; else niri msg output HDMI-A-1 off; fi"; }
            Mod+Prior { set-dynamic-cast-monitor "HDMI-A-1"; }
            Mod+Next { set-dynamic-cast-monitor "DP-1"; }
          ''}

          XF86AudioRaiseVolume { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"; }
          XF86AudioLowerVolume { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
          XF86AudioMute { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
          XF86MonBrightnessUp { spawn-sh "brightnessctl set 10%+"; }
          XF86MonBrightnessDown { spawn-sh "brightnessctl set 10%-"; }

          XF86AudioNext { focus-column-right; }
          XF86AudioPrev { focus-column-left; }
          Mod+Tab { focus-window-down-or-column-right; }
          Mod+Shift+Tab { focus-window-up-or-column-left; }

          Mod+Left { focus-column-left; }
          Mod+Down { focus-window-down; }
          Mod+Up { focus-window-up; }
          Mod+Right { focus-column-right; }
          Mod+Ctrl+Left { move-column-left; }
          Mod+Ctrl+Down { move-window-down; }
          Mod+Ctrl+Up { move-window-up; }
          Mod+Ctrl+Right { move-column-right; }
          Mod+Shift+Left { focus-monitor-left; }
          Mod+Shift+Down { focus-monitor-down; }
          Mod+Shift+Up { focus-monitor-up; }
          Mod+Shift+Right { focus-monitor-right; }
          Mod+Shift+Ctrl+Left { move-window-to-monitor-left; }
          Mod+Shift+Ctrl+Down { move-window-to-monitor-down; }
          Mod+Shift+Ctrl+Up { move-window-to-monitor-up; }
          Mod+Shift+Ctrl+Right { move-window-to-monitor-right; }

          Mod+V { switch-focus-between-floating-and-tiling; }
          Mod+Shift+V { toggle-window-floating; }

          Mod+Home { focus-column-first; }
          Mod+End { focus-column-last; }
          Mod+Ctrl+Home { move-column-to-first; }
          Mod+Ctrl+End { move-column-to-last; }

          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }
          Mod+0 { focus-workspace 10; }
          Mod+Shift+1 { move-window-to-workspace 1; }
          Mod+Shift+2 { move-window-to-workspace 2; }
          Mod+Shift+3 { move-window-to-workspace 3; }
          Mod+Shift+4 { move-window-to-workspace 4; }
          Mod+Shift+5 { move-window-to-workspace 5; }
          Mod+Shift+6 { move-window-to-workspace 6; }
          Mod+Shift+7 { move-window-to-workspace 7; }
          Mod+Shift+8 { move-window-to-workspace 8; }
          Mod+Shift+9 { move-window-to-workspace 9; }
          Mod+Shift+0 { move-window-to-workspace 10; }

          Mod+Comma { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }
          Mod+R { switch-preset-column-width; }
          Mod+Shift+F { maximize-column; }
          Mod+C { center-column; }
          Mod+Minus { set-column-width "-10%"; }
          Mod+Plus { set-column-width "+10%"; }
          Mod+Shift+Minus { set-window-height "-10%"; }
          Mod+Shift+Plus { set-window-height "+10%"; }
          Mod+Shift+Escape { toggle-keyboard-shortcuts-inhibit; }
          Mod+Shift+P { power-off-monitors; }
          Mod+Shift+Ctrl+T { toggle-debug-tint; }
      }
    '';
  };
}

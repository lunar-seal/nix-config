{
  lib,
  pkgs,
  user,
  ...
}:
let
  bindings = pkgs.writeText "niri-media-controls.kdl" ''
    binds {
        XF86AudioPlay allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "--player=playerctld" "play-pause"; }
        XF86AudioStop allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "--player=playerctld" "stop"; }
        XF86AudioPrev allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "--player=playerctld" "previous"; }
        XF86AudioNext allow-when-locked=true { spawn "${pkgs.playerctl}/bin/playerctl" "--player=playerctld" "next"; }
    }
  '';
in
{
  home-manager.users.${user} = {
    services.playerctld.enable = true;

    xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
      include "${bindings}"
    '';

    programs.waybar = {
      settings.mainBar = {
        # Compact fallback if output geometry is unavailable. The supervisor
        # overlays only the native module's format and metadata length limits.
        mpris = {
          player = "playerctld";
          format = "{status_icon}";
          format-playing = "{status_icon}";
          format-paused = "{status_icon}";
          format-stopped = "{status_icon}";
          status-icons = {
            playing = "";
            paused = "";
            stopped = "";
          };
          tooltip-format = "{player} · {status}\n{title}\n{artist}\n{album}\n\nClick: play/pause · middle: previous · right: next";
          # Use native click actions: they address the same player as the label.
          max-length = 2;
          title-len = 0;
          artist-len = 0;
          album-len = 0;
          dynamic-len = 0;
          dynamic-order = [
            "title"
            "artist"
            "album"
          ];
          dynamic-importance-order = [
            "title"
            "artist"
            "album"
          ];
          dynamic-separator = " · ";
        };
      };
      style = lib.mkAfter ''
        #mpris {
            padding: 0 4px;
            color: @bar_foreground;
        }

        #mpris.paused {
            color: @status_muted;
        }
      '';
    };
  };
}

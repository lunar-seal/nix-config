{ lib, user, ... }:
{
  home-manager.users.${user}.programs.waybar = {
    settings.mainBar = {
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% (-.-) z";
        format-full = "{capacity}% (-.-) z";
        format-alt = "{time} {icon}";
        format-icons = [
          " "
          " "
          " "
          " "
          " "
        ];
      };
    };
    style = lib.mkAfter ''
      #battery {
          padding: 0 2px;
          color: @bar_foreground;
      }

      @keyframes blink {
          to { color: @bar_blink; }
      }

      #battery.critical:not(.charging) {
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
    '';
  };
}

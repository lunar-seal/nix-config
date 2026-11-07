{
  lib,
  pkgs,
  user,
  ...
}:
let
  notification-cat = pkgs.writeShellApplication {
    name = "notification-cat";
    runtimeInputs = [
      pkgs.swaynotificationcenter
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./_helpers/notification_cat.sh;
  };
  client = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  timeout = "${pkgs.coreutils}/bin/timeout";
  bindings = pkgs.writeText "niri-notifications.kdl" ''
    binds {
        Super+Alt+N hotkey-overlay-title="Notification panel" { spawn "${timeout}" "3s" "${client}" "--skip-wait" "--toggle-panel"; }
        Super+Alt+Shift+N hotkey-overlay-title="Toggle notification DND" { spawn "${timeout}" "3s" "${client}" "--skip-wait" "--toggle-dnd"; }
    }
  '';
in
{
  home-manager.users.${user} = {
    home.packages = [ notification-cat ];
    services.swaync = {
      enable = true;
      settings = {
        positionX = "right";
        positionY = "top";
        control-center-width = 380;
        fit-to-screen = true;
        transition-time = 0;
        notification-grouping = true;
        widgets = [
          "inhibitors"
          "title"
          "notifications"
        ];
      };
    };

    programs.waybar = {
      settings.mainBar = {
        "custom/notifications" = {
          exec = "${notification-cat}/bin/notification-cat";
          return-type = "json";
          restart-interval = 5;
          exec-on-event = false;
          on-click = "${timeout} 3s ${client} --skip-wait --toggle-panel";
          on-click-right = "${timeout} 3s ${client} --skip-wait --toggle-dnd";
        };
      };
      style = lib.mkAfter ''
        #custom-notifications {
            padding: 0 2px;
            font-family: monospace;
            color: @bar_foreground;
        }

        #custom-notifications.pending { color: @status_positive; }
        #custom-notifications.dnd,
        #custom-notifications.inhibited { color: @status_muted; }
        #custom-notifications.unknown { color: @status_warning; }
        #custom-notifications.open { box-shadow: inset 0 -2px currentColor; }
      '';
    };

    xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
      include "${bindings}"
    '';
  };
}

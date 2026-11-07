{
  lib,
  pkgs,
  user,
  ...
}:
let
  tea-timer = pkgs.writeShellApplication {
    name = "tea-timer";
    runtimeInputs = [
      pkgs.fuzzel
      pkgs.systemd
      pkgs.libnotify
      pkgs.coreutils
      pkgs.jq
      pkgs.util-linux
    ];
    text = builtins.readFile ./_helpers/tea_timer.sh;
  };
  bindings = pkgs.writeText "niri-tea-timer.kdl" ''
    binds {
        Super+Alt+T hotkey-overlay-title="Tea timer" { spawn "${tea-timer}/bin/tea-timer" "menu"; }
    }
  '';
in
{
  home-manager.users.${user} = {
    home.packages = [ tea-timer ];

    programs.waybar = {
      settings.mainBar = {
        "custom/tea-timer" = {
          exec = "${tea-timer}/bin/tea-timer status";
          return-type = "json";
          interval = 1;
          hide-empty-text = true;
          on-click = "${tea-timer}/bin/tea-timer menu";
          on-click-right = "${tea-timer}/bin/tea-timer cancel";
        };
      };
      style = lib.mkAfter ''
        #custom-tea-timer {
            padding: 0 2px;
            color: @status_positive;
        }

        #custom-tea-timer.error {
            color: @status_warning;
        }
      '';
    };

    xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
      include "${bindings}"
    '';
  };
}

{
  lib,
  pkgs,
  user,
  ...
}:
let
  cpu-pressure = pkgs.writeShellApplication {
    name = "cpu-pressure";
    runtimeInputs = [
      pkgs.gawk
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = builtins.readFile ./_helpers/cpu_pressure.sh;
  };
in
{
  home-manager.users.${user} = {
    home.packages = [ cpu-pressure ];
    programs.waybar = {
      settings.mainBar = {
        "custom/cpu-pressure" = {
          exec = "${cpu-pressure}/bin/cpu-pressure";
          return-type = "json";
          interval = 5;
          exec-on-event = false;
          hide-empty-text = true;
        };
      };
      style = lib.mkAfter ''
        #custom-cpu-pressure {
            padding: 0 2px;
            color: @status_alert;
        }
      '';
    };
  };
}

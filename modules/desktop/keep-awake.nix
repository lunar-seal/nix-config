{
  lib,
  pkgs,
  user,
  ...
}:
let
  keep-awake = pkgs.writeShellApplication {
    name = "keep-awake";
    runtimeInputs = [
      pkgs.fuzzel
      pkgs.systemd
      pkgs.libnotify
      pkgs.coreutils
      pkgs.jq
      pkgs.util-linux
    ];
    text = builtins.readFile ./_helpers/keep_awake.sh;
  };
  bindings = pkgs.writeText "niri-keep-awake.kdl" ''
    binds {
        Super+Alt+I hotkey-overlay-title="Timed keep-awake" { spawn "${keep-awake}/bin/keep-awake" "menu"; }
    }
  '';
in
{
  home-manager.users.${user} = {
    home.packages = [ keep-awake ];
    programs.waybar = {
      settings.mainBar = {
        "custom/keep-awake" = {
          exec = "${keep-awake}/bin/keep-awake status";
          return-type = "json";
          interval = 5;
          hide-empty-text = true;
          on-click = "${keep-awake}/bin/keep-awake menu";
          on-click-right = "${keep-awake}/bin/keep-awake cancel";
        };
      };
      style = lib.mkAfter ''
        #custom-keep-awake {
            padding: 0 2px;
            color: @status_active;
        }
      '';
    };
    xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
      include "${bindings}"
    '';
  };
}

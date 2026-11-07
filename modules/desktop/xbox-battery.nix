{
  lib,
  pkgs,
  user,
  ...
}:
let
  xbox-battery = pkgs.writeShellApplication {
    name = "xbox-battery";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      for battery in /sys/class/power_supply/xpadneo_battery_*; do
        [[ -r "$battery/online" ]] || continue
        read -r online < "$battery/online" || continue
        [[ "$online" == 1 ]] || continue
        level=Unknown
        read -r level < "$battery/capacity_level" || true
        jq -cn --arg level "$level" '{
          text: (" " + $level),
          tooltip: ("Xbox controller battery: " + $level),
          class: ($level | ascii_downcase)
        }'
        exit 0
      done
      printf '%s\n' '{"text":""}'
    '';
  };
in
{
  hardware.xpadneo.enable = true;
  environment.systemPackages = [ xbox-battery ];
  home-manager.users.${user}.programs.waybar = {
    settings.mainBar = {
      "custom/xbox-battery" = {
        exec = "${xbox-battery}/bin/xbox-battery";
        return-type = "json";
        interval = 15;
        hide-empty-text = true;
      };
    };
    style = lib.mkAfter ''
      #custom-xbox-battery {
          padding: 0 2px;
          color: @bar_foreground;
      }

      #custom-xbox-battery.low {
          color: @status_warning;
      }

      #custom-xbox-battery.critical {
          color: @status_alert;
      }
    '';
  };
}

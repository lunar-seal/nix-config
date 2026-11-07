{ lib, user, ... }:
{
  home-manager.users.${user}.programs.waybar = {
    settings.mainBar = {
      "memory#warning" = {
        interval = 5;
        # Waybar uses MemAvailable, so reclaimable cache is not treated as used.
        # An empty format hides the whole widget, including its spacing.
        format = "";
        states.alert = 90;
        format-alert = " {percentage}%";
        tooltip-format = ''
          Available: {avail:.1f} GiB of {total:.1f} GiB
          In use: {used:.1f} GiB ({percentage}%, excluding reclaimable cache)
          Swap: {swapUsed:.1f} / {swapTotal:.1f} GiB
          Shown only at 90% usage or higher.'';
      };
    };
    style = lib.mkAfter ''
      #memory.warning {
          padding: 0 2px;
          color: @status_alert;
      }
    '';
  };
}

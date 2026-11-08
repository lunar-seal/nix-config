{ pkgs, user, ... }:
let
  warning = pkgs.writeShellApplication {
    name = "github-actions-warning";
    runtimeInputs = [
      pkgs.gh
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./_helpers/github_actions_warning.sh;
  };
in
{
  desktop.warnings.collectors = [ "${warning}/bin/github-actions-warning" ];
  home-manager.users.${user} = {
    home.packages = [ warning ];
    systemd.user.services.github-actions-warning = {
      Unit.Description = "Refresh nix-config GitHub Actions warnings";
      Service = {
        Type = "oneshot";
        ExecStart = "${warning}/bin/github-actions-warning refresh";
        TimeoutStartSec = 60;
      };
    };
    systemd.user.timers.github-actions-warning = {
      Unit.Description = "Check nix-config GitHub Actions every five minutes";
      Timer = {
        OnStartupSec = "30s";
        OnUnitActiveSec = "5m";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}

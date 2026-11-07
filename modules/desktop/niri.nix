{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  wallpaper = pkgs.fetchurl {
    url = "https://nya.owo.ff15.eu/media_attachments/files/116/622/605/459/387/323/original/46f3220014922c75.webp";
    hash = "sha256-lVeVwrXraJkTuWlbBmwxZ7ft48Yv+op5Q4QE8k1cDTU=";
  };

  # Spawn a command and pull its window into the focused column, since niri
  # has no way to open a window into an existing column.
  stack-under = pkgs.writeShellScriptBin "stack-under" ''
    # ponytail: grabs the first window id that wasn't there before, so a splash
    # screen or a window opening elsewhere at the same time can steal the match.
    before=$(niri msg --json windows | jq -c '[.[].id]')
    niri msg action spawn -- "$@"
    # Act on the id, not on focus: the open event beats the focus change.
    id=$(niri msg --json event-stream |
      timeout 10 jq -ne --argjson b "$before" \
        'first(inputs | .WindowOpenedOrChanged.window.id | select(. and (IN($b[]) | not)))') || exit 1
    niri msg action consume-or-expel-window-left --id "$id"
  '';

  # Steam won't raise its existing window the way discord does, so match on
  # app-id and focus it ourselves; spawn only when nothing is open.
  focus-or-spawn = pkgs.writeShellScriptBin "focus-or-spawn" ''
    re=$1
    shift
    id=$(niri msg --json windows |
      jq --arg re "$re" 'first(.[] | select(.app_id // "" | test($re; "i")) | .id)')
    if [ -n "$id" ]; then
      niri msg action focus-window --id "$id"
    else
      niri msg action spawn -- "$@"
    fi
  '';
in
{
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;
  # Plasma and Niri both supply defaults; use Niri for this desktop.
  services.displayManager.defaultSession = lib.mkForce "niri";

  environment.variables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    cage
    gamescope
    libsecret
    xwayland-satellite
  ];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      brightnessctl
      focus-or-spawn
      fuzzel
      grim
      jq
      libnotify
      playerctl
      slurp
      stack-under
      swaylock
      swaynotificationcenter
      wayland-utils
      wl-clipboard
      warpd
    ];

    programs.fuzzel = {
      enable = true;
      settings.main = {
        launch-prefix = "niri msg action spawn --";
        terminal = "alacritty -e";
      };
    };

    systemd.user.services.swaybg = {
      Unit = {
        Description = "Niri desktop wallpaper";
        After = [ "niri.service" ];
        PartOf = [ "niri.service" ];
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "niri.service" ];
    };

    # Feature modules append native Niri includes for their own bindings.
    xdg.configFile."niri/config.kdl".text = builtins.readFile ./niri.kdl;
    # config.kdl starts with `include "~/.config/niri/host.kdl"`.
    xdg.configFile."niri/host.kdl".source = ./niri-${config.networking.hostName}.kdl;
  };
}

{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  hostKdl = ./niri-${config.networking.hostName}.kdl;

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
in
{
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;

  environment.variables = {
    NIXOS_OZONE_WL = "1";
    TERMINAL = "alacritty";
  };

  environment.systemPackages = with pkgs; [
    cage
    gamescope
    libsecret
    xwayland-satellite
  ];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      alacritty
      brightnessctl
      fuzzel
      grim
      jq
      libnotify
      playerctl
      slurp
      stack-under
      swaylock
      swaynotificationcenter
      waybar
      wayland-utils
      wl-clipboard
      warpd
    ];

    home.sessionVariables.TERMINAL = "alacritty";

    programs.alacritty = {
      enable = true;
      settings.window.decorations = "None";
    };

    programs.fuzzel = {
      enable = true;
      settings.main = {
        launch-prefix = "niri msg action spawn --";
        terminal = "alacritty -e";
      };
    };

    services.swaync.enable = true;
    
    xdg.configFile."niri/config.kdl".text =
      lib.optionalString (builtins.pathExists hostKdl) (builtins.readFile hostKdl)
      + builtins.readFile ./niri.kdl;
  };
}

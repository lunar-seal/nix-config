{ pkgs, user, ... }:
{
  users.users.${user} = {
    isNormalUser = true;
    description = user;
    extraGroups = [ "wheel" ];
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  home-manager.users.${user}.home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "24.05";
  };
}

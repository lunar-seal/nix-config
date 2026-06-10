{ user, ... }:
{
  home-manager.users.${user}.programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      vim = "nvim";
      vi = "nvim";
      sudo = "doas";
      c = "clear";
      rsync = "rsync --info=progress2";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "aliases"
        "golang"
        "docker"
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "common-aliases"
        "compleat"
        "composer"
        "copybuffer"
        "copypath"
        "copyfile"
        "cp"
        "dircycle"
        "direnv"
        "dirhistory"
        "dirpersist"
        "docker-compose"
        "dotenv"
        "dotnet"
        "git-auto-fetch"
        "git-escape-magic"
        "git-extras"
        "systemd"
        "tmux"
        "z"
        "zsh-interactive-cd"
        "zsh-navigation-tools"
      ];
      theme = "obraun";
    };
  };
}

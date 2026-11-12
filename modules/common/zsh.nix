{ user, ... }:
{
  home-manager.users.${user}.programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      sudo = "doas";
      c = "clear";
      rsync = "rsync --info=progress2";
      nixos-rebuild = "nixos-rebuild --elevate run0 --ask-elevate-password";
    };
    oh-my-zsh = {
      enable = true;
      # Keep shell startup independent of saved directories and project envs.
      # Use direnv explicitly instead of running it from startup/prompt hooks.
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
        "dirhistory"
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

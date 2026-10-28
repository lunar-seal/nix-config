{
  lib,
  pkgs,
  user,
  ...
}:
{
  home-manager.users.${user} = {
    programs.zed-editor = {
      enable = true;
      # Manage settings on headless hosts without installing the GUI.
      package = lib.mkDefault null;
      mutableUserSettings = true;
      userSettings = {
        # Load project toolchains and formatting from direnv.
        load_direnv = "shell_hook";
        languages.Nix.language_servers = [
          "nixd"
          "!nil"
        ];
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        terminal = {
          shell = "system";
          working_directory = "current_project_directory";
        };
      };
    };

    # Use the same pinned version as the desktop; leave other versions writable.
    home.file.".zed_server/${pkgs.zed-editor.remoteServerExecutableName}".source =
      lib.getExe' pkgs.zed-editor.remote_server pkgs.zed-editor.remoteServerExecutableName;
  };
}

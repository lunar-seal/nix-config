{ pkgs, user, ... }:
{
  imports = [ ../development/zed.nix ];

  home-manager.users.${user}.programs.zed-editor = {
    package = pkgs.zed-editor;
    extensions = [
      "nix"
      "toml"
      "kotlin"
      "java"
      "sql"
    ];
    userSettings = {
      auto_update = false;
      base_keymap = "JetBrains";
      ui_font_size = 16;
      buffer_font_size = 15;
      buffer_font_family = "FiraCode Nerd Font";
      theme = {
        mode = "dark";
        dark = "One Dark";
        light = "One Light";
      };
      agent_servers."codex-acp" = {
        type = "registry";
      };
    };
  };
}

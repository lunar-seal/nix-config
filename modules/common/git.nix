{ user, ... }:
{
  home-manager.users.${user}.imports = [
    (
      { config, pkgs, ... }:
      {
        programs.git = {
          enable = true;
          lfs.enable = true;
          signing = {
            key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
            format = "ssh";
            signByDefault = true;
          };
          settings = {
            user = {
              name = "lunar-seal";
              email = "lunar-seal@ff15.eu";
            };
            alias = {
              ci = "commit";
              co = "checkout";
              s = "status";
              br = "checkout -b";
            };
            core.pager = "${pkgs.delta}/bin/delta";
            delta = {
              hyperlinks = true;
              keep-plus-minus-markers = true;
              line-numbers = true;
              navigate = true;
              side-by-side = true;
              syntax-theme = "TwoDark";
              tabs = 4;
            };
            difftool.prompt = true;
            init.defaultBranch = "main";
            merge.conflictstyle = "diff3";
            push.autoSetupRemote = true;
          };
        };
      }
    )
  ];
}

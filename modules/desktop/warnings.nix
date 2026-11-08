# One attention indicator for local problems and configured warning sources.
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  storage = config.desktop.warnings.storage;
  localFilesystems = [
    "ext2"
    "ext3"
    "ext4"
    "btrfs"
    "xfs"
    "zfs"
    "bcachefs"
    "f2fs"
    "vfat"
    "exfat"
    "ntfs3"
    "reiserfs"
    "jfs"
  ];
  requiredLocalMounts = lib.attrNames (
    lib.filterAttrs (
      _: fs:
      lib.elem fs.fsType localFilesystems
      && !lib.any (option: lib.elem option fs.options) [
        "nofail"
        "noauto"
        "x-systemd.automount"
        "ro"
      ]
    ) config.fileSystems
  );
  settings = pkgs.writeText "local-attention.json" (
    builtins.toJSON {
      host = config.networking.hostName;
      collectors = config.desktop.warnings.collectors;
      inherit (storage) mounts;
      thresholds = removeAttrs storage [ "mounts" ];
    }
  );
  local-failures = pkgs.writeShellApplication {
    name = "local-failures";
    runtimeInputs = [
      pkgs.systemd
      pkgs.coreutils
      pkgs.util-linux
      pkgs.jq
    ];
    text = ''
      export ATTENTION_CONFIG=${settings}
    ''
    + builtins.readFile ./_helpers/local_failures.sh;
  };
  bindings = pkgs.writeText "niri-service-failures.kdl" ''
    binds {
        Super+Alt+F hotkey-overlay-title="Warnings" { spawn "${pkgs.alacritty}/bin/alacritty" "--hold" "-e" "${local-failures}/bin/local-failures" "details"; }
    }
  '';
in
{
  options.desktop.warnings.collectors = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Local commands emitting JSON warning objects with message and alert fields. Network sources should read a background-refreshed cache.";
  };
  options.desktop.warnings.storage = {
    mounts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = requiredLocalMounts;
      description = "Required local mounts to check for missing mounts and storage pressure; optional, read-only, virtual and network mounts are excluded by default.";
    };
    freeBytes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 20 * 1024 * 1024 * 1024;
      description = "Alert at or below this many available bytes, regardless of percentage used. Non-boot volumes smaller than this threshold instead alert at 10% available capacity.";
    };
    bootFreeBytes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 256 * 1024 * 1024;
      description = "Available-byte alert threshold for /boot and /boot2, capped at 25% of their capacity so small boot partitions are not permanently alarming.";
    };
    freeInodes = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10000;
      description = "Alert at or below this many available inodes; filesystems without inode accounting are skipped.";
    };
  };

  config = {
    home-manager.users.${user} = {
      home.packages = [ local-failures ];
      programs.waybar = {
        settings.mainBar = {
          "custom/local-failures" = {
            exec = "${local-failures}/bin/local-failures status";
            return-type = "json";
            interval = 30;
            hide-empty-text = true;
            on-click = "${pkgs.alacritty}/bin/alacritty --hold -e ${local-failures}/bin/local-failures details";
          };
        };
        style = lib.mkAfter ''
          #custom-local-failures {
              padding: 0 2px;
              color: @status_alert;
              font-weight: bold;
          }
        '';
      };
      xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
        include "${bindings}"
      '';
    };
  };
}

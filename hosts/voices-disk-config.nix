args@{
  lib,
  modulesPath,
  pkgs,
  user,
  ...
}:
let
  rootSsd1 = args.rootSsd1 or "/dev/disk/by-id/ata-SanDisk_Ultra_II_240GB_171119803333";
  rootSsd2 = args.rootSsd2 or "/dev/disk/by-id/ata-SAMSUNG_MZYTE256HMHP-000L2_S1PNNYAG124910";
  dataHdd1 = args.dataHdd1 or "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZDH8SAEY";
  dataHdd2 = args.dataHdd2 or "/dev/disk/by-id/ata-ST4000VN008-2DR166_ZM40Y433";
  dataHdd3 = args.dataHdd3 or "/dev/disk/by-id/ata-ST4000VN006-3CW104_ZW601YMR";
  includeDataPool = args.includeDataPool or true;
  swapSize = args.swapSize or "8G";

  rootDisk = device: bootMount: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 100;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountOptions = [
              "nofail"
              "umask=0077"
              "x-systemd.device-timeout=10s"
            ];
          }
          // lib.optionalAttrs (bootMount != null) {
            mountpoint = bootMount;
          };
        };
        swap = {
          priority = 200;
          size = swapSize;
          content = {
            type = "swap";
            randomEncryption = true;
            discardPolicy = "both";
            mountOptions = [ "nofail" ];
            priority = 100;
          };
        };
        zfs = {
          size = "100%";
          content = {
            type = "zfs";
            pool = "zroot";
          };
        };
      };
    };
  };

  dataDisk = pool: device: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions.zfs = {
        size = "100%";
        content = {
          type = "zfs";
          inherit pool;
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = {
      root1 = rootDisk rootSsd1 "/boot";
      root2 = rootDisk rootSsd2 "/boot2";
    }
    // lib.optionalAttrs includeDataPool {
      data1 = dataDisk "isolinear" dataHdd1;
      data2 = dataDisk "isolinear" dataHdd2;
      data3 = dataDisk "isolinear" dataHdd3;
    };

    zpool = {
      zroot = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "off";
          compression = "zstd";
          mountpoint = "none";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
        };
      };
    }
    // lib.optionalAttrs includeDataPool {
      isolinear = {
        type = "zpool";
        mode = {
          topology = {
            type = "topology";
            vdev = [
              {
                mode = "raidz1";
                members = [
                  "data1"
                  "data2"
                  "data3"
                ];
              }
            ];
          };
        };
        options.ashift = "12";
        mountOptions = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          compression = "zstd";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/isolinear";
      };
    };
  };
}

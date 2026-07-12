args@{
  lib,
  modulesPath,
  pkgs,
  user,
  ...
}:
let
  rootSsd1 = args.rootSsd1 or "/dev/disk/by-id/REPLACE_ME_ROOT_SSD_1";
  rootSsd2 = args.rootSsd2 or "/dev/disk/by-id/REPLACE_ME_ROOT_SSD_2";
  rootSsd3 = args.rootSsd3 or "/dev/disk/by-id/REPLACE_ME_ROOT_SSD_3";
  dataHdd1 = args.dataHdd1 or "/dev/disk/by-id/REPLACE_ME_DATA_HDD_1";
  dataHdd2 = args.dataHdd2 or "/dev/disk/by-id/REPLACE_ME_DATA_HDD_2";
  dataHdd3 = args.dataHdd3 or "/dev/disk/by-id/REPLACE_ME_DATA_HDD_3";
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
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  networking.hostName = "voices";
  networking.hostId = "db9cf15a";

  # This host bootstraps through SSH keys, without a local password.
  security.doas.extraRules = lib.mkAfter [
    {
      users = [ user ];
      noPass = true;
    }
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = true;
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        path = "/boot";
        devices = [ "nodev" ];
      }
      {
        path = "/boot2";
        devices = [ "nodev" ];
      }
      {
        path = "/boot3";
        devices = [ "nodev" ];
      }
    ];
  };

  disko.devices = {
    disk = {
      root1 = rootDisk rootSsd1 "/boot";
      root2 = rootDisk rootSsd2 "/boot2";
      root3 = rootDisk rootSsd3 "/boot3";
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

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.pools = [
      "zroot"
      "isolinear"
    ];
    trim.enable = true;
  };

  fileSystems."/auxiliary" = {
    device = lib.mkDefault "/dev/disk/by-label/auxiliary";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

  swapDevices = [ ];

  hardware.enableRedistributableFirmware = true;
}

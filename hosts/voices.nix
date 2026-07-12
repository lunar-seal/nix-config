args@{
  lib,
  modulesPath,
  pkgs,
  user,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./voices-disk-config.nix
  ];

  networking.hostName = "voices";
  networking.hostId = "db9cf15a";

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
    ];
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

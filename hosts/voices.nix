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

  users.users.${user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOO5ut5KjZhkSstx0Q+rJ5ZExj0jSoQ/rViJf4PRwX7P"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKNuqanPuzuT1tPnbodKQKkwNxaYMAy48qy5rnycYN4"
  ];

  # Deploy and cache target: answers on the LAN as well as on wireguard.
  services.openssh.reachableOn = [
    "eno2"
    "wg1"
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

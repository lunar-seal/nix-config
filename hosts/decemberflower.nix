{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  networking.hostName = "decemberflower";

  environment.systemPackages = [
    pkgs.ryzen-monitor-ng
    pkgs.ectool
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];

  services.logind.settings.Login.HandleLidSwitch = "suspend";

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
  ];

  boot.kernelModules = [
    "kvm-amd"
    "ryzen-smu"
    "zenpower"
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_6;

  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.sg_display=0"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bfde217a-5985-4f63-8899-eb7d9eacb50e";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-3a5d5f6d-c9fe-4f24-9cea-644b2e6dd0fb".device =
    "/dev/disk/by-uuid/3a5d5f6d-c9fe-4f24-9cea-644b2e6dd0fb";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E9A0-0034";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.amd.ryzen-smu.enable = true;
  hardware.fw-fanctrl.enable = true;
  hardware.fw-fanctrl.config.defaultStrategy = "medium";

  powerManagement.cpuFreqGovernor = "performance";
}

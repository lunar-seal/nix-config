{
  lib,
  modulesPath,
  user,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./jester-disk-config.nix
  ];

  networking = {
    hostName = "jester";
    networkmanager.enable = true;
    useDHCP = lib.mkForce false;
    dhcpcd.enable = lib.mkForce false;
  };
  users.users.${user}.extraGroups = [ "networkmanager" ];

  # Before the first reboot, preserve the installer's SSH host key on the SSD.
  # agenix uses it to decrypt the saved Wi-Fi profile before NetworkManager starts.
  age.secrets.jester-wifi = {
    file = ../secrets/jester-wifi.age;
    path = "/run/NetworkManager/system-connections/jester-wifi.nmconnection";
    mode = "0600";
    symlink = false;
  };

  services.openssh.reachableOn = [ "wlp170s0" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.fstrim.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}

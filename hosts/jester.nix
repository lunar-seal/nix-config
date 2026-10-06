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
  };
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  documentation.dev.enable = lib.mkForce false;

  # Before the first reboot, preserve the installer's SSH host key on the SSD.
  # agenix uses it to decrypt the saved Wi-Fi profile before NetworkManager starts.
  age.secrets.jester-wifi = {
    file = ../secrets/jester-wifi.age;
    path = "/run/NetworkManager/system-connections/jester-wifi.nmconnection";
    mode = "0600";
    symlink = false;
  };
  age.secrets.jester-kodi = {
    file = ../secrets/jester-kodi.age;
    path = "/home/kodi/.kodi/userdata/advancedsettings.xml";
    owner = "kodi";
    group = "users";
    mode = "0600";
  };

  services.openssh.reachableOn = [ "wlp170s0" ];
  services.avahi.allowInterfaces = [ "wlp170s0" ];
  networking.firewall.interfaces.wlp170s0 = {
    # Kodi HTTP/JSON-RPC and TubeCast's fixed DIAL port.
    allowedTCPPorts = [
      8080
      9090
      8008
    ];
    # TubeCast SSDP, discovery via mDNS, and Kodi's remote event server.
    allowedUDPPorts = [
      1900
      5353
      9777
    ];
  };

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

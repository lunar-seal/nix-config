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
    ../modules/media/https.nix
  ];

  networking = {
    hostName = "jester";
    domain = "ff15.eu";
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
  networking.firewall = {
    # Replace the SSH module's interface-wide opening with source restrictions.
    interfaces.wlp170s0.allowedTCPPorts = lib.mkForce [ ];
    extraCommands = ''
      iptables -A nixos-fw -i wlp170s0 -s 192.168.178.0/24 -p tcp -m multiport --dports 22,8443,8008 -j nixos-fw-accept
      iptables -A nixos-fw -i wlp170s0 -s 192.168.178.0/24 -p udp -m multiport --dports 1900,5353 -j nixos-fw-accept
      for subnet in fdf1:a045:71a::/64 fe80::/10; do
        ip6tables -A nixos-fw -i wlp170s0 -s "$subnet" -p tcp -m multiport --dports 22,8443 -j nixos-fw-accept
        ip6tables -A nixos-fw -i wlp170s0 -s "$subnet" -p udp --dport 5353 -j nixos-fw-accept
      done
    '';
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

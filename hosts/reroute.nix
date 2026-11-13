{
  config,
  lib,
  modulesPath,
  user,
  ...
}:
{
  age.secrets = {
    reroute-wg0.file = ../secrets/reroute-wg0.age;
    reroute-wg1.file = ../secrets/reroute-wg1.age;
    reroute-crowdsec-local = lib.mkIf config.services.crowdsec.enable {
      file = ../secrets/reroute-crowdsec-local.age;
      owner = config.services.crowdsec.user;
      mode = "0400";
    };
    reroute-crowdsec-online = lib.mkIf config.services.crowdsec.enable {
      file = ../secrets/reroute-crowdsec-online.age;
      owner = config.services.crowdsec.user;
      mode = "0400";
    };
    reroute-crowdsec-bouncer = lib.mkIf config.services.crowdsec.enable {
      file = ../secrets/reroute-crowdsec-bouncer.age;
    };
  };
  services.crowdsec.enable = true;
  services.crowdsec.settings.config.api = lib.mkIf config.services.crowdsec.enable {
    client.credentials_path = config.age.secrets.reroute-crowdsec-local.path;
    server.online_client.credentials_path = config.age.secrets.reroute-crowdsec-online.path;
  };
  services.crowdsec-firewall-bouncer = lib.mkIf config.services.crowdsec.enable {
    registerBouncer.enable = false;
    secrets.apiKeyPath = config.age.secrets.reroute-crowdsec-bouncer.path;
  };
  imports = [
    ../modules/crowdsec
    (modulesPath + "/profiles/qemu-guest.nix")
    ../modules/wireguard/server.nix
    ./reroute-disk-config.nix
  ];

  services.crowdsecProtection.staticMediaPaths."furizon.ff15.eu" = [
    "(?i)^/items/[0-9a-f-]+/images/[^/?]+(/[0-9]+)?([?].*)?$"
  ];

  services.wireguardHub.uplink = "uplink";
  services.wireguardHub.interfaces = {
    wg0 = {
      address = [ "10.13.166.0/24" ];
      listenPort = 51538;
      peers = [
        {
          allowedIPs = [ "10.13.166.1/32" ];
          publicKey = "IljvG5b2JVDVHaVc/a8NVkqV53G/MSrkj1xpawePiiY=";
        }
        {
          allowedIPs = [ "10.13.166.2/32" ];
          publicKey = "A/qqtajCq4xY3tlw5y5benBGN9iuXiRNq+pGTRCFhyo=";
        }
        {
          allowedIPs = [ "10.13.166.99/32" ];
          publicKey = "kXgJqRwafvJuOH0rrbGZBPTIUViSWL88/YLIdRJbOxY=";
        }
        {
          allowedIPs = [ "10.13.166.98/32" ];
          publicKey = "utoTsMixQsCqkGAtot2HO5ZQ6XymQ7L3Ftw2r9CG8yM=";
        }
        {
          allowedIPs = [ "10.13.166.97/32" ];
          publicKey = "IU2kCz8DL1OYsvxb1hCcC1AkmoahDGqKIwCG2fbyUng=";
        }
        {
          allowedIPs = [ "10.13.166.5/32" ];
          publicKey = "m9j8crYs3YIWzBmD+bCQEsDaVZQ2gvNj8IvBBkck+jo=";
        }
        {
          allowedIPs = [ "10.13.166.6/32" ];
          publicKey = "abCDVdKbdZLvwLf7vAciyE84IpMSZYT1KuyrZqfQ30I=";
        }
      ];
      privateKeyFile = config.age.secrets.reroute-wg0.path;
    };
    wg1 = {
      address = [ "10.13.167.0/24" ];
      listenPort = 51539;
      peers = [
        {
          allowedIPs = [ "10.13.167.1/32" ];
          publicKey = "Fn9Kjn2ZllJU1YQgyGviKW/FeV3Add6SgKmZ+oarjmI=";
        }
        {
          allowedIPs = [ "10.13.167.2/32" ];
          publicKey = "el6snXjCzXZPUae8fWZjiln3aV657jZHVeOplgQ1gXI=";
        }
        {
          allowedIPs = [ "10.13.167.3/32" ];
          publicKey = "9P8gsf/Nznw+EDdxq8veqkkr3IFAjj/AVaviILxyojo=";
        }
        {
          allowedIPs = [ "10.13.167.4/32" ];
          publicKey = "4RyflRiSjHBL62NCHTSLRoz9nrmg3xDSLOKfK5eCvHk=";
        }
        {
          allowedIPs = [ "10.13.167.5/32" ];
          publicKey = "kWkvemn9hijtUPzrZyaM90CUOJLic00Vt+0sR1OYB3g=";
        }
        {
          allowedIPs = [ "10.13.167.6/32" ];
          publicKey = "W6eZJ4N2I5cb/cnQCAv4o+St5Hh3ISKlw0QWxLgxbQ8=";
        }
        {
          allowedIPs = [ "10.13.167.7/32" ];
          publicKey = "6qJOooLcKlHU5EK4jdUkm9p8G1zEALyN95h5AjlVJHk=";
        }
        {
          allowedIPs = [ "10.13.167.8/32" ];
          publicKey = "T27xR/nbqcMas5qkK90LwQ256C+0oNOGZmIcsOjda3c=";
        }
        {
          allowedIPs = [ "10.13.167.9/32" ];
          publicKey = "eSFSPO4hjVDIMx79g88agEZBhTDXWpL8N6Yuv9Ylfx4=";
        }
        {
          allowedIPs = [ "10.13.167.10/32" ];
          publicKey = "EM4QDSeiTZvUi4XHdwp4lpZqJFuR7j+XeYtzrdcV7RM=";
        }
        {
          allowedIPs = [ "10.13.167.11/32" ];
          publicKey = "VM9CtI3aezKLYZzUGVea3++bOnMzeZ6lnAQfPQoKPng=";
        }
        {
          allowedIPs = [ "10.13.167.12/32" ];
          publicKey = "E1mvxAKNCc+rEIcDuzub1eqoXnNnqbZFAHJgdwya8EA=";
        }
        {
          allowedIPs = [ "10.13.167.13/32" ];
          publicKey = "QdMjso+0wJ7Yr4MlcQHDIZDiYt40Zr6y71sCb7JCwyY=";
        }
        {
          allowedIPs = [ "10.13.167.14/32" ];
          publicKey = "KMU653/RweYh7EKCm5q2LnM2PUNG9qXye4Bc3UPUtDc=";
        }
        {
          allowedIPs = [ "10.13.167.99/32" ];
          publicKey = "VjAtJfjFLBnQqbilHHIikDPwikrxzwHMKVj3ogk/zn0=";
        }
        {
          allowedIPs = [ "10.13.167.98/32" ];
          publicKey = "J68qcTHVBY3k5xCS2ubq6UyK3WqpFWZzCmtwKnEe1yM=";
        }
        {
          allowedIPs = [ "10.13.167.97/32" ];
          publicKey = "Fp3CXvqe/IPnYXeqzKsc8hU4ixNi8g/0Tb4pzEGiS30=";
        }
        {
          allowedIPs = [ "10.13.167.32/32" ];
          publicKey = "lAmdGodGAn6RczsEtR8v1HiMG72F9JG0moy5UySl1gU=";
        }
        {
          allowedIPs = [ "10.13.167.36/32" ];
          publicKey = "K3rShZcaRB0YQJsYFXImDy0J+HPFjrbtDK225F4Cdhg=";
        }
      ];
      privateKeyFile = config.age.secrets.reroute-wg1.path;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Existing data volume: mounted, never included in disko's format targets.
  # WWN avoids accidentally selecting a recovery clone with the same FS UUID.
  fileSystems."/data" = {
    device = "/dev/disk/by-id/wwn-0x609237f406f54d44b2c0bb9244421f7b-part1";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=30s"
    ];
  };

  networking = {
    hostName = "reroute";
    domain = "ff15.eu";
    useDHCP = false;
    useNetworkd = true;
  };
  # Match the existing primary OCI VNIC independently of kernel interface names.
  systemd.network.links."10-uplink" = {
    matchConfig.MACAddress = "02:00:17:12:65:ac";
    linkConfig.Name = "uplink";
  };
  systemd.network.networks."10-uplink" = {
    matchConfig.Name = "uplink";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.UseRoutes = true;
  };
  services.resolved.enable = true;
  services.openssh.reachableOn = [ "uplink" ];
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOO5ut5KjZhkSstx0Q+rJ5ZExj0jSoQ/rViJf4PRwX7P"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKNuqanPuzuT1tPnbodKQKkwNxaYMAy48qy5rnycYN4"
    ];
  };
  # Bootstrap administration works before a local password is set for doas.
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.${user}.openssh.authorizedKeys.keys;

  boot.initrd.availableKernelModules = [ "sd_mod" ];
  boot.kernelParams = [
    "console=tty1"
    "console=ttyAMA0,115200"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.fstrim.enable = true;
  zramSwap.enable = true;
  documentation.dev.enable = lib.mkForce false;
  system.stateVersion = lib.mkForce "26.05";
}

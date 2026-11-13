{
  config,
  lib,
  modulesPath,
  pkgs,
  user,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./reroute-disk-config.nix
  ];

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
  environment.systemPackages = with pkgs; [
    rsync
    tmux
  ];
  documentation.dev.enable = lib.mkForce false;
  system.stateVersion = lib.mkForce "26.05";
}

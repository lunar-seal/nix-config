{ inputs, pkgs, ... }:
{
  imports = [ inputs.nix-cache-beacon.nixosModules.default ];

  services.nix-cache-beacon.cache = {
    enable = true;
    listenAddresses = [ "127.0.0.1:5028" ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  nix.settings = {
    substituters = [ "http://127.0.0.1:5028" ];
    # Recheck discovery after roaming: cached hits contain LAN download URLs,
    # and cached misses would hide caches discovered after returning home.
    # These TTL settings apply to all substituters on this laptop.
    narinfo-cache-positive-ttl = 0;
    narinfo-cache-negative-ttl = 0;
  };

  environment.systemPackages = [
    pkgs.brightnessctl
    pkgs.upower
  ];

  services.upower.enable = true;
}

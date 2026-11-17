{ pkgs, ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  nix.settings = {
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

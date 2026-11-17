{ inputs, lib, ... }:
{
  imports = [ inputs.nix-cache-beacon.nixosModules.default ];

  # Loopback proxy that races LAN caches discovered over mDNS (voices'
  # harmonia); answers 404 when none are around, so Nix falls through.
  services.nix-cache-beacon.cache = {
    enable = true;
    listenAddresses = [ "127.0.0.1:5028" ];
  };

  # The beacon speaks mDNS itself; multicast replies need 5353 open.
  networking.firewall.allowedUDPPorts = [ 5353 ];

  # mkForce to merge with core.nix's forced list; ahead of cache.nixos.org (40).
  nix.settings.substituters = lib.mkForce [ "http://127.0.0.1:5028?priority=30" ];
}

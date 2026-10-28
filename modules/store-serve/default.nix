{ config, inputs, ... }:
{
  imports = [
    ./nightly-build.nix
    inputs.nix-cache-beacon.nixosModules.default
  ];

  services.nix-cache-beacon.advert = {
    enable = true;
    port = 5000;
  };

  # Serve the local store as a binary cache: zstd on the wire, signed
  # narinfos, no separate storage. LAN-only via the firewall below.
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.age.secrets.harmonia-signing-key.path ];
    settings = {
      bind = "[::]:5000";
      # Preferred over cache.nixos.org (priority 40).
      priority = 30;
    };
  };

  age.secrets.harmonia-signing-key.file = ../../secrets/harmonia-signing-key.age;

  nix.settings.secret-key-files = [ config.age.secrets.harmonia-signing-key.path ];

  networking.firewall.interfaces.eno2.allowedTCPPorts = [ 5000 ];
  networking.firewall.interfaces.eno2.allowedUDPPorts = [ 5353 ];
}

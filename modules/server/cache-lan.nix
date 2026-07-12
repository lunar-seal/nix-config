{ config, lib, ... }:
let
  isVoices = config.networking.hostName == "voices";

  # Home hosts resolve this to voices' LAN address via hosts overrides; the
  # public route on ocar Traefik was removed, so away clients get a 404 from
  # the wildcard cert holder and nix falls back to the public caches.
  cacheHost = "redacted.example";
in
{
  config = lib.mkIf isVoices {
    # Garage's web endpoint is plain HTTP on wg1, so LAN reads need a local
    # TLS terminator holding a real cert for the cache hostname.
    security.acme = {
      acceptTerms = true;
      defaults.email = "redacted@redacted.example";
      certs.${cacheHost} = {
        dnsProvider = "porkbun";
        # PORKBUN_API_KEY / PORKBUN_SECRET_API_KEY; provisioned out-of-band.
        environmentFile = "/var/lib/acme-secrets/porkbun.env";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/acme-secrets 0750 root acme - -"
    ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts.${cacheHost} = {
        forceSSL = true;
        useACMEHost = cacheHost;
        locations."/".proxyPass = "http://10.13.166.6:3902";
      };
    };
    users.users.nginx.extraGroups = [ "acme" ];

    # Cache reads come from the LAN only.
    networking.firewall.interfaces.eno2.allowedTCPPorts = [ 443 ];

    # voices itself takes the loopback path.
    networking.hosts."127.0.0.1" = [ cacheHost ];
  };
}

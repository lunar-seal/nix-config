{
  config,
  lib,
  ...
}:
let
  isVoices = config.networking.hostName == "voices";

  # wg1 overlay address; the socket listens here so the ocar hub reaches it.
  overlayIp = "10.13.166.6";

  # Public hostnames fronted by ocar Traefik.
  serverHost = "redacted.example";
  s3Host = "redacted.example";
  # Anonymous public reads go through Garage's web endpoint, not the S3 API.
  cacheHost = "redacted.example";
in
{
  config = lib.mkIf isVoices {
    services.niks3 = {
      enable = true;

      # Socket binds on the overlay for Traefik (voices:5751).
      httpAddr = "${overlayIp}:5751";

      # Local PostgreSQL on the SSD-backed zroot (db + user managed by the module).
      database.createLocally = true;

      s3 = {
        endpoint = s3Host;
        bucket = "nix-cache";
        useSSL = true;
        # Garage is addressed path-style (no wildcard DNS needed).
        bucketLookup = "path";
        accessKeyFile = "/var/lib/niks3/s3-access-key";
        secretKeyFile = "/var/lib/niks3/s3-secret-key";
      };

      # Admin/CLI token (>=36 chars); CI does not use this, it uses OIDC below.
      apiTokenFile = "/var/lib/niks3/api-token";

      # Ed25519 narinfo signing key ("name:base64"); public half goes to consumers.
      signKeyFiles = [ "/var/lib/niks3/cache-sign-key" ];

      cacheUrl = "https://${cacheHost}";
      serverUrl = "https://${serverHost}";

      # GitHub Actions authenticates with its own OIDC token; no shared secret.
      oidc.providers.github = {
        issuer = "https://token.actions.githubusercontent.com";
        audience = "https://${serverHost}";
        boundClaims = {
          repository_owner = [ "lunar-seal" ];
        };
      };
    };

    # Reach the niks3 socket only over the overlay.
    networking.firewall.interfaces.wg1.allowedTCPPorts = [ 5751 ];
  };
}

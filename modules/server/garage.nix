{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Garage only runs on voices; guard so a future shared server host in
  # modules/server does not accidentally inherit this.
  isVoices = config.networking.hostName == "voices";

  # wg1 overlay address; the S3 API listens here so the ocar hub can reach it.
  overlayIp = "10.13.166.6";
in
{
  config = lib.mkIf isVoices {
    users.groups.garage = { };
    users.users.garage = {
      isSystemUser = true;
      group = "garage";
      home = "/var/lib/garage";
    };

    # Bulk object data on the isolinear HDD pool; metadata (LMDB) and the
    # secrets env file stay on the SSD-backed zroot (/var/lib/garage).
    systemd.tmpfiles.rules = [
      "d /var/lib/garage 0750 garage garage - -"
      "d /isolinear/garage 0750 garage garage - -"
      "d /isolinear/garage/data 0750 garage garage - -"
    ];

    services.garage = {
      enable = true;
      package = pkgs.garage_1;
      # Holds GARAGE_RPC_SECRET and GARAGE_ADMIN_TOKEN; provisioned out-of-band.
      environmentFile = "/var/lib/garage/garage.env";
      settings = {
        metadata_dir = "/var/lib/garage/meta";
        data_dir = "/isolinear/garage/data";
        db_engine = "lmdb";
        replication_factor = 1;

        # Single node: keep RPC and admin loopback-only.
        rpc_bind_addr = "127.0.0.1:3901";
        rpc_public_addr = "127.0.0.1:3901";

        s3_api = {
          s3_region = "garage";
          api_bind_addr = "${overlayIp}:3900";
          root_domain = ".s3.garage";
        };

        # Public read endpoint: anonymous GETs of the (public) nix-cache bucket.
        s3_web = {
          bind_addr = "${overlayIp}:3902";
          root_domain = ".redacted.example";
          index = "index.html";
        };

        admin = {
          api_bind_addr = "127.0.0.1:3903";
        };
      };
    };

    systemd.services.garage = {
      # The S3 API binds to the wg1 address, so that interface must exist first.
      after = [ "wg-quick-wg1.service" ];
      requires = [ "wg-quick-wg1.service" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "garage";
        Group = "garage";
      };
    };

    # Reach the S3 API (3900) and public web endpoint (3902) over the overlay.
    networking.firewall.interfaces.wg1.allowedTCPPorts = [
      3900
      3902
    ];
  };
}

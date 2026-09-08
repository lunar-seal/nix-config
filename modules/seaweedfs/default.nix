{
  config,
  lib,
  pkgs,
  ...
}:
let
  overlayIp = "10.13.166.6";

  hot = "/var/lib/seaweedfs/hot";
  cold = "/isolinear/seaweedfs";

  volumeSizeMB = 1024;
  hotVolumes = 48;
in
{
  users.groups.seaweedfs = { };
  users.users.seaweedfs = {
    isSystemUser = true;
    group = "seaweedfs";
  };

  environment.systemPackages = [ pkgs.seaweedfs ];

  systemd.tmpfiles.rules = [ "d ${cold} 0750 seaweedfs seaweedfs - -" ];

  age.secrets.seaweedfs-s3 = {
    file = ../../secrets/seaweedfs-s3.json.age;
    owner = "seaweedfs";
  };

  systemd.services.seaweedfs = {
    description = "SeaweedFS object storage (master, volume, filer, S3)";
    wantedBy = [ "multi-user.target" ];
    after = [ "wg-quick-wg1.service" ];
    requires = [ "wg-quick-wg1.service" ];

    serviceConfig = {
      User = "seaweedfs";
      Group = "seaweedfs";
      StateDirectory = [
        "seaweedfs/hot"
        "seaweedfs/meta"
      ];
      StateDirectoryMode = "0750";
      Restart = "always";
      RestartSec = "10s";
      LimitNOFILE = 1048576;

      ExecStart = lib.escapeShellArgs [
        (lib.getExe pkgs.seaweedfs)
        "server"
        "-dir=${hot},${cold}"
        "-volume.disk=ssd,hdd"
        "-volume.max=${toString hotVolumes},0"
        "-volume.index=leveldb"
        "-master.dir=/var/lib/seaweedfs/meta"
        "-master.volumeSizeLimitMB=${toString volumeSizeMB}"
        "-filer.disk=hdd"
        "-ip=${overlayIp}"
        "-s3"
        "-s3.config=${config.age.secrets.seaweedfs-s3.path}"
      ];
    };
  };

  systemd.services.seaweedfs-tier-down = {
    description = "Move idle SeaweedFS volumes from SSD to the isolinear pool";
    serviceConfig = {
      Type = "oneshot";
      User = "seaweedfs";
      Group = "seaweedfs";
    };
    script = ''
      echo 'volume.tier.move -fromDiskType=ssd -toDiskType=hdd -fullPercent=85 -quietFor=5m' \
        | ${lib.getExe pkgs.seaweedfs} shell -master=${overlayIp}:9333
    '';
    startAt = "*:0/5";
  };

  networking.firewall.interfaces.wg1.allowedTCPPorts = [ 8333 ];
}

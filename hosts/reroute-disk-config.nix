{ lib, ... }:
{
  # Verified on ocar: the 50 GB OCI boot volume, currently /dev/sda.
  # Never use /dev/oracleoci/oraclevda here: its live alias points at a CSI disk.
  # Only this volume is managed by disko. /data and recovery clones are excluded.
  disko.devices.disk.main = {
    device = lib.mkDefault "/dev/disk/by-id/wwn-0x601dbfe983c64a19813f01f67973cbff";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}

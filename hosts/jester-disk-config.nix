{ lib, ... }:
{
  disko.devices.disk.main = {
    # SK hynix PC401 256 GB NVMe SSD; the installer USB is a separate device.
    device = lib.mkDefault "/dev/disk/by-id/nvme-eui.ace42e817028ed2c";
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
            # Unencrypted for unattended startup when the TV turns on.
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}

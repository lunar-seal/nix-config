# agenix recipients. Edit with: agenix -e <name>.age -i ~/.ssh/id_ed25519
# After adding a key, rekey everything: agenix -r -i ~/.ssh/id_ed25519
let
  # ~/.ssh/id_ed25519.pub
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8koEKvE/Pgc6QyhDbCFKMwMvWPyLYKWlyl84q6qmXC";
  # /etc/ssh/ssh_host_ed25519_key.pub
  voices = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0rfMYiaYBTgP21DnV5h0y7mePdSqayBfCIlOBfpxWb";
  # Preserve the installer's /etc/ssh/ssh_host_ed25519_key on jester's SSD.
  jester = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILysx9ZPZy/t4o8+djRC4x7JA4xMbLQZwewBXtvB5xFH";
  reroute = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHwp1F48L7pdNneZcQpkU86rPoG2zJjSr2AWylS06KrV";
  rerouteKeys = [
    admin
    reroute
  ];
  keys = [
    admin
    voices
  ];
in
{
  "reroute-wg0.age".publicKeys = rerouteKeys;
  "reroute-wg1.age".publicKeys = rerouteKeys;
  "harmonia-signing-key.age".publicKeys = keys;
  "msmtprc.age".publicKeys = keys;
  "seaweedfs-s3.json.age".publicKeys = keys;
  "msmtp-aliases.age".publicKeys = keys;
  "jester-wifi.age".publicKeys = [
    admin
    jester
  ];
  "jester-kodi.age".publicKeys = [
    admin
    jester
  ];
  "jester-porkbun.age".publicKeys = [
    admin
    jester
  ];
}

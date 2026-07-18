# agenix recipients. Edit with: agenix -e <name>.age -i ~/.ssh/id_ed25519
# After adding a key, rekey everything: agenix -r -i ~/.ssh/id_ed25519
let
  # ~/.ssh/id_ed25519.pub
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8koEKvE/Pgc6QyhDbCFKMwMvWPyLYKWlyl84q6qmXC";
  # /etc/ssh/ssh_host_ed25519_key.pub
  voices = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0rfMYiaYBTgP21DnV5h0y7mePdSqayBfCIlOBfpxWb";
  keys = [
    admin
    voices
  ];
in
{
  "harmonia-signing-key.age".publicKeys = keys;
  "msmtprc.age".publicKeys = keys;
  "msmtp-aliases.age".publicKeys = keys;
}

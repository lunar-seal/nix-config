{ config, pkgs, ... }:
let
  domain = "jester.ff15.eu";
  certificateDirectory = "/var/lib/acme/${domain}";
in
{
  users.groups.kodi-tls = { };
  users.users.kodi.extraGroups = [ "kodi-tls" ];
  age.secrets.jester-porkbun.file = ../../secrets/jester-porkbun.age;
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@ff15.eu";
    certs.${domain} = {
      dnsProvider = "porkbun";
      dnsResolver = "1.1.1.1:53";
      environmentFile = config.age.secrets.jester-porkbun.path;
      group = "kodi-tls";
      # Also starts Kodi after the first successful certificate issuance.
      postRun = "systemctl --no-block restart greetd.service";
    };
  };
  systemd.tmpfiles.rules = [
    "L+ /home/kodi/.kodi/userdata/server.pem - - - - ${certificateDirectory}/fullchain.pem"
    "L+ /home/kodi/.kodi/userdata/server.key - - - - ${certificateDirectory}/key.pem"
  ];

  # Kodi silently falls back to HTTP if its certificate cannot load. Reject
  # missing/invalid certificates, including ACME's initial self-signed one.
  systemd.services.greetd.preStart = ''
    ${pkgs.openssl}/bin/openssl verify \
      -CAfile ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
      -untrusted ${certificateDirectory}/fullchain.pem \
      -verify_hostname ${domain} ${certificateDirectory}/cert.pem
    ${pkgs.openssl}/bin/openssl pkey -in ${certificateDirectory}/key.pem -noout
  '';
}

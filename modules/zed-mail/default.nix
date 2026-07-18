{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.zfs.zed.enableMail = false;
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    # Mail on healthy scrub completion too; doubles as a pipeline heartbeat.
    ZED_NOTIFY_VERBOSE = true;
    ZED_EMAIL_PROG = lib.getExe pkgs.msmtp;
    # --aliases maps the local "root" to the real recipient, keeping the
    # address out of the repo and the store.
    ZED_EMAIL_OPTS =
      "-C ${config.age.secrets.msmtprc.path} --aliases=${config.age.secrets.msmtp-aliases.path} @ADDRESS@";
  };
  age.secrets = {
    msmtprc.file = ../../secrets/msmtprc.age;
    msmtp-aliases.file = ../../secrets/msmtp-aliases.age;
  };
}

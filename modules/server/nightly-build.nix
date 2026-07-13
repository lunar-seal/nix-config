{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  isVoices = config.networking.hostName == "voices";

  hosts = [
    "decemberflower"
    "moonshield"
    "voices"
  ];
in
{
  config = lib.mkIf isVoices {
    # Prebuild all hosts from the nightly branch after the lock update so
    # morning rebuilds substitute from this store over ssh instead of
    # compiling. The -o symlinks double as gc roots for the latest round.
    systemd.services.nightly-build = {
      description = "Prebuild host closures from the nightly branch";
      path = [
        pkgs.nix
        pkgs.git
        pkgs.openssh
      ];
      environment.HOME = "/home/${user}";
      serviceConfig = {
        Type = "oneshot";
        # ${user}'s ssh key can fetch the private flake input.
        User = user;
        StateDirectory = "nightly-build";
      };
      script = ''
        fail=0
        for host in ${lib.concatStringsSep " " hosts}; do
          nix build --refresh -o "$STATE_DIRECTORY/$host" \
            "github:lunar-seal/nix-config/nightly#nixosConfigurations.$host.config.system.build.toplevel" \
            || fail=1
        done
        exit $fail
      '';
    };

    systemd.timers.nightly-build = {
      wantedBy = [ "timers.target" ];
      # The lock update lands on the nightly branch at 03:17 UTC.
      timerConfig = {
        OnCalendar = "06:30";
        Persistent = true;
      };
    };
  };
}

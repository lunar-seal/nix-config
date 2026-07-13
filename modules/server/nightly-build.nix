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
    # Prebuild all hosts after the lock update so rebuilds substitute from
    # this store instead of compiling: nightly for the next lock bump, main
    # for what nrs actually evaluates today. The -o symlinks double as gc
    # roots for the latest round.
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
        for ref in main nightly; do
          for host in ${lib.concatStringsSep " " hosts}; do
            nix build --refresh -o "$STATE_DIRECTORY/$host-$ref" \
              "github:lunar-seal/nix-config/$ref#nixosConfigurations.$host.config.system.build.toplevel" \
              || fail=1
          done
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

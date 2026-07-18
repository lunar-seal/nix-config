{
  lib,
  pkgs,
  user,
  ...
}:
let
  hosts = [
    "decemberflower"
    "moonshield"
    "voices"
  ];
in
{
  # Prebuild all hosts after lock update
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
    timerConfig = {
      OnCalendar = "06:30";
      Persistent = true;
    };
  };
}

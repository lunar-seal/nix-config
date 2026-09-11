{
  config,
  lib,
  user,
  ...
}:
{
  # How sshd is run, for every host. Where it can be reached is a property of
  # the host's networks, not of this module, so each host defines reachableOn.
  options.services.openssh.reachableOn = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "wg1" ];
    description = ''
      Interfaces sshd answers on. Port 22 is opened on exactly these and
      nowhere else. A host has to say which of its networks it trusts; the
      assertion below catches leaving this empty, since listOf would
      otherwise hand out [ ] and run sshd where nothing can reach it.
      Definitions merge, so a role module can add an interface without
      restating the ones it does not care about.
    '';
  };

  config = {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      # reachableOn is the only thing that opens port 22; leaving this on
      # would expose sshd on every interface and make that list a lie.
      openFirewall = false;
    };

    networking.firewall.interfaces = lib.genAttrs config.services.openssh.reachableOn (_: {
      allowedTCPPorts = [ 22 ];
    });

    assertions = [
      {
        assertion = config.services.openssh.enable -> config.services.openssh.reachableOn != [ ];
        message = ''
          services.openssh.reachableOn is empty on ${config.networking.hostName}, so
          sshd would run with port 22 closed on every interface. List the ones it
          should answer on, or set services.openssh.enable = false.
        '';
      }
    ];

    users.users.${user}.openssh.authorizedKeys.keys = [
      # ~/.ssh/id_ed25519.pub
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF8koEKvE/Pgc6QyhDbCFKMwMvWPyLYKWlyl84q6qmXC langj@moonshield"
      # decemberflower ~/.ssh/id_ed25519.pub
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEpo5xO4/2BB4kTDumRaifjir9MWamsPEGR52NTuMBm langj@decemberflower"
      # ~/.ssh/id_rsa.pub
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCszYA+pQGpK6zhV/Xhqgc4BJlZieDTVF+RmQxp3q/SqgIUFhaNNID+/0DqPshcF4xGz4eaTl0BFu363ERsWeJHpU2fDMztYt0w3Q9FXbQqDaLMj2tcQAXMH0tG1SZOkzs1MbfrV1EMuc/EkKHl+O8iflb+xnN9BB7HrDp18ZEH9soZzgTTpqTBJ2Jy9GbJYjKlc7X6IOOcJ9C14f81qHPNBAYhms4xZws5gV5RLMbj480ubp58oRKq1qA5jv4qbmBM57+dSg99PiPtp51GAHK1hXN+pCWsIcQbbEykrFP5VX5t70RH1S2J4OIDy+fR0gbgL3QurcnZ0zLRYjaa6LiIWBqggOPKRhDHw4ak1vru2dIgBAvlkPPoHupYi2W8jpApJ8OnWH7HB6WFRvC6VM/yfi+7aIr9pmoUeSLAoPDZzNxzrR+O6lKbNkGKG/6kUtSBoDmRewDqAB5m8F1rbWiOc0/yo3o8HQ80Ma4sMlFolswLvhk54IncGI6pN83fxd6PFNljVTY/bilvbGyDCqEwJPpaez+weO3y5jONMrYMpLAt/PYt1v9w47hvNfq4mL62gbVNQVhT1OvgZKZZAZEGkJLLeno5kf1F4r9mly8IpZEWzKjsxQWMQ7CivxTm5Yf1QKiFGCM8i3aecyHjZdJ+yWlY8jydeBTSQTvQCMVVAw== langj@xps"
      # voices ~/.ssh/id_ed25519.pub
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBHdaz0yx9xWxfwnNEskxz+8UAjdGcCQdQUzFmF9832l voices"
    ];
  };
}

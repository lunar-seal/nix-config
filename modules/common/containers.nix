{ pkgs, user, ... }:
{
  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
  ];

  virtualisation.docker.enable = true;
  users.users.${user}.extraGroups = [ "docker" ];
}

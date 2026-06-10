{
  services = {
    printing = {
      enable = true;
      defaultShared = true;
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  programs.system-config-printer.enable = true;
}

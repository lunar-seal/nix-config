{
  config,
  lib,
  ...
}:
{
  networking = {
    useDHCP = true;
    dhcpcd.enable = true;
    nameservers = [ "127.0.0.1" ];
    # Keep DHCP and NetworkManager from bypassing the local encrypted resolver.
    dhcpcd.extraConfig = "nohook resolv.conf";
    networkmanager.dns = "none";
    resolvconf.useLocalResolver = true;
    firewall.enable = true;
  };

  services.resolved.enable = false;

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" ] ++ lib.optional config.networking.enableIPv6 "[::1]:53";
      # Quad9 without threat blocking or EDNS Client Subnet; DNSSEC remains enabled.
      server_names = [
        "quad9-primary"
        "quad9-secondary"
      ]
      ++ lib.optionals config.networking.enableIPv6 [
        "quad9-ipv6-primary"
        "quad9-ipv6-secondary"
      ];
      ipv6_servers = config.networking.enableIPv6;
      dnscrypt_servers = false;
      doh_servers = true;
      require_nofilter = true;
      ignore_system_dns = true;
      bootstrap_resolvers = [ ];
      netprobe_address = "9.9.9.10:443";
      # Override the upstream defaults: no downloaded resolver lists.
      sources = { };
      # https://dns10.quad9.net/dns-query, with fixed IPs to avoid bootstrap DNS.
      # Normal CA validation allows certificate rotation without pin updates.
      static = {
        quad9-primary.stamp = "sdns://AgcAAAAAAAAACDkuOS45LjEwAA9kbnMxMC5xdWFkOS5uZXQKL2Rucy1xdWVyeQ"; # 9.9.9.10
        quad9-secondary.stamp = "sdns://AgcAAAAAAAAADjE0OS4xMTIuMTEyLjEwAA9kbnMxMC5xdWFkOS5uZXQKL2Rucy1xdWVyeQ"; # 149.112.112.10
        quad9-ipv6-primary.stamp = "sdns://AgcAAAAAAAAADVsyNjIwOmZlOjoxMF0AD2RuczEwLnF1YWQ5Lm5ldAovZG5zLXF1ZXJ5"; # 2620:fe::10
        quad9-ipv6-secondary.stamp = "sdns://AgcAAAAAAAAAEFsyNjIwOmZlOjpmZToxMF0AD2RuczEwLnF1YWQ5Lm5ldAovZG5zLXF1ZXJ5"; # 2620:fe::fe:10
      };
    };
  };
}

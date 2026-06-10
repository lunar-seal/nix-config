{
  networking = {
    useDHCP = true;
    dhcpcd.enable = true;
    nameservers = [
      "9.9.9.9"
      "1.1.1.1"
      "2620:fe::fe"
      "2001:4860:4860::8888"
    ];
    firewall.enable = true;
  };
}

{ pkgs, user, ... }:
{
  hardware.hackrf.enable = true;

  users.groups.plugdev = { };
  users.users.${user}.extraGroups = [
    "plugdev"
    "kvm"
    "dialout"
    "uucp"
  ];

  environment.systemPackages = with pkgs; [
    hackrf
    minicom
    woeusb-ng
  ];

  services.udev.extraRules = ''
    # LED badge
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5020", MODE="0666"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5020", MODE="0666"
  '';

  home-manager.users.${user}.home.packages = with pkgs; [
    gqrx
    linssid
  ];
}

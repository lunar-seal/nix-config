{ user, ... }:
let
  speakerDevice = "alsa_output.pci-0000_c1_00.6.analog-stereo";
  speakerRoute = "Speakers";
in
{
  imports = [ ./easyeffects.nix ];

  home-manager.users.${user} = {
    services.easyeffects = {
      # Native device/route autoload selects speaker correction or passthrough.
      extraPresets."Gracefu (Nix)" = builtins.fromJSON (
        builtins.readFile ./_framework-audio/gracefu.json
      );

    };
    xdg.dataFile."easyeffects/autoload/output/${speakerDevice}:${speakerRoute}.json".text =
      builtins.toJSON
        {
          device = speakerDevice;
          "device-description" = "Framework laptop speakers";
          "device-profile" = speakerRoute;
          "preset-name" = "Gracefu (Nix)";
        };
    # Selected IR: ALT_IR_50ms_27dB_5t_15s_0c.irs, preserved byte-for-byte.
    xdg.dataFile."easyeffects/irs/nix-gracefu.irs".source =
      ./_framework-audio/ALT_IR_50ms_27dB_5t_15s_0c.irs;
  };
}

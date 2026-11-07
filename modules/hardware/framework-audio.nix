{ user, ... }:
let
  speakerDevice = "alsa_output.pci-0000_c1_00.6.analog-stereo";
  speakerRoute = "Speakers";
in
{
  home-manager.users.${user} = {
    services.easyeffects = {
      enable = true;
      # Native device/route autoload selects speaker correction or passthrough.
      extraPresets."Gracefu (Nix)" = builtins.fromJSON (
        builtins.readFile ./_framework-audio/gracefu.json
      );
      extraPresets."Passthrough (Nix)".output = {
        plugins_order = [ ];
        blocklist = [ ];
      };
      settings = {
        Window = {
          outputAutoloadingUsesFallback = true;
          outputAutoloadingFallbackPreset = "Passthrough (Nix)";
        };
        EffectsPipelines = {
          processAllOutputs = true;
          processAllInputs = false;
        };
        StreamOutputs = {
          useDefaultOutputDevice = true;
          # Start clean until PipeWire announces the current device and route.
          plugins = "";
        };
      };
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

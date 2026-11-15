{ user, ... }:
{
  home-manager.users.${user}.services.easyeffects = {
    enable = true;
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
}

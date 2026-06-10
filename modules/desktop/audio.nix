{ pkgs, ... }:
{
  programs.noisetorch.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.enable = true;
    extraLadspaPackages = [ pkgs.deepfilternet ];
    extraConfig.pipewire."99-input-denoising" = {
      "context.properties" = {
        "link.max-buffers" = 64;
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 2048;
        "core.daemon" = true;
        "core.name" = "pipewire-0";
        "module.x11.bell" = false;
        "module.access" = true;
        "module.jackdbus-detect" = false;
      };

      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "DeepFilter Noise Canceling source";
            "media.name" = "DeepFilter Noise Canceling source";

            "filter.graph".nodes = [
              {
                type = "ladspa";
                name = "DeepFilter Mono";
                plugin = "libdeep_filter_ladspa";
                label = "deep_filter_mono";
                control."Attenuation Limit (dB)" = 100;
              }
            ];

            "audio.rate" = 48000;
            "audio.position" = "[MONO]";

            "capture.props"."node.passive" = true;
            "capture.props"."node.latency" = "1024/48000";
            "playback.props" = {
              "media.class" = "Audio/Source";
              "node.latency" = "1024/48000";
            };
          };
        }
      ];
    };
  };
}

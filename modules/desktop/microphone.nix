{
  lib,
  pkgs,
  user,
  ...
}:
let
  mic-toggle = pkgs.writeShellApplication {
    name = "mic-toggle";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.pulseaudio
      pkgs.libnotify
    ];
    text = ''
      # Use the same source and protocol as Waybar's native PulseAudio module.
      # With a monitor as the default input, wpctl resolves the underlying sink
      # and can mute speaker output while the input indicator remains unchanged.
      export LC_ALL=C
      if ! source=$(timeout 3s pactl get-default-source) || [[ -z "$source" ]]; then
        notify-send --app-name="Microphone" "Default input unavailable"
        exit 1
      fi
      if ! timeout 3s pactl set-source-mute "$source" toggle; then
        notify-send --app-name="Microphone" --urgency=normal "Microphone unavailable" "Could not change the default input."
        exit 1
      fi
      if ! state=$(timeout 3s pactl get-source-mute "$source"); then
        notify-send --app-name="Microphone" "Default input state unavailable"
        exit 1
      fi
      case "$state" in
        "Mute: yes") label="Default input muted"; icon="microphone-sensitivity-muted" ;;
        "Mute: no") label="Default input unmuted"; icon="microphone-sensitivity-high" ;;
        *) notify-send --app-name="Microphone" "Default input state unavailable"; exit 1 ;;
      esac
      notify-send --app-name="Microphone" --replace-id=2606 --expire-time=1500 \
        --hint=int:transient:1 --icon="$icon" "$label"
    '';
  };
  bindings = pkgs.writeText "niri-microphone.kdl" ''
    binds {
        Super+F6 allow-when-locked=true hotkey-overlay-title="Toggle default input mute" { spawn "${mic-toggle}/bin/mic-toggle"; }
        XF86AudioMicMute allow-when-locked=true { spawn "${mic-toggle}/bin/mic-toggle"; }
    }
  '';
in
{
  home-manager.users.${user} = {
    home.packages = [ mic-toggle ];
    programs.waybar = {
      settings.mainBar = {
        privacy = {
          icon-size = 16;
          icon-spacing = 4;
          transition-duration = 0;
          modules = [
            {
              type = "audio-in";
              tooltip = true;
            }
            {
              type = "screenshare";
              tooltip = true;
            }
          ];
        };
        "pulseaudio#microphone" = {
          format = "{format_source}";
          format-muted = "{format_source}";
          format-source = "";
          format-source-muted = "";
          tooltip-format = "Default input: {source_desc}\n{format_source} · {source_volume}%\nClick / Super+F6: toggle mute\nRight click: input settings";
          on-click = "${mic-toggle}/bin/mic-toggle";
          on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol --tab=4";
          on-scroll-up = "true";
          on-scroll-down = "true";
        };
      };
      style = lib.mkAfter ''
        #privacy {
            padding: 0 2px;
            color: @status_warning;
        }

        #pulseaudio.microphone.source-muted {
            color: @status_muted;
        }
      '';
    };
    xdg.configFile."niri/config.kdl".text = lib.mkAfter ''
      include "${bindings}"
    '';
  };
}

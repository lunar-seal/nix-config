{ user, ... }:
let
  headphoneDevice = "alsa_output.pci-0000_0c_00.4.analog-stereo";
  headphoneRoute = "Headphones";
  presetName = "DT 990 Pro 250 Ohm (Nix)";

  # AutoEq / Auriculares Argentina, DT 990 Pro (250 Ohm), at revision
  # 7ae0f56d53074872b028649617a22bbb4232feb7:
  # https://github.com/jaakkopasanen/AutoEq/tree/7ae0f56d53074872b028649617a22bbb4232feb7/results/Auriculares%20Argentina/over-ear/Beyerdynamic%20DT%20990%20Pro%20(250%20Ohm)
  # [ type frequency gain Q ]; APO (DR) matches EasyEffects' APO importer.
  filters = [
    [
      "Lo-shelf"
      105
      6.1
      0.70
    ]
    [
      "Bell"
      564
      2.2
      1.86
    ]
    [
      "Bell"
      8240
      (-6.0)
      0.91
    ]
    [
      "Bell"
      2070
      2.6
      2.69
    ]
    [
      "Bell"
      82
      1.7
      4.34
    ]
    [
      "Hi-shelf"
      10000
      (-15.8)
      0.70
    ]
    [
      "Bell"
      9052
      6.4
      1.28
    ]
    [
      "Bell"
      181
      (-1.1)
      2.55
    ]
    [
      "Bell"
      4255
      2.9
      6.00
    ]
    [
      "Bell"
      5819
      (-4.1)
      5.58
    ]
  ];
  channel = builtins.listToAttrs (
    builtins.genList (i: {
      name = "band${toString i}";
      value = {
        type = builtins.elemAt (builtins.elemAt filters i) 0;
        frequency = builtins.elemAt (builtins.elemAt filters i) 1;
        gain = builtins.elemAt (builtins.elemAt filters i) 2;
        q = builtins.elemAt (builtins.elemAt filters i) 3;
        mode = "APO (DR)";
        slope = "x1";
        width = 4.0;
        solo = false;
        mute = false;
      };
    }) (builtins.length filters)
  );
in
{
  imports = [ ./easyeffects.nix ];

  home-manager.users.${user} = {
    services.easyeffects.extraPresets.${presetName}.output = {
      plugins_order = [ "equalizer#0" ];
      blocklist = [ ];
      "equalizer#0" = {
        bypass = false;
        input-gain = -6.1;
        output-gain = 0.0;
        mode = "IIR";
        split-channels = false;
        balance = 0.0;
        pitch-left = 0.0;
        pitch-right = 0.0;
        num-bands = builtins.length filters;
        left = channel;
        right = channel;
      };
    };
    xdg.dataFile."easyeffects/autoload/output/${headphoneDevice}:${headphoneRoute}.json".text =
      builtins.toJSON
        {
          device = headphoneDevice;
          "device-description" = "Starship/Matisse HD Audio Controller Analog Stereo";
          "device-profile" = headphoneRoute;
          "preset-name" = presetName;
        };
  };
}

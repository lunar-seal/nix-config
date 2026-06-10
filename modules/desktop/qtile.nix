{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  wallpaper = pkgs.fetchurl {
    url = "https://nya.owo.ff15.eu/media_attachments/files/116/622/605/459/387/323/original/46f3220014922c75.webp";
    hash = "sha256-lVeVwrXraJkTuWlbBmwxZ7ft48Yv+op5Q4QE8k1cDTU=";
  };
  hasBrightnessctl = builtins.elem pkgs.brightnessctl config.environment.systemPackages;
  hasBattery = config.services.upower.enable;

  configFile = pkgs.writeText "qtile-config.py" ''
    from libqtile import bar, layout, widget, hook
    from libqtile.config import Click, Drag, Group, Key, Match, Screen
    from libqtile.lazy import lazy
    import subprocess

    mod = "mod4"

    def _detect_max_width(fallback=1920):
        import glob, os
        widths = []
        for status in glob.glob("/sys/class/drm/*/status"):
            try:
                if open(status).read().strip() != "connected":
                    continue
                modes = os.path.join(os.path.dirname(status), "modes")
                first = open(modes).readline().strip()
                widths.append(int(first.split("x")[0]))
            except (OSError, ValueError):
                pass
        return max(widths) if widths else fallback

    _WIDESCREEN_MIN = 2400
    _side = 1000 if _detect_max_width() >= _WIDESCREEN_MIN else 0

    BG       = "#1a212e"
    FG       = "#dfdfdf"
    FOCUSED  = "#007a84"
    INACTIVE = "#1a212e"
    FG_ALT   = "#555555"
    ALERT    = "#bd2c40"

    def _focus_or_spawn(qtile, wm_class, cmd):
        needle = wm_class.lower()
        for win in qtile.windows_map.values():
            if not getattr(win, "group", None):
                continue
            classes = win.get_wm_class() or []
            if any(needle in (c or "").lower() for c in classes):
                qtile.current_screen.set_group(win.group)
                win.group.focus(win)
                return
        qtile.spawn(cmd)

    keys = [
        # Applications
        Key([mod], "Return", lazy.spawn("alacritty")),
        Key([mod], "u",      lazy.spawn("firefox")),
        Key([mod], "d",      lazy.function(_focus_or_spawn, "discord", "discord")),
        Key([mod], "g",      lazy.function(_focus_or_spawn, "steam", "steam")),
        Key([mod], "space",  lazy.spawn("fuzzel")),

        # Window control
        Key([mod],          "w", lazy.window.kill()),
        Key([mod, "shift"], "w", lazy.window.kill()),

        # Focus
        Key([mod], "h", lazy.layout.left()),
        Key([mod], "j", lazy.layout.down()),
        Key([mod], "k", lazy.layout.up()),
        Key([mod], "l", lazy.layout.right()),

        # Swap
        Key([mod, "shift"], "h", lazy.layout.shuffle_left()),
        Key([mod, "shift"], "j", lazy.layout.shuffle_down()),
        Key([mod, "shift"], "k", lazy.layout.shuffle_up()),
        Key([mod, "shift"], "l", lazy.layout.shuffle_right()),

        # Resize
        Key([mod, "mod1"], "h", lazy.layout.grow_left()),
        Key([mod, "mod1"], "j", lazy.layout.grow_down()),
        Key([mod, "mod1"], "k", lazy.layout.grow_up()),
        Key([mod, "mod1"], "l", lazy.layout.grow_right()),

        Key([mod], "m", lazy.next_layout()),
        Key([mod], "f", lazy.window.toggle_fullscreen()),
        Key([mod], "s", lazy.window.toggle_floating()),
        Key([mod], "n", lazy.spawn("warpd --hint")),

        Key([mod, "mod1"], "q", lazy.shutdown()),
        Key([mod, "mod1"], "r", lazy.reload_config()),

        # Brightness
        Key([mod], "F8", lazy.spawn("brightnessctl set 8%+")),
        Key([mod], "F7", lazy.spawn("brightnessctl set 8%-")),

        # Volume
        Key([mod], "F1", lazy.spawn("wpctl set-mute @DEFAULT_SINK@ toggle")),
        Key([mod], "F2", lazy.spawn("wpctl set-volume @DEFAULT_SINK@ 3%-")),
        Key([mod], "F3", lazy.spawn("wpctl set-volume @DEFAULT_SINK@ 3%+")),

        # Region screenshot to clipboard via grim + slurp.
        Key([mod, "shift"], "s", lazy.spawn(
            "sh -c 'grim -g \"$(slurp)\" - | wl-copy'"
        )),
    ]

    # Roman numeral groups matching bspwm desktop layout.
    _groups = [
        ("I",    "1"), ("II",   "2"), ("III", "3"),
        ("IV",   "4"), ("V",    "5"), ("VI",  "6"),
        ("VII",  "7"), ("VIII", "8"), ("IX",  "9"),
        ("X",    "0"),
    ]

    groups = [Group(name) for name, _ in _groups]

    for name, key in _groups:
        keys += [
            Key([mod],          key, lazy.group[name].toscreen()),
            Key([mod, "shift"], key, lazy.window.togroup(name)),
        ]

    layouts = [
        layout.Bsp(
            border_focus=FOCUSED,
            border_normal=INACTIVE,
            border_width=2,
            margin=0,
            margin_on_single=[0, _side, 0, _side],
            ratio=1.2,
            fair=False,
        ),
        layout.Max(
            border_focus=FOCUSED,
            border_normal=INACTIVE,
            border_width=2,
        ),
    ]

    widget_defaults = dict(
        font="hack",
        fontsize=14,
        padding=4,
        background=BG,
        foreground=FG,
    )

    def _sep():
        return widget.Sep(linewidth=1, foreground=FG_ALT, padding=6)

    def make_bar(primary=False):
        widgets = [
            widget.GroupBox(
                active=FOCUSED,
                inactive=FG_ALT,
                this_current_screen_border=FG,
                this_screen_border=INACTIVE,
                other_current_screen_border=FG_ALT,
                other_screen_border=FOCUSED,
                urgent_border=ALERT,
                highlight_method="text",
                highlight_color=[BG],
                border_width=2,
                padding=5,
            ),
            widget.Spacer(),
            widget.PulseVolume(),
            _sep(),
            ${lib.optionalString hasBrightnessctl ''
              # brightnessctl -m output: device,class,current,percent,max
              widget.GenPollCommand(
                  cmd="brightnessctl -m | cut -d, -f4",
                  shell=True,
                  update_interval=2,
              ),
              _sep(),
            ''}
            ${lib.optionalString hasBattery ''
              widget.Battery(
                  format="{percent:2.0%} {char}",
                  charge_char="up",
                  discharge_char="dn",
                  full_char="==",
                  low_foreground=ALERT,
              ),
              _sep(),
            ''}
            widget.Clock(format="%Y-%m-%d %H:%M"),
        ]
        if primary:
            widgets.append(widget.StatusNotifier())
        return bar.Bar(widgets, 30, background=BG, margin=0)

    screens = [
        Screen(top=make_bar(primary=True)),
        Screen(top=make_bar()),
        Screen(top=make_bar()),
    ]

    mouse = [
        Drag([mod], "Button1", lazy.window.set_position_floating(),
             start=lazy.window.get_position()),
        Drag([mod], "Button3", lazy.window.set_size_floating(),
             start=lazy.window.get_size()),
        Click([mod], "Button2", lazy.window.bring_to_front()),
    ]

    floating_layout = layout.Floating(
        border_focus=FOCUSED,
        border_normal=INACTIVE,
        border_width=2,
        float_rules=[
            *layout.Floating.default_float_rules,
            Match(wm_class="pavucontrol"),
        ],
    )

    @hook.subscribe.startup_once
    def autostart():
        subprocess.Popen(["mako"])
        subprocess.Popen([
            "swaybg", "-i",
            "${wallpaper}",
            "-m", "center",
        ])

    dgroups_key_binder  = None
    dgroups_app_rules   = []
    follow_mouse_focus  = False
    bring_front_click   = False
    cursor_warp         = False
    auto_fullscreen     = True
    auto_minimize       = False
    focus_on_window_activation = "smart"
    reconfigure_screens = True

    try:
        from libqtile.backend.wayland import InputConfig
        wl_input_rules = {
            "type:keyboard": InputConfig(kb_layout="eu"),
        }
    except ImportError:
        pass
  '';
  qtileWaylandSession =
    (pkgs.writeTextFile {
      name = "qtile-wayland-session";
      destination = "/share/wayland-sessions/qtile-wayland.desktop";
      text = ''
        [Desktop Entry]
        Name=Qtile (Wayland)
        Comment=Qtile Session
        Exec=${pkgs.python3Packages.qtile}/bin/qtile start -b wayland -c /etc/qtile/config.py
        Type=Application
      '';
    })
    // {
      providedSessions = [ "qtile-wayland" ];
    };
in
{
  environment.systemPackages = [
    pkgs.python3Packages.qtile
    pkgs.swaybg
  ];
  # Stable path so `super+alt+r` reloads the current generation after rebuild,
  # instead of re-reading the /nix/store hash baked in at login time.
  environment.etc."qtile/config.py".source = configFile;
  services.displayManager.sessionPackages = [ qtileWaylandSession ];
  services.displayManager.defaultSession = "qtile-wayland";

  home-manager.users.${user}.home.packages = with pkgs; [
    cliphist
    dmenu
    fuzzel
    grim
    mako
    nwg-displays
    slurp
    swayidle
    swaylock
    warpd
    wayland-utils
    wl-clipboard
    wlr-randr
    xwayland-run
  ];
}

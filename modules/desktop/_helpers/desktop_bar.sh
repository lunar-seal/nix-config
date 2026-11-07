umask 077
# systemd owns the supervisor; this shell owns exactly one Waybar child.
config_dir=${XDG_RUNTIME_DIR:?}/desktop-waybar
mkdir -p "$config_dir"
exec 9>"$config_dir/lock"
flock -n 9
child='' connection=''
stop_bar() { if [[ -n "$child" ]]; then
    kill "$child" 2>/dev/null || true
    wait "$child" || true
    child=
fi; }
trap stop_bar EXIT
trap 'exit 0' TERM INT
trap '[[ -z "$child" ]] || kill -USR1 "$child"' USR1
trap '[[ -z "$child" ]] || kill -USR2 "$child"' USR2
while :; do
    if ! outputs=$(timeout 3 niri msg --json outputs); then
        candidate=$(timeout 2 systemctl --user show-environment --output=json | jq -r --arg display "${WAYLAND_DISPLAY:-}" '. | select(.WAYLAND_DISPLAY == $display) | .NIRI_SOCKET // empty') || candidate=
        if [[ "$candidate" == "$XDG_RUNTIME_DIR/"* && -S "$candidate" && -O "$candidate" && ! -L "$candidate" ]]; then
            export NIRI_SOCKET=$candidate
        fi
        # A forwarded USR signal interrupts wait; keep supervising afterward.
        sleep 2 9>&- &
        wait "$!" || true
        continue
    fi
    jq -L "$MEDIA_FILTER_DIR" --slurpfile template "$BAR_TEMPLATE" '
      include "media_layout";
      [to_entries | sort_by(.key)[] | select(.value.logical != null and .value.current_mode != null)
       | (.value | media_layout) as $media
       | $template[0] + {output: .key, "fixed-center": false}
       | .mpris += $media.config
       | ."niri/window"."max-length" = (if $media.logical_width <= 1700 then 28 elif $media.logical_width < 2500 then 40 else 50 end)]
    ' <<<"$outputs" >"$config_dir/next.json"
    current="${NIRI_SOCKET:-}:$(stat -Lc '%d:%i' "${NIRI_SOCKET:-/nonexistent}" 2>/dev/null || true)"
    [[ "$current" == "$connection" ]] || stop_bar
    if [[ -n "$child" ]] && ! kill -0 "$child" 2>/dev/null; then
        wait "$child"
        exit 1
    fi
    if ! cmp -s "$config_dir/next.json" "$config_dir/config.json"; then
        mv "$config_dir/next.json" "$config_dir/config.json"
        [[ -z "$child" ]] || kill -USR2 "$child"
    fi
    if [[ -z "$child" ]]; then
        waybar --config "$config_dir/config.json" --style "$BAR_STYLE" 9>&- &
        child=$!
        connection=$current
    fi
    sleep 5 9>&- &
    wait "$!" || true
done

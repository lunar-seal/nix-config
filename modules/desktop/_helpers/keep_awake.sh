action=${1:-menu}
umask 077
state=${XDG_RUNTIME_DIR:?}/desktop-keep-awake
unit=desktop-keep-awake.service
if [[ "$action" == hold ]]; then
    printf '%s\n' "$(($(date +%s) + $2 * 60))" >"$state.next"
    mv "$state.next" "$state"
    exec sleep "$2"m
fi
if [[ "$action" == menu ]]; then
    choice=$(printf '15\n30\n60\n120\nCustom…\nCancel keep-awake\n' | fuzzel --dmenu --only-match --prompt='Keep awake minutes: ') || exit 0
    if [[ "$choice" == 'Cancel keep-awake' ]]; then
        action=cancel
    else
        if [[ "$choice" == 'Custom…' ]]; then
            choice=$(fuzzel --dmenu --prompt='Minutes (1–1440): ' </dev/null) || exit 0
        fi
        action=start
        set -- start "$choice"
    fi
fi
exec 9>"$state.lock"
flock -w 5 9
case "$action" in
    start)
        if [[ ! "${2:-}" =~ ^[0-9]{1,4}$ ]] || ((10#$2 < 1 || 10#$2 > 1440)); then
            notify-send 'Keep awake' 'Choose 1–1440 whole minutes'
            exit 1
        fi
        minutes=$((10#$2))
        systemctl --user stop "$unit" 2>/dev/null || true
        rm -f "$state"
        systemctl --user reset-failed "$unit" 2>/dev/null || true
        if systemd-run --user --quiet --collect --expand-environment=no --unit="$unit" \
            --property=Type=exec --property=PartOf=graphical-session.target --property="RuntimeMaxSec=$((minutes * 60 + 5))" \
            --setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
            systemd-inhibit --no-ask-password --what=idle:sleep --who='Timed keep-awake' --why="$minutes-minute keep-awake" \
            "$0" hold "$minutes" 9>&-; then
            for _ in {1..30}; do
                [[ ! -f "$state" ]] || exit 0
                sleep 0.1
            done
        fi
        systemctl --user stop "$unit" 2>/dev/null || true
        rm -f "$state"
        notify-send 'Keep awake' 'Could not acquire sleep inhibition'
        exit 1
        ;;
    cancel)
        systemctl --user stop "$unit" 2>/dev/null || true
        rm -f "$state"
        ;;
    status)
        if [[ ! -f "$state" ]] || ! systemctl --user is-active --quiet "$unit"; then
            printf '{"text":""}\n'
            exit 0
        fi
        read -r deadline <"$state"
        remaining=$((deadline - $(date +%s)))
        if ((remaining <= 0)); then
            printf '{"text":""}\n'
            exit 0
        fi
        label=$(printf '◉ %d:%02d' "$((remaining / 60))" "$((remaining % 60))")
        jq -nc --arg text "$label" '{text:$text,tooltip:"Keeping awake · click to change, right-click to cancel\nSleep/idle inhibition; lid-close and manual locking unchanged."}'
        ;;
    *)
        printf 'Usage: keep-awake menu|start MINUTES|cancel|status\n' >&2
        exit 2
        ;;
esac

action=${1:-menu}
if [[ "$action" == menu ]]; then
    choice=$(printf '3\n5\n7\n10\nCustom…\nCancel timer\n' | fuzzel --dmenu --only-match --prompt='Tea minutes: ') || exit 0
    if [[ "$choice" == 'Cancel timer' ]]; then
        action=cancel
    else
        if [[ "$choice" == 'Custom…' ]]; then
            choice=$(fuzzel --dmenu --prompt='Minutes (1–240): ' </dev/null) || exit 0
        fi
        action=start
        set -- start "$choice"
    fi
fi
umask 077
state_dir=${XDG_RUNTIME_DIR:?}/desktop-tea-simple
mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock -w 5 9
state=$state_dir/state
deadline=0 minutes=0 token='' phase=active
[[ ! -f "$state" ]] || read -r deadline minutes token phase <"$state"
save() {
    printf '%s %s %s %s\n' "$deadline" "$minutes" "$token" "$phase" >"$state.next"
    mv "$state.next" "$state"
}
stop_old() {
    [[ -z "$token" ]] || systemctl --user --no-block stop "desktop-tea-$token.timer" "desktop-tea-$token.service" >/dev/null 2>&1 || true
}
case "$action" in
    start)
        if [[ ! "${2:-}" =~ ^[0-9]{1,3}$ ]] || ((10#$2 < 1 || 10#$2 > 240)); then
            notify-send 'Tea timer' 'Choose 1-240 whole minutes'
            exit 1
        fi
        old=$token
        minutes=$((10#$2))
        deadline=$(($(date +%s) + minutes * 60))
        token=$(date +%s%N)
        phase=active
        if ! systemd-run --user --quiet --collect --expand-environment=no --unit="desktop-tea-$token" --on-calendar="@$deadline" \
            --timer-property=AccuracySec=1s --timer-property=PartOf=graphical-session.target \
            --property=PartOf=graphical-session.target --setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" "$0" finish "$token"; then
            notify-send 'Tea timer' 'Could not start timer'
            exit 1
        fi
        save
        token=$old
        stop_old
        ;;
    cancel)
        rm -f "$state"
        stop_old
        ;;
    finish)
        [[ -f "$state" && "$token" == "${2:-}" && "$phase" == active ]] || exit 0
        phase=notifying
        save
        if timeout 5 notify-send --app-name='Tea timer' --icon=alarm-symbolic 'Tea is ready' "Your $minutes-minute timer is done."; then
            rm -f "$state"
        else
            phase=error
            save
            exit 1
        fi
        ;;
    status)
        [[ -f "$state" ]] || {
            printf '{"text":""}\n'
            exit 0
        }
        remaining=$((deadline - $(date +%s)))
        if [[ "$phase" != active ]] || ! systemctl --user is-active --quiet "desktop-tea-$token.timer" "desktop-tea-$token.service" || ((remaining < -10)); then
            printf '{"text":"☕ !","class":"error","tooltip":"Tea timer stopped or notification failed. Right-click to clear."}\n'
        else
            ((remaining >= 0)) || remaining=0
            label=$(printf '☕ %d:%02d' "$((remaining / 60))" "$((remaining % 60))")
            jq -nc --arg text "$label" --arg tooltip "$minutes-minute tea timer · click to change, right-click to cancel" '{text:$text,tooltip:$tooltip}'
        fi
        ;;
    *)
        printf 'Usage: tea-timer menu|start MINUTES|cancel|status\n' >&2
        exit 2
        ;;
esac

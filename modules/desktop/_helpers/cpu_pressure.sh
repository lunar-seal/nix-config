export LC_ALL=C
umask 077
proc_root=${1:-/proc}
state_dir=${XDG_RUNTIME_DIR:?}/desktop-cpu-pressure
mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock -w 5 9

# Share samples between bars; a delayed poll must not count as sustained load.
read -r now _ <"$proc_root/uptime"
touch "$state_dir/state"
pressure="$proc_root/pressure/cpu"
[[ -r "$pressure" ]] || pressure=/dev/null

awk -v now="$now" -v state="$state_dir/state" -v cache="$state_dir/output" '
FILENAME == state {
    if ($1 == "time") previous_time = $2
    else {
        old_total[$1] = $2
        old_idle[$1] = $3
        old_duration[$1] = $4
    }
    next
}
/^cpu[0-9]+ / {
    cpu = substr($1, 4) + 0
    total[cpu] = 0
    # guest counters are already included in user/nice: count only fields 2–9.
    for (i = 2; i <= 9; i++) total[cpu] += $i
    idle[cpu] = $5 + $6 + $9  # Idle, I/O wait and stolen time are not busy work.
    next
}
$1 == "some" {
    for (i = 2; i <= NF; i++) {
        split($i, field, "=")
        if (field[1] == "avg60") pressure = field[2]
    }
}
END {
    elapsed = now - previous_time
    if (previous_time > 0 && elapsed >= 0 && elapsed < 1 && (getline cached < cache) > 0) {
        print cached
        exit
    }

    printf "time %.2f\n", now > (state ".next")
    PROCINFO["sorted_in"] = "@ind_num_asc"
    for (cpu in total) {
        duration = 0
        delta = total[cpu] - old_total[cpu]
        idle_delta = idle[cpu] - old_idle[cpu]
        if (cpu in old_total && elapsed > 0 && elapsed <= 15 && delta > 0 && idle_delta >= 0 && idle_delta <= delta) {
            busy = 100 * (delta - idle_delta) / delta
            if (busy >= 95) duration = old_duration[cpu] + elapsed
            if (duration >= 60) {
                alert = 1
                detail = detail sprintf("CPU %d: %.1f%% busy for %.0f s\\n", cpu, busy, duration)
            }
        }
        printf "%d %.0f %.0f %.2f\n", cpu, total[cpu], idle[cpu], duration > (state ".next")
    }

    if (pressure ~ /^[0-9]+([.][0-9]+)?$/ && pressure + 0 >= 0 && pressure + 0 <= 100) {
        if (pressure + 0 >= 10) alert = 1
        detail = detail sprintf("CPU waiting pressure (60 s): %.2f%%", pressure)
    }
    if (alert) printf "{\"text\":\"\",\"class\":\"alert\",\"tooltip\":\"%s\"}\n", detail
    else print "{\"text\":\"\"}"
}' "$state_dir/state" "$proc_root/stat" "$pressure" >"$state_dir/output.next"

if [[ -f "$state_dir/state.next" ]]; then
    mv "$state_dir/state.next" "$state_dir/state"
fi
mv "$state_dir/output.next" "$state_dir/output"
cat "$state_dir/output"

export LC_ALL=C
umask 077
proc_root=${1:-/proc}
state_dir=${XDG_RUNTIME_DIR:?}/desktop-cpu-threads
mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock -w 5 9
read -r now _ <"$proc_root/uptime"
hz=$(getconf CLK_TCK)
touch "$state_dir/state"

# Multiple bars share a sample. Missing polls reset the sustained-load timers.
previous=0
read -r _ previous <"$state_dir/state" || true
if [[ -s "$state_dir/output" ]] && awk -v now="$now" -v previous="$previous" 'BEGIN { exit !(now >= previous && now - previous < 1) }'; then
    cat "$state_dir/output"
    exit 0
fi

# comm can contain spaces, parentheses and newlines. Strip through its final ).
# Keep only IDs, start time and user+system ticks; never count child CPU time.
read_stat() {
    local kind=$1 pid=$2 file=$3 record tail
    local -a fields
    { record=$(<"$file"); } 2>/dev/null || return 0
    tail=${record##*) }
    read -ra fields <<<"$tail"
    ((${#fields[@]} >= 20)) || return 0
    printf '%s %s %s %s %s\n' "$kind" "$pid" "${record%% *}" "${fields[19]}" "$((fields[11] + fields[12]))"
}

shopt -s nullglob
for file in "$proc_root"/[0-9]*/stat; do
    pid=${file%/stat}
    read_stat P "${pid##*/}" "$file"
done >"$state_dir/processes"

printf 'time %s\n' "$now" >"$state_dir/state.next"
# Inspect threads only in processes consuming >=80% of one CPU, or new processes.
# The margin keeps the prefilter safely below the 95% thread threshold.
awk -v state="$state_dir/state" -v now="$now" -v hz="$hz" '
FILENAME == state {
    if ($1 == "time") previous = $2
    if ($1 == "P") old[$2, $4] = $5
    next
}
{
    print >> (state ".next")
    elapsed = now - previous
    key = $2 SUBSEP $4
    if (!(key in old) || elapsed <= 0 || elapsed > 15 || ($5 - old[key]) / (elapsed * hz) >= 0.80)
        print $2
}' "$state_dir/state" "$state_dir/processes" >"$state_dir/candidates"

while read -r pid; do
    for file in "$proc_root/$pid"/task/[0-9]*/stat; do
        read_stat T "$pid" "$file"
    done
done <"$state_dir/candidates" >"$state_dir/threads"

pressure="$proc_root/pressure/cpu"
[[ -r "$pressure" ]] || pressure=/dev/null
awk -v state="$state_dir/state" -v now="$now" -v hz="$hz" '
FILENAME == state {
    if ($1 == "time") previous = $2
    if ($1 == "T") {
        key = $2 SUBSEP $3 SUBSEP $4
        ticks[key] = $5
        held[key] = $6
    }
    next
}
$1 == "T" {
    key = $2 SUBSEP $3 SUBSEP $4
    elapsed = now - previous
    duration = 0
    if (key in ticks && elapsed > 0 && elapsed <= 15 && $5 >= ticks[key]) {
        busy = 100 * ($5 - ticks[key]) / (elapsed * hz)
        if (busy >= 95) duration = held[key] + elapsed
        if (duration >= 60) {
            alert = 1
            printf "PID %s / thread %s: %.1f%% of one CPU for %.0f s\n", $2, $3, (busy > 100 ? 100 : busy), duration
        }
    }
    printf "%s %.2f\n", $0, duration >> (state ".next")
    next
}
$1 == "some" {
    for (i = 2; i <= NF; i++) {
        split($i, field, "=")
        if (field[1] == "avg60") pressure = field[2]
    }
}
END {
    valid = pressure ~ /^[0-9]+([.][0-9]+)?$/ && pressure + 0 >= 0 && pressure + 0 <= 100
    if (valid && (alert || pressure + 0 >= 10))
        printf "CPU waiting pressure (60 s): %.2f%%\n", pressure
}' "$state_dir/state" "$state_dir/threads" "$pressure" >"$state_dir/details"

jq -Rs '{text:(if length > 0 then "" else "" end), class:"alert", tooltip:(rtrimstr("\n") | @html)}' \
    "$state_dir/details" >"$state_dir/output.next"
mv "$state_dir/state.next" "$state_dir/state"
mv "$state_dir/output.next" "$state_dir/output"
cat "$state_dir/output"

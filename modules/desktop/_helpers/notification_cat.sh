printf '{"text":"=?.?=","class":"unknown","tooltip":"Waiting for SwayNC"}\n'
swaync-client --skip-wait --subscribe | while IFS= read -r event; do
    if ! timeout 2 swaync-client --skip-wait --count >/dev/null; then
        printf '{"text":"=?.?=","class":"unknown","tooltip":"SwayNC unavailable"}\n'
        continue
    fi
    jq -c '
  {text: (if .dnd or .inhibited then "=-.-=" elif .count > 0 then "=^o^=" else "=^.^=" end),
   tooltip: ("\(.count) stored notifications\nDND: \(.dnd) · inhibited: \(.inhibited)\nLeft click: notifications · right click: DND"),
   class: [if .dnd then "dnd" else empty end, if .inhibited then "inhibited" else empty end,
           if .count > 0 then "pending" else empty end, if .visible then "open" else empty end]}' <<<"$event"
done

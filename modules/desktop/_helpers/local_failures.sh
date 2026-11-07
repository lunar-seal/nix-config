export LC_ALL=C
notice() {
    jq -nc --arg message "$2" --argjson alert "$1" '{message:$message, alert:$alert}'
}
collect() {
    for scope in system user; do
        args=()
        [[ "$scope" != user ]] || args=(--user)
        if units=$(timeout 5 systemctl "${args[@]}" --failed --full --no-legend --plain --no-pager); then
            while read -r unit _; do
                [[ -z "$unit" ]] || notice true "$scope: $unit failed"
            done <<<"$units"
        else
            notice false "$scope service state unavailable"
        fi
    done
    read -r limit boot_limit inode_limit < <(jq -r '.thresholds | [.freeBytes,.bootFreeBytes,.freeInodes] | @tsv' "$ATTENTION_CONFIG")
    declare -A seen=()
    while IFS= read -r mount; do
        if identity=$(timeout 3 findmnt -rn --mountpoint "$mount" -o FSTYPE,MAJ:MIN); then
            :
        else
            code=$?
            if ((code == 1)); then
                notice true "Required mount $mount is missing"
            else
                notice false "Mount state unavailable for $mount"
            fi
            continue
        fi
        read -r filesystem device <<<"$identity"
        case "$filesystem" in
            ext[234] | btrfs | xfs | zfs | bcachefs | f2fs | vfat | exfat | ntfs3 | reiserfs | jfs)
                ;;
            *)
                continue
                ;;
        esac
        [[ -z "${seen[$device]:-}" ]] || continue
        seen[$device]=1
        if ! space=$(timeout 3 df -B1 --output=size,avail,itotal,iavail -- "$mount"); then
            notice false "Storage state unavailable for $mount"
            continue
        fi
        read -r total available inodes free_inodes <<<"$(tail -n 1 <<<"$space")"
        ((available >= 0)) || available=0
        threshold=$limit
        if [[ "$mount" == /boot || "$mount" == /boot2 ]]; then
            threshold=$((total / 4 < boot_limit ? total / 4 : boot_limit))
        elif ((total < limit)); then
            threshold=$((total / 10))
        fi
        if ((available <= threshold)); then
            notice true "$mount: $(numfmt --to=iec-i --suffix=B "$available") available"
        fi
        if [[ "$inodes" =~ ^[0-9]+$ && "$free_inodes" =~ ^[0-9]+$ ]] && ((inodes > 0 && free_inodes <= inode_limit)); then
            notice true "$mount: $free_inodes inodes available"
        fi
    done < <(jq -r '.mounts[]' "$ATTENTION_CONFIG")

}
issues=$(collect)
if [[ "${1:-status}" == details ]]; then
    jq -sr 'if length == 0 then "No actionable problems detected." else .[] | (if .alert then "⚠ " else "? " end) + .message end' <<<"$issues"
    printf '\nDetails: systemctl [--user] --failed; df -h; df -i\n'
else
    jq -sc '[.[] | select(.alert)] as $alerts | {
      text:(if ($alerts|length)>0 then "⚠ \($alerts|length)" else "" end), class:"alert",
      tooltip:([.[] | .message | @html] | join("\n"))}' <<<"$issues"
fi

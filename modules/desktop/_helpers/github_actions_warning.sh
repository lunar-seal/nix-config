export LC_ALL=C GH_PROMPT_DISABLED=1
umask 077
cache=${XDG_RUNTIME_DIR:?}/github-actions-warning.json
if [[ ${1:-status} == refresh ]]; then
    temporary=$(mktemp "$cache.XXXXXX")
    trap 'rm -f "$temporary" "$temporary.json"' EXIT
    # workflow_run reports the default-branch SHA, even though eval checks nightly.
    # Read the latest run of each workflow, rather than pretending it proves a SHA.
    for workflow in update-flake-lock.yml eval-hosts.yml; do
        timeout 25 gh run list --repo lunar-seal/nix-config --workflow "$workflow" \
            --limit 1 --json workflowName,status,conclusion,url >>"$temporary"
    done
    jq -s --argjson checked "$(date +%s)" '{checked:$checked,runs:add}' "$temporary" >"$temporary.json"
    mv "$temporary.json" "$cache"
else
    if [[ ! -s $cache ]]; then
        jq -nc '{alert:false,message:"GitHub Actions status unavailable (check github-actions-warning.service and gh auth status)."}'
        exit 0
    fi
    jq -c --argjson now "$(date +%s)" '
      if $now - .checked > 900 or .checked > $now then
        {alert:false,message:"GitHub Actions status is stale; last refresh over 15 minutes ago."}
      else .runs[] | select(.status == "completed") |
        select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "action_required" or .conclusion == "startup_failure") |
        {alert:true,message:("GitHub Actions: " + .workflowName + " — " + .conclusion + "\n" + .url)}
      end' "$cache"
fi

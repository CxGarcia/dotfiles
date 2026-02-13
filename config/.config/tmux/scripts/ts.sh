#!/usr/bin/env bash
# ts.sh — tmux session/window switcher with fzf

CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
CURRENT_SESSION_ID=$(tmux display-message -p '#{session_id}' 2>/dev/null)

go_to_session() {
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$1" 2>/dev/null || tmux switch-client -t "$2"
    else
        tmux attach-session -t "$1" 2>/dev/null || tmux attach-session -t "$2"
    fi
}

COLORS="bg+:#2d3843,fg:#908caa,fg+:#e0def4,hl:#ebbcba,hl+:#ebbcba"
COLORS+=",border:#3a4450,header:#f6c177,pointer:#ebbcba,marker:#f6c177,prompt:#ebbcba"

# ── Subcommands (called by fzf binds) ───────────────────────────────

list_sessions() {
    tmux list-sessions -F '#{session_activity} #{session_id} #{session_name}' |
        sort -rn | while read -r _ id name; do
            [[ "$name" == "$CURRENT_SESSION" || "$name" == _picker_* ]] && continue
            title=$(tmux display-message -t "$id:=claude" -p '#{pane_title}' 2>/dev/null)
            printf '%s\t%s\t%s\n' "$id" "$name" "$title"
        done
}

case "${1:-}" in
    --list)     list_sessions; exit 0 ;;
    --list-dirs)
        { zoxide query -l 2>/dev/null; find "$HOME/dev" -maxdepth 1 -mindepth 1 -type d 2>/dev/null; } | awk '!seen[$0]++ { printf "\t%s\n", $0 }'
        exit 0 ;;
    --kill)
        [[ -z "${2:-}" || "$2" == "${3:-}" ]] && exit 0
        tmux kill-session -t "$2" 2>/dev/null; exit 0 ;;
esac

SELF="bash $0"

# ── Window mode ──────────────────────────────────────────────────────

if [[ "${1:-}" == "--windows" ]]; then
    selected=$(
        tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' |
        fzf --prompt="  Windows > " \
            --preview='tmux capture-pane -ep -t "$(echo {} | cut -d" " -f1)" 2>/dev/null' \
            --preview-window=right:55%:border-left \
            --color="$COLORS" --no-border --no-sort --no-separator --header=" " --layout=reverse --padding=0,3
    ) || exit 0
    target_win="$(echo "$selected" | cut -d' ' -f1)"
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$target_win"
    else
        tmux attach-session -t "$target_win"
    fi
    exit 0
fi

# ── Session picker ───────────────────────────────────────────────────

PREVIEW_SESSION='tmux capture-pane -ep -t "$(echo {} | cut -f1):=claude" 2>/dev/null'
PREVIEW_DIR='ls -1 --color=always {2} 2>/dev/null || ls -1G {2} 2>/dev/null'

selected=$(
    list_sessions |
    fzf --prompt="> " \
        --print-query \
        --pointer="" \
        --delimiter='\t' \
        --with-nth=2.. \
        --bind="ctrl-x:execute-silent($SELF --kill {1} $CURRENT_SESSION_ID)+reload($SELF --list)" \
        --bind="ctrl-f:reload($SELF --list-dirs)+change-preview($PREVIEW_DIR)" \
        --bind="ctrl-s:reload($SELF --list)+change-preview($PREVIEW_SESSION)" \
        --preview="$PREVIEW_SESSION" \
        --preview-window=right:55%:border-left \
        --color="$COLORS" --no-border --no-sort --no-separator --header=" " --info=inline-right --padding=0,3
) || exit 0

query=$(echo "$selected" | sed -n '1p')
choice=$(echo "$selected" | sed -n '2p')
# Use stable session ID (field 1) when a session was selected, fall back to query for new sessions
target=$([[ -n "$choice" ]] && echo "$choice" | cut -f1 || echo "")
name=$([[ -n "$choice" ]] && echo "$choice" | cut -f2 || echo "$query")
[[ -z "$target" && -z "$name" ]] && exit 0

# ── Act on selection ─────────────────────────────────────────────────

# Existing session → switch using stable session ID
if [[ -n "$target" ]]; then
    go_to_session "$target:=claude" "$target"
    exit 0
fi

# Resolve to a directory: use directly if path, otherwise zoxide lookup
if [[ -d "$name" ]]; then
    work_dir="$name"
else
    work_dir=$(zoxide query "$name" 2>/dev/null || echo "$HOME")
fi

# Create Claude workspace session from resolved directory (always new)
base_name="$(basename "$work_dir" | tr '.' '_')"
session_name="$base_name"
n=2
while tmux has-session -t="$session_name" 2>/dev/null; do
    session_name="${base_name}-${n}"
    n=$((n + 1))
done
tmux new-session -d -s "$session_name" -n "claude" -c "$work_dir"
tmux send-keys -t "$session_name:=claude" "claude --dangerously-skip-permissions" C-m
zoxide add "$work_dir" 2>/dev/null
go_to_session "$session_name:=claude" "$session_name"

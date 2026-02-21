#!/usr/bin/env bash
# ts.sh — tmux session/window switcher with fzf

CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
CURRENT_SESSION_ID=$(tmux display-message -p '#{session_id}' 2>/dev/null)

# Clean up stale _picker_ sessions
tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^_picker_' | while read -r s; do
    [[ "$s" != "$CURRENT_SESSION" ]] && tmux kill-session -t "$s" 2>/dev/null
done

go_to_session() {
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$1" 2>/dev/null || tmux switch-client -t "$2"
    else
        tmux attach-session -t "$1" 2>/dev/null || tmux attach-session -t "$2"
    fi
    [[ "$CURRENT_SESSION" == _picker_* ]] && tmux kill-session -t "$CURRENT_SESSION" 2>/dev/null
}

COLORS="bg+:#2d3843,fg:#908caa,fg+:#e0def4,hl:#ebbcba,hl+:#ebbcba"
COLORS+=",border:#3a4450,header:#f6c177,pointer:#ebbcba,marker:#f6c177,prompt:#ebbcba"

list_sessions() {
    # Captain first in output = bottom in fzf --layout=reverse
    tmux list-sessions -F '#{session_id} #{session_name}' 2>/dev/null | while read -r id name; do
        [[ "$name" == "$CURRENT_SESSION" ]] && continue
        [[ "$(tmux show-option -qv -t "$name" @fleet_captain 2>/dev/null)" != "1" ]] && continue
        task=$(tmux show-option -qv -t "$name" @claude_task 2>/dev/null | head -1)
        [[ -z "$task" ]] && task="Fleet Captain"
        printf '%s\t%s\t⚡ %s\t%s\n' "$id" "$name" "$task" "fleet"
    done
    tmux list-sessions -F '#{session_activity} #{session_id} #{session_name}' |
        sort -rn | while read -r _ id name; do
            [[ "$name" == "$CURRENT_SESSION" || "$name" == _picker_* ]] && continue
            [[ "$(tmux show-option -qv -t "$name" @fleet_captain 2>/dev/null)" == "1" ]] && continue
            task=$(tmux show-option -qv -t "$name" @claude_task 2>/dev/null | head -1)
            repo=$(basename "$(tmux display-message -t "$id:=claude" -p '#{pane_current_path}' 2>/dev/null)" 2>/dev/null)
            [[ -z "$task" ]] && task="$name"
            printf '%s\t%s\t%s\t%s\n' "$id" "$name" "$task" "$repo"
        done
}

case "${1:-}" in
    --list)     list_sessions; exit 0 ;;
    --list-dirs)
        { zoxide query -l 2>/dev/null; find "$HOME/dev" -maxdepth 1 -mindepth 1 -type d 2>/dev/null; } | awk -v home="$HOME" '!seen[$0]++ { display=$0; sub("^"home, "~", display); printf "\t%s\t%s\n", $0, display }'
        exit 0 ;;
    --kill)
        [[ -z "${2:-}" || "$2" == "${3:-}" ]] && exit 0
        tmux kill-session -t "$2" 2>/dev/null; exit 0 ;;
esac

SELF="bash $0"

if [[ "${1:-}" == "--windows" ]]; then
    selected=$(
        tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' |
        fzf --prompt="  Windows > " \
            --preview='tmux capture-pane -ep -t "$(echo {} | cut -d" " -f1)" 2>/dev/null' \
            --preview-window=right:55%:border-left \
            --color="$COLORS" --no-border --no-sort --no-separator --header=" " --layout=reverse --padding=0,3
    ) || exit 0
    target_win="$(echo "$selected" | cut -d' ' -f1)"
    go_to_session "$target_win" "$target_win"
    exit 0
fi

PREVIEW_SESSION='tmux capture-pane -ep -t "$(echo {} | cut -f1):=claude" 2>/dev/null'
PREVIEW_DIR='ls -1 --color=always {2} 2>/dev/null || ls -1G {2} 2>/dev/null'

selected=$(
    list_sessions |
    fzf --prompt="> " \
        --print-query \
        --pointer="" \
        --delimiter='\t' \
        --with-nth=3 \
        --nth=.. \
        --bind="ctrl-x:execute-silent($SELF --kill {1} $CURRENT_SESSION_ID)+reload($SELF --list)" \
        --bind="ctrl-f:reload($SELF --list-dirs)+change-preview($PREVIEW_DIR)" \
        --bind="ctrl-s:reload($SELF --list)+change-preview($PREVIEW_SESSION)" \
        --preview="$PREVIEW_SESSION" \
        --preview-window=right:55%:border-left \
        --color="$COLORS" --no-border --no-sort --no-separator --header=" " --info=inline-right --padding=0,3
) || exit 0

query=$(echo "$selected" | sed -n '1p')
choice=$(echo "$selected" | sed -n '2p')
target=$([[ -n "$choice" ]] && echo "$choice" | cut -f1 || echo "")
name=$([[ -n "$choice" ]] && echo "$choice" | cut -f2 || echo "$query")
[[ -z "$target" && -z "$name" ]] && exit 0

# Existing session -- switch using stable session ID
if [[ -n "$target" ]]; then
    go_to_session "$target:=claude" "$target"
    exit 0
fi

# No session matched -- resolve query to a directory and create a new workspace
if [[ -d "$name" ]]; then
    work_dir="$name"
else
    work_dir=$(zoxide query "$name" 2>/dev/null || echo "$HOME")
fi

base_name="$(basename "$work_dir" | tr '.' '_')"
session_name="$base_name"
n=2
while tmux has-session -t="$session_name" 2>/dev/null; do
    session_name="${base_name}-${n}"
    n=$((n + 1))
done
tmux new-session -d -s "$session_name" -n "claude" -c "$work_dir"
tmux set-option -t "$session_name" @claude_task "$(basename "$work_dir")"
tmux send-keys -t "$session_name:=claude" "claude --dangerously-skip-permissions" C-m
zoxide add "$work_dir" 2>/dev/null
go_to_session "$session_name:=claude" "$session_name"

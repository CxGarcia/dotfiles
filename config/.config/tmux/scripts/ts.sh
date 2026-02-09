#!/usr/bin/env bash
# ts.sh — tmux session/window switcher with fzf

CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)

COLORS="bg+:#2d3843,fg:#908caa,fg+:#e0def4,hl:#ebbcba,hl+:#ebbcba"
COLORS+=",border:#3a4450,header:#f6c177,pointer:#ebbcba,marker:#f6c177,prompt:#ebbcba"

# ── Subcommands (called by fzf binds) ───────────────────────────────

list_sessions() {
    tmux list-sessions -F '#{session_activity} #{session_name}' |
        sort -rn | awk '{print $NF}' | grep -vxF "$CURRENT_SESSION" |
        while IFS= read -r sess; do
            title=$(tmux display-message -t "$sess:=claude" -p '#{pane_title}' 2>/dev/null)
            printf '%s\t%s\n' "$sess" "$title"
        done
}

case "${1:-}" in
    --list)     list_sessions; exit 0 ;;
    --list-dirs)
        { zoxide query -l 2>/dev/null; find "$HOME/dev" -maxdepth 1 -mindepth 1 -type d 2>/dev/null; } | awk '!seen[$0]++'
        exit 0 ;;
    --kill)
        [[ -z "${2:-}" || "$2" == "${3:-}" ]] && exit 0
        tmux kill-session -t="$2" 2>/dev/null; exit 0 ;;
esac

SELF="bash $0"

# ── Window mode ──────────────────────────────────────────────────────

if [[ "${1:-}" == "--windows" ]]; then
    selected=$(
        tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' |
        fzf --prompt="  Windows > " \
            --preview='tmux capture-pane -ep -t "$(echo {} | cut -d" " -f1)" 2>/dev/null' \
            --preview-window=right:55% \
            --color="$COLORS" --border=rounded --no-sort
    ) || exit 0
    tmux switch-client -t "$(echo "$selected" | cut -d' ' -f1)"
    exit 0
fi

# ── Session picker ───────────────────────────────────────────────────

PREVIEW_SESSION='tmux capture-pane -ep -t "$(echo {} | cut -f1):=claude" 2>/dev/null'
PREVIEW_DIR='ls -1 --color=always {} 2>/dev/null || ls -1G {} 2>/dev/null'

selected=$(
    list_sessions |
    fzf --prompt="  Sessions > " \
        --print-query \
        --delimiter='\t' \
        --bind="ctrl-d:execute-silent($SELF --kill {1} $CURRENT_SESSION)+reload($SELF --list)" \
        --bind="ctrl-f:reload($SELF --list-dirs)+change-prompt(  Dirs > )+change-preview($PREVIEW_DIR)" \
        --bind="ctrl-s:reload($SELF --list)+change-prompt(  Sessions > )+change-preview($PREVIEW_SESSION)" \
        --preview="$PREVIEW_SESSION" \
        --preview-window=right:55% \
        --color="$COLORS" --border=rounded --no-sort
) || exit 0

query=$(echo "$selected" | sed -n '1p')
choice=$(echo "$selected" | sed -n '2p')
name=$([[ -n "$choice" ]] && echo "$choice" | cut -f1 || echo "$query")
[[ -z "$name" ]] && exit 0

# ── Act on selection ─────────────────────────────────────────────────

# Existing session → switch to its claude window
if tmux has-session -t="$name" 2>/dev/null; then
    tmux switch-client -t "$name:=claude" 2>/dev/null || tmux switch-client -t="$name"
    exit 0
fi

# Directory → create session named after basename
if [[ -d "$name" ]]; then
    session_name=$(basename "$name" | tr '.' '-')
    tmux has-session -t="$session_name" 2>/dev/null || tmux new-session -d -s "$session_name" -c "$name"
    tmux switch-client -t="$session_name"
    exit 0
fi

# Typed name → zoxide lookup for working dir, fallback to $HOME
work_dir=$(zoxide query "$name" 2>/dev/null || echo "$HOME")
tmux new-session -d -s "$name" -c "$work_dir"
tmux switch-client -t="$name"

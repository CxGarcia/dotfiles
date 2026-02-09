#!/usr/bin/env bash
# ts.sh — tmux session/window switcher with fzf
# Always targets the "claude" window for switching and previews.
# Shows Claude Code session name (from pane title) alongside tmux session name.
# Ctrl-f switches to zoxide directory browsing for creating sessions in specific dirs.

CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")

# Rose-pine colors (matches tmux.conf / config.fish palette)
COLORS="bg+:#2d3843,fg:#908caa,fg+:#e0def4,hl:#ebbcba,hl+:#ebbcba"
COLORS+=",border:#3a4450,header:#f6c177,pointer:#ebbcba,marker:#f6c177,prompt:#ebbcba"

# ── List sessions (tab-separated: session_name\tclaude_title) ────────
# Used by --list (for fzf reload) and the main picker
list_sessions() {
    tmux list-sessions -F '#{session_activity} #{session_name}' |
        sort -rn |
        awk '{print $NF}' |
        grep -vxF "$CURRENT_SESSION" |
        while IFS= read -r sess; do
            title=$(tmux display-message -t "$sess:=claude" -p '#{pane_title}' 2>/dev/null || echo "")
            printf '%s\t%s\n' "$sess" "${title:-}"
        done
}

if [[ "${1:-}" == "--list" ]]; then
    list_sessions
    exit 0
fi

# Kill a session (called by fzf ctrl-d bind, passes current session as $3)
if [[ "${1:-}" == "--kill" ]]; then
    target="${2:-}"
    protected="${3:-$CURRENT_SESSION}"
    [[ -z "$target" || "$target" == "$protected" ]] && exit 0
    tmux kill-session -t="$target" 2>/dev/null
    exit 0
fi

# List directories: zoxide results + ~/dev/* (deduplicated, zoxide order preserved)
if [[ "${1:-}" == "--list-dirs" ]]; then
    { zoxide query -l 2>/dev/null; find "$HOME/dev" -maxdepth 1 -mindepth 1 -type d 2>/dev/null; } | awk '!seen[$0]++'
    exit 0
fi

RELOAD_CMD="bash $(printf '%q' "$0") --list"
RELOAD_DIRS="bash $(printf '%q' "$0") --list-dirs"

# ── Self-test mode ───────────────────────────────────────────────────
if [[ "${1:-}" == "--test" ]]; then
    ok=0 fail=0
    check() {
        if eval "$2" >/dev/null 2>&1; then
            echo "  PASS: $1"; ((ok++))
        else
            echo "  FAIL: $1"; ((fail++))
        fi
    }
    echo "ts.sh self-test"
    echo "───────────────"
    check "tmux reachable"        "tmux display-message -p '#{session_name}'"
    check "fzf installed"         "command -v fzf"
    check "fzf version >= 0.30"   "fzf --version | head -1"
    check "zoxide installed"      "command -v zoxide"
    check "current session set"   "[ -n '$CURRENT_SESSION' ]"
    check "sessions listed"       "tmux list-sessions -F '#{session_name}'"
    check "list cmd works"        "$RELOAD_CMD"
    check ":=claude targeting"    "tmux display-message -t '$CURRENT_SESSION:=claude' -p '#{pane_title}'"
    check "windows listed"        "tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}'"
    echo "───────────────"
    echo "Results: $ok passed, $fail failed"
    echo "Current session: $CURRENT_SESSION"
    echo "Sessions (excluding current):"
    list_sessions | sed 's/^/  /'
    exit "$fail"
fi

# ── Window mode ──────────────────────────────────────────────────────
if [[ "${1:-}" == "--windows" ]]; then
    selected=$(
        tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}' |
        fzf --prompt="  Windows > " \
            --preview='tmux capture-pane -ep -t "$(echo {} | cut -d" " -f1)" 2>/dev/null || echo "no preview"' \
            --preview-window=right:55% \
            --color="$COLORS" \
            --border=rounded \
            --no-sort
    ) || exit 0

    target=$(echo "$selected" | cut -d' ' -f1)
    tmux switch-client -t "$target"
    exit 0
fi

# ── Session picker ───────────────────────────────────────────────────
PREVIEW_SESSION='tmux capture-pane -ep -t "$(echo {} | cut -f1):=claude" 2>/dev/null || echo "no preview"'
PREVIEW_DIR='ls -1 --color=always {} 2>/dev/null || ls -1G {} 2>/dev/null'

KILL_CMD="bash $(printf '%q' "$0") --kill {1} $CURRENT_SESSION"

selected=$(
    list_sessions |
    fzf --prompt="  Sessions > " \
        --print-query \
        --delimiter='\t' \
        --with-nth=1.. \
        --bind="ctrl-d:execute-silent($KILL_CMD)+reload($RELOAD_CMD)" \
        --bind="ctrl-f:reload($RELOAD_DIRS)+change-prompt(  Dirs > )+change-preview($PREVIEW_DIR)" \
        --bind="ctrl-s:reload($RELOAD_CMD)+change-prompt(  Sessions > )+change-preview($PREVIEW_SESSION)" \
        --preview="$PREVIEW_SESSION" \
        --preview-window=right:55% \
        --color="$COLORS" \
        --border=rounded \
        --no-sort
) || exit 0

# fzf --print-query: line 1 = typed query, line 2 = selected item
query=$(echo "$selected" | sed -n '1p')
choice=$(echo "$selected" | sed -n '2p')

# Extract session name (first tab field) from selection, or use raw query
if [[ -n "$choice" ]]; then
    name=$(echo "$choice" | cut -f1)
else
    name="$query"
fi
[[ -z "$name" ]] && exit 0

# ── Act on selection ─────────────────────────────────────────────────

# Existing session → switch to its claude window
if tmux has-session -t="$name" 2>/dev/null; then
    tmux switch-client -t "$name:=claude" 2>/dev/null || tmux switch-client -t="$name"
    exit 0
fi

# Directory path (from zoxide) → create session named after basename
if [[ -d "$name" ]]; then
    session_name=$(basename "$name" | tr '.' '-')
    if ! tmux has-session -t="$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$name"
    fi
    tmux switch-client -t="$session_name"
    exit 0
fi

# Typed name → try zoxide for a working dir, else use $HOME
work_dir=$(zoxide query "$name" 2>/dev/null || echo "$HOME")
if ! tmux has-session -t="$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$work_dir"
fi
tmux switch-client -t="$name"

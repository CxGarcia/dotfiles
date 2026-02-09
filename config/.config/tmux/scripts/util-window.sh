#!/usr/bin/env bash
# util-window.sh — Create or link a shared utility window (index 2) for git repos
# Two horizontal panes: clean shell (top) + dev server slot (bottom)
# Called by tmux after-new-session hook, or manually: bash util-window.sh [session-name]

SESSION="${1:-}"
if [[ -z "$SESSION" ]]; then
    SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null) || exit 0
fi

# Get the session's working directory
SESSION_PATH=$(tmux display-message -t "$SESSION:" -p '#{pane_current_path}' 2>/dev/null)
[[ -z "$SESSION_PATH" ]] && exit 0

# Only create utility windows for git repos
REPO_ROOT=$(git -C "$SESSION_PATH" rev-parse --show-toplevel 2>/dev/null) || exit 0

# Don't touch sessions that already have a window 2
if tmux list-windows -t "$SESSION" -F '#{window_index}' 2>/dev/null | grep -qx '2'; then
    exit 0
fi

# Search other sessions for an existing utility window tagged with this repo
existing=""
while IFS= read -r win; do
    win_repo=$(tmux show-options -wv -t "$win" @repo_root 2>/dev/null)
    if [[ "$win_repo" == "$REPO_ROOT" ]]; then
        existing="$win"
        break
    fi
done < <(tmux list-windows -a -F '#{session_name}:#{window_index}' 2>/dev/null | grep ':2$')

if [[ -n "$existing" ]]; then
    # Link the existing shared utility window into this session
    tmux link-window -s "$existing" -t "$SESSION:2" 2>/dev/null
else
    # Create a new utility window: two horizontal panes at repo root
    tmux new-window -d -t "$SESSION:2" -n "util" -c "$REPO_ROOT"
    tmux set-option -w -t "$SESSION:2" @repo_root "$REPO_ROOT"
    tmux split-window -d -v -t "$SESSION:2" -c "$REPO_ROOT"
    tmux select-pane -t "$SESSION:2.1"
fi

# Silence activity monitoring on util window (prevents bell on switch)
tmux set-option -w -t "$SESSION:2" monitor-activity off 2>/dev/null

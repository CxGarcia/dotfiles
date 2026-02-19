#!/usr/bin/env bash
# sync-title.sh — Rename tmux session once from Claude Code's pane title,
# then store subsequent titles as session metadata (@claude_task).
# Called by tmux pane-title-changed hook.
# Args: $1=session_name  $2=window_name  $3=pane_id

SESSION="$1"
WINDOW_NAME="$2"
PANE_ID="$3"

# Only care about the "claude" window
[[ "$WINDOW_NAME" != "claude" ]] && exit 0

# Only sync from the first pane (skip team agent split-panes)
PANE_INDEX=$(tmux display-message -p -t "$PANE_ID" '#{pane_index}' 2>/dev/null)
[[ "$PANE_INDEX" != "1" ]] && exit 0

# Query pane title safely via tmux (avoids shell quoting issues)
TITLE=$(tmux display-message -p -t "$PANE_ID" '#{pane_title}' 2>/dev/null)
[[ -z "$TITLE" ]] && exit 0

# Strip leading emoji/symbols and whitespace (e.g. "✳ Fix auth bug" → "Fix auth bug")
clean=${TITLE#*[[:space:]]}
[[ -z "$clean" ]] && exit 0

# Always update the metadata with the latest task description
tmux set-option -t "$SESSION" @claude_task "$clean" 2>/dev/null

# Check if session has already been renamed (locked)
locked=$(tmux show-option -qv -t "$SESSION" @title_locked 2>/dev/null)
[[ "$locked" == "1" ]] && exit 0

# Convert to tmux-safe session name: lowercase, spaces→hyphens, strip bad chars, truncate
name=$(echo "$clean" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9_-' | cut -c1-30 | sed 's/-$//')
[[ -z "$name" ]] && exit 0

# Don't rename to what it already is
[[ "$name" == "$SESSION" ]] && exit 0

# Handle conflicts by appending a suffix
final="$name"
n=2
while tmux has-session -t="$final" 2>/dev/null; do
    final="$name-$n"
    ((n++))
done

if tmux rename-session -t "$SESSION" "$final" 2>/dev/null; then
    # Lock the name so future title changes only update metadata
    tmux set-option -t "$final" @title_locked 1 2>/dev/null
    # Re-set metadata on the renamed session (session name changed)
    tmux set-option -t "$final" @claude_task "$clean" 2>/dev/null
fi

#!/usr/bin/env bash
# sync-title.sh — Rename tmux session to match Claude Code's pane title
# Called by tmux pane-title-changed hook.
# Args: $1=session_name  $2=window_name  $3=pane_title

SESSION="$1"
WINDOW_NAME="$2"
TITLE="$3"

# Only care about the "claude" window
[[ "$WINDOW_NAME" != "claude" ]] && exit 0

# Strip leading emoji/symbols and whitespace (e.g. "✳ Fix auth bug" → "Fix auth bug")
clean=${TITLE#*[[:space:]]}
[[ -z "$clean" ]] && exit 0

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

tmux rename-session -t "$SESSION" "$final" 2>/dev/null || exit 0

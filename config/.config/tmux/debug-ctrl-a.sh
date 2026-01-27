#!/bin/bash
# Debug script to check what tmux sees

current_pane_program=$(tmux display-message -p '#{pane_current_command}')
current_session=$(tmux display-message -p '#{session_name}')

echo "Current program: [$current_pane_program]"
echo "Current session: [$current_session]"
echo ""
echo "Checking conditions:"

if [ "$current_pane_program" = "nvim" ]; then
    echo "✓ Program matches 'nvim'"
else
    echo "✗ Program does NOT match 'nvim'"
fi

if [ "$current_session" = "fam-dashboard" ]; then
    echo "✓ Session matches 'fam-dashboard'"
else
    echo "✗ Session does NOT match 'fam-dashboard'"
fi

echo ""
echo "Would execute:"
if [ "$current_pane_program" = "nvim" ] || [ "$current_session" = "fam-dashboard" ]; then
    echo "→ send Ctrl-a to application"
else
    echo "→ open sesh fuzzy finder"
fi

function tclaude --description "Claude Code workspace with dev layout"
    argparse n/new -- $argv
    or return 1

    set -l base_name (basename $PWD | tr . _)-workspace
    set -l dev_cmd $argv[1]

    # Track this directory in zoxide so it appears in the session picker
    zoxide add $PWD 2>/dev/null

    if set -q _flag_new
        set -l suffix 1
        while tmux has-session -t "$base_name-$suffix" 2>/dev/null
            set suffix (math $suffix + 1)
        end
        set base_name "$base_name-$suffix"
    end

    if not tmux has-session -t $base_name 2>/dev/null
        # Create session with Claude window (full screen)
        tmux new-session -d -s $base_name -n "claude" -c $PWD
        tmux send-keys -t "$base_name:claude" "claude --dangerously-skip-permissions" C-m

        # Create dev window only if dev command provided
        if test -n "$dev_cmd"
            tmux new-window -t $base_name -n "dev" -c $PWD
            tmux split-window -v -t "$base_name:dev" -p 50 -c $PWD
            tmux send-keys -t "$base_name:dev.1" "$dev_cmd" C-m
            # Focus back on Claude window
            tmux select-window -t "$base_name:claude"
        end
    else
        # Session exists — check if Claude is running in it
        # Handles restored sessions from resurrect where panes are empty
        set -l pane_cmd (tmux list-panes -t "$base_name:claude" -F '#{pane_current_command}' 2>/dev/null | head -1)
        if test "$pane_cmd" != claude
            tmux send-keys -t "$base_name:claude" "claude --dangerously-skip-permissions" C-m
        end
    end

    if test -z "$TMUX"
        tmux attach-session -t $base_name
    else
        tmux switch-client -t $base_name
    end
end

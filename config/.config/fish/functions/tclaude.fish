function tclaude --description "Claude Code workspace with dev layout"
    argparse n/new -- $argv
    or return 1

    set -l base_name (basename $PWD | tr . _)-workspace
    set -l dev_cmd $argv[1]

    if set -q _flag_new
        set -l suffix 1
        while tmux has-session -t "$base_name-$suffix" 2>/dev/null
            set suffix (math $suffix + 1)
        end
        set base_name "$base_name-$suffix"
    end

    if not tmux has-session -t $base_name 2>/dev/null
        tmux new-session -d -s $base_name -c $PWD

        # Split vertically: left 60%, right 40%
        tmux split-window -h -t "$base_name:1" -p 40 -c $PWD

        # Split right pane horizontally: top 50%, bottom 50%
        tmux split-window -v -t "$base_name:1.2" -p 50 -c $PWD

        # Start Claude Code in left pane
        tmux send-keys -t "$base_name:1.1" "claude --dangerously-skip-permissions" C-m

        # Start dev server in right top pane if command provided
        if test -n "$dev_cmd"
            tmux send-keys -t "$base_name:1.2" "$dev_cmd" C-m
        end

        # Focus Claude Code pane
        tmux select-pane -t "$base_name:1.1"
    end

    if test -z "$TMUX"
        tmux attach-session -t $base_name
    else
        tmux switch-client -t $base_name
    end
end

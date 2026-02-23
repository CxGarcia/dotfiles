function tclaude --description "Claude Code workspace with dev layout"
    argparse n/new o/orchestrator -- $argv
    or return 1

    if set -q _flag_orchestrator
        set -l session_name fleet-captain

        if not tmux has-session -t $session_name 2>/dev/null
            tmux new-session -d -s $session_name -n "claude" -c $PWD
            tmux set-option -t $session_name @fleet_captain 1
            tmux new-window -d -t $session_name:2 -n util -c $PWD
            tmux split-window -d -v -t "$session_name:2" -c $PWD
            tmux set-option -w -t "$session_name:2" monitor-activity off
            tmux select-window -t "$session_name:1"
        end
        _tclaude_ensure_claude $session_name
        _tclaude_attach $session_name
        return
    end

    set -l base_name (basename $PWD | tr . _)-workspace
    set -l dev_cmd $argv[1]

    zoxide add $PWD 2>/dev/null

    if set -q _flag_new
        set -l suffix 1
        while tmux has-session -t "$base_name-$suffix" 2>/dev/null
            set suffix (math $suffix + 1)
        end
        set base_name "$base_name-$suffix"
    end

    if not tmux has-session -t $base_name 2>/dev/null
        tmux new-session -d -s $base_name -n "claude" -c $PWD
        tmux set-option -t $base_name @claude_task (basename $PWD)
        tmux send-keys -t "$base_name:claude" "claude --dangerously-skip-permissions" C-m

        if test -n "$dev_cmd"
            tmux new-window -t $base_name -n "dev" -c $PWD
            tmux split-window -v -t "$base_name:dev" -p 50 -c $PWD
            tmux send-keys -t "$base_name:dev.1" "$dev_cmd" C-m
            tmux select-window -t "$base_name:claude"
        end
    else
        _tclaude_ensure_claude $base_name
    end

    _tclaude_attach $base_name
end

function _tclaude_ensure_claude
    set -l pane_cmd (tmux list-panes -t "$argv[1]:claude" -F '#{pane_current_command}' 2>/dev/null | head -1)
    if test "$pane_cmd" != claude
        tmux send-keys -t "$argv[1]:claude" "claude --dangerously-skip-permissions" C-m
    end
end

function _tclaude_attach
    if test -z "$TMUX"
        tmux attach-session -t $argv[1]
    else
        tmux switch-client -t $argv[1]
    end
end

function tclaude --description "AI workspace with dev layout"
    argparse n/new o/orchestrator c/codex -- $argv
    or return 1

    set -l engine claude
    set -l launch_cmd "claude --dangerously-skip-permissions"
    if set -q _flag_codex
        set engine codex
        set launch_cmd "codex --full-auto"
    end

    if set -q _flag_orchestrator
        set -l session_name fleet-captain

        if not tmux has-session -t $session_name 2>/dev/null
            tmux new-session -d -s $session_name -n "claude" -c $PWD
            tmux set-option -t $session_name @fleet_captain 1
            tmux set-option -t $session_name @fleet_engine $engine
            tmux new-window -d -t $session_name:2 -n util -c $PWD
            tmux split-window -d -v -t "$session_name:2" -c $PWD
            tmux set-option -w -t "$session_name:2" monitor-activity off
            tmux select-window -t "$session_name:1"
            tmux send-keys -t "$session_name:claude" "$launch_cmd" C-m
            _tclaude_wait_and_send $session_name /fleet-captain $engine &
        else
            _tclaude_ensure_engine $session_name $engine
        end
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
        tmux set-option -t $base_name @fleet_engine $engine
        tmux set-option -t $base_name @claude_task (basename $PWD)
        tmux send-keys -t "$base_name:claude" "$launch_cmd" C-m

        if test -n "$dev_cmd"
            tmux new-window -t $base_name -n "dev" -c $PWD
            tmux split-window -v -t "$base_name:dev" -p 50 -c $PWD
            tmux send-keys -t "$base_name:dev.1" "$dev_cmd" C-m
            tmux select-window -t "$base_name:claude"
        end
    else
        _tclaude_ensure_engine $base_name $engine
    end

    _tclaude_attach $base_name
end

function _tclaude_wait_and_send
    set -l session $argv[1]
    set -l cmd $argv[2]
    set -l engine $argv[3]
    for i in (seq 1 30)
        set -l content (tmux capture-pane -t "$session:claude" -p -S -5 2>/dev/null)
        set -l ready 0
        if test "$engine" = codex
            if string match -qr '(^|\n)(›|>) ' -- $content; and not string match -qr 'esc to interrupt|Working \(|Booting MCP server' -- $content
                set ready 1
            end
        else if string match -q '*❯*' $content; and not string match -qr 'ctrl.c to interrupt|tokens' -- $content
            set ready 1
        end
        if test $ready -eq 1
            sleep 1
            tmux send-keys -t "$session:claude" -l $cmd
            sleep 0.5
            tmux send-keys -t "$session:claude" Enter
            return
        end
        sleep 2
    end
end

function _tclaude_ensure_engine
    set -l engine $argv[2]
    set -l pane_cmd (tmux list-panes -t "$argv[1]:claude" -F '#{pane_current_command}' 2>/dev/null | head -1)
    if test "$engine" = codex
        if not string match -qr '^codex' -- $pane_cmd
            tmux send-keys -t "$argv[1]:claude" "codex --full-auto" C-m
        end
    else if test "$pane_cmd" != claude
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

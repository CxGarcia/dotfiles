function tk --description "Kill tmux sessions with fzf multi-select"
    set -l sessions (tmux list-sessions -F "#{session_name}" 2>/dev/null)

    if test -z "$sessions"
        echo "No tmux sessions"
        return 1
    end

    set -l to_kill (printf '%s\n' $sessions | fzf --multi --height 40% --reverse --prompt="kill> ")
    test -z "$to_kill"; and return

    for s in $to_kill
        tmux kill-session -t "$s"
        echo "Killed session: $s"
    end
end

function ts --description "Tmux session switcher with fzf"
    set -l sessions (tmux list-sessions -F "#{session_name}" 2>/dev/null)

    if test -z "$sessions"
        echo "No tmux sessions"
        return 1
    end

    set -l session (printf '%s\n' $sessions | fzf --height 40% --reverse --prompt="session> ")
    test -z "$session"; and return

    if set -q TMUX
        tmux switch-client -t "$session"
    else
        tmux attach-session -t "$session"
    end
end

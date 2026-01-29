function tl --description "Switch to last tmux session"
    if not set -q TMUX
        echo "Not in tmux"
        return 1
    end
    tmux switch-client -l
end

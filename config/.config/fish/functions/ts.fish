function ts --description "tmux session picker"
    if set -q TMUX
        bash ~/.config/tmux/scripts/ts.sh $argv
        return
    end

    set -l session "_picker_"(random)
    set -l script "$HOME/.config/tmux/scripts/ts.sh"

    tmux new-session -d -s $session
    tmux set-option -t $session status off
    tmux set-hook -t $session client-attached "display-popup -E -w 80% -h 70% -S fg=#3a4450 \"bash $script\""
    tmux attach-session -t $session
    tmux kill-session -t $session 2>/dev/null
end

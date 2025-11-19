# ==========================================
# Tmux + Sesh Configuration
# ==========================================
# Smart tmux session management with telescope-style UI

# t: Smart tmux attach - attach to last session or create new
function t() {
    if tmux has-session 2>/dev/null; then
        tmux attach-session
    else
        tmux new-session
    fi
}

# ta: Attach to or create named session
function ta() {
    local session_name="${1:-default}"
    tmux new-session -A -s "$session_name"
}

# tdev: Create or switch to tmux session based on current directory
function tdev() {
    local session_name=$(basename "$PWD" | tr . _)

    # Use exact matching by checking if session exists in list
    if ! tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -q "^${session_name}$"; then
        tmux new-session -d -s "$session_name" -c "$PWD"
        # Disable status bar for this session
        tmux set-option -t "$session_name" status off
        # Open nvim in current directory (shows file tree)
        tmux send-keys -t "$session_name:1" "nvim ." C-m
    fi

    if [ -z "$TMUX" ]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# tai: Create or switch to Claude Code session for current directory
# Usage: tai [name]
#   tai        -> Creates "projectname-claude" session
#   tai task1  -> Creates "projectname-claude-task1" session
#   tai review -> Creates "projectname-claude-review" session
function tai() {
    local base_name="$(basename "$PWD" | tr . _)-claude"
    local session_name="$base_name"

    # If argument provided, append it to create unique session
    if [ -n "$1" ]; then
        session_name="${base_name}-$1"
    fi

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$PWD"
        # Disable status bar for this session
        tmux set-option -t "$session_name" status off
        # Start Claude Code with dangerously-skip-permissions flag
        tmux send-keys -t "$session_name:1" "claude --dangerously-skip-permissions" C-m
    fi

    if [ -z "$TMUX" ]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# tfam: Create or switch to fam dashboard tmux session
function tfam() {
    local session_name="fam-dashboard"

    # Check if session already exists (exact match)
    if tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -q "^${session_name}$"; then
        # Session exists, just attach/switch
        if [ -z "$TMUX" ]; then
            tmux attach-session -t "$session_name"
        else
            tmux switch-client -t "$session_name"
        fi
        return
    fi

    # Session doesn't exist, create it with fam dashboard running
    # For interactive TUI apps, we need to create the session directly with the command
    # Note: Ctrl-a passthrough is handled in tmux.conf for fam-dashboard session
    if [ -z "$TMUX" ]; then
        # Not in tmux: create and attach with fam dashboard running
        tmux new-session -s "$session_name" -c "$HOME" \; \
            set-option -t "$session_name" status off \; \
            send-keys "fam dashboard" C-m
    else
        # Already in tmux: create detached, give dashboard time to initialize, then switch
        tmux new-session -d -s "$session_name" -c "$HOME" \; \
            set-option -t "$session_name" status off \; \
            send-keys -t "$session_name:1" "fam dashboard" C-m
        # Small delay to let dashboard initialize before switching
        sleep 0.5
        tmux switch-client -t "$session_name"
    fi
}

# ts: Simple telescope-style session switcher with sesh
function ts() {
    if ! command -v sesh &> /dev/null; then
        echo "sesh not found. Install with: brew install joshmedeski/sesh/sesh"
        return 1
    fi

    local session=$(
        sesh list | \
        fzf \
            --height=80% \
            --border=rounded \
            --border-label=' Sessions ' \
            --prompt='❯ ' \
            --pointer='▶' \
            --header='Enter: switch | Ctrl-d: delete' \
            --preview='
                if tmux has-session -t {} 2>/dev/null; then
                    echo "Session: {}"
                    echo ""
                    tmux list-windows -t {} -F "  #{window_index}: #{window_name}"
                elif [ -d "{}" ]; then
                    echo "Directory: {}"
                    echo ""
                    if command -v eza &> /dev/null; then
                        eza -la --icons --git --color=always {} 2>/dev/null | head -15
                    else
                        ls -lah {} | tail -n +4 | head -15
                    fi
                else
                    echo "New session: {}"
                fi
            ' \
            --preview-window='right:55%:border-rounded' \
            --bind='ctrl-d:execute(tmux kill-session -t {})+reload(sesh list)'
    )

    [[ -z "$session" ]] && return
    sesh connect "$session"
}

# Keybindings: Ctrl-s to open tmux session switcher
bindkey -s '^s' 'ts\n'
# Ctrl-a removed to avoid conflict with tmux prefix (C-a)
# bindkey -s '^a' 'ts\n'

# Smart tmux alias - never create unwanted sessions
alias tm='t'

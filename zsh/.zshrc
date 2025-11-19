
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/cristobalschlaubitz/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

plugins=(git fzf)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# fix Hyper first line precent sign

# Delete % at the beginning
unsetopt PROMPT_SP


# Adds a blank line between prompts
#POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
#POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=’red’

## getting python environment PIPENV in terminal ##
#export PATH="/Users/cristobalschlaubitz/Library/Python/3.7/lib/python/site-packages:$PATH"

##pip packages Bin
#export PATH="~/Library/Python/3.7/bin:$PATH"
#export PYTHONPATH="${PYTHONPATH}:/Users/cristobalschlaubitz/Library/Python/3.7/bin"

##Jupyter command
#alias jupyter='/Users/cristobalschlaubitz/Library/Python/3.7/bin/jupyter'

autoload bashcompinit

export DEV="$HOME/dev"
export CXBIN="$DEV/cx-scripts"

export DEV=$HOME/dev
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export BREWBIN=/opt/homebrew/bin
export LOCALBIN=$HOME/.local/bin
export NODEBIN="/opt/homebrew/opt/node@22/bin"
export MYSQLBIN=/opt/homebrew/opt/mysql-client/bin
export CXBIN=$HOME/dotfiles/mac/mac-scripts
export PYTHONBIN=/opt/homebrew/opt/python@3.13/libexec/bin
export PATH="$PATH:$CXBIN:$GOBIN:$NODEBIN:$MYSQLBIN:$BREWBIN:$PYTHONBIN:$LOCALBIN:/usr/local/sbin"

# Only load interactive features in interactive shells
if [[ -o interactive ]]; then
    #syntax Highlight
    source $ZSH/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    #starship prompt
    eval "$(starship init zsh)"
fi

#######ALIASES#######

##sync brancher w/ remote and delete all local
alias gbda="git fetch --prune && git branch --v | grep '\[gone\]' | awk '{print $1}' | xargs git branch -D"

##get current size of all node_modules
alias nmgs="find . -name "node_modules" -type d -prune -print | xargs du -chs"

##delete all node_modules
alias nmda="seekndestroy node_modules"

alias destroynode="seekndestroy node_modules; seekndestroy dist; seekndestroy build; seekndestroy .turbo; seekndestroy turbo;"

alias gprs="gho -p"

##push sync retropie
alias retropush="rsync -arv ~/Documents/retropie/* pi@192.168.0.31:~/RetroPie/roms/"

## alias code="zed"
# alias code="cursor"

##ssh
alias wpcloud="ssh cx@46.101.204.150"
alias cxcloud="ssh cx@159.89.111.58"
alias hotcloud="ssh cx@207.154.201.191"

#######END-ALIASES#######

#prevent brew from updating on every install
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

#completions

zstyle :compinstall filename '/Users/cristobalschlaubitz/.zshrc'

autoload -Uz compinit
fpath+=~/.zfunc
[ -s "/Users/cristobalschlaubitz/.bun/_bun" ] && source "/Users/cristobalschlaubitz/.bun/_bun"

compinit

zstyle :compinstall filename '/Users/cristobalschlaubitz/.zshrc'
compdef _cdd cdd

# spaceship
SPACESHIP_TIME_SHOW=true

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. /opt/homebrew/opt/asdf/libexec/asdf.sh

export GOTOOLCHAIN=auto

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Nest development environment (only in interactive shells)
if [[ -o interactive ]]; then
    [ -f ~/.nest/nest-init.sh ] && source ~/.nest/nest-init.sh
fi

# ==========================================
# tmux + sesh helper functions
# ==========================================

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
#   tai        → Creates "projectname-claude" session
#   tai task1  → Creates "projectname-claude-task1" session
#   tai review → Creates "projectname-claude-review" session
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

# ts: Quick tmux session switcher with fzf (works outside tmux)
function ts() {
    # If no sessions exist, create one
    if ! tmux has-session 2>/dev/null; then
        echo "No tmux sessions. Creating 'default' session..."
        tmux new-session -s default
        return
    fi

    local session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | \
        fzf --border=rounded --prompt='Session: ' --reverse \
            --preview="tmux list-windows -t {}" \
            --preview-window=right:50%)

    if [ -n "$session" ]; then
        if [ -z "$TMUX" ]; then
            tmux attach-session -t "$session"
        else
            tmux switch-client -t "$session"
        fi
    fi
}

# Keybinding: Ctrl-s to open tmux session switcher
bindkey -s '^s' 'ts\n'

# Smart tmux alias - never create unwanted sessions
alias tm='t'

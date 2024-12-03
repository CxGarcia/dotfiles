
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

plugins=(git)

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
export NODEBIN="/opt/homebrew/opt/node@20/bin"
export CONDABIN=/opt/homebrew/anaconda3/bin
export MYSQLBIN=/opt/homebrew/opt/mysql-client/bin
export CXBIN=$HOME/dotfiles/mac/mac-scripts
export PATH="$PATH:$CXBIN:$GOBIN:$NODEBIN:$CONDABIN:$MYSQLBIN:/usr/local/sbin"


#syntax Highlight
source $ZSH/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


#starship prompt
eval "$(starship init zsh)"

#######ALIASES#######

##sync brancher w/ remote and delete all local
alias gbda="git fetch --prune && git branch --v | grep '\[gone\]' | awk '{print $1}' | xargs git branch -D"

##get current size of all node_modules
alias nmgs="find . -name "node_modules" -type d -prune -print | xargs du -chs"

##delete all node_modules
alias nmda="seekndestroy node_modules"

alias destroynode="seekndestroy node_modules; seekndestroy dist; seekndestroy build; seekndestroy .turbo; seekndestroy turbo;"

##push sync retropie
alias retropush="rsync -arv ~/Documents/retropie/* pi@192.168.0.31:~/RetroPie/roms/"

##zed as default editor
alias code="cursor"

##ssh
alias wpcloud="ssh cx@46.101.204.150"
alias cxcloud="ssh cx@159.89.111.58"
alias hotcloud="ssh cx@207.154.201.191"
#######END-ALIASES#######

source $CXBIN/cdn-completion.zsh

#prevent brew from updating on every install
export HOMEBREW_NO_AUTO_UPDATE=1

#completions
zstyle :compinstall filename '/Users/cristobalschlaubitz/.zshrc'

autoload -Uz compinit
fpath+=~/.zfunc

compinit

SPACESHIP_TIME_SHOW=true


# bun completions
[ -s "/Users/cristobalschlaubitz/.bun/_bun" ] && source "/Users/cristobalschlaubitz/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
###-begin-npm-completion-###
#
# npm command completion script
#
# Installation: npm completion >> ~/.bashrc  (or ~/.zshrc)
# Or, maybe: npm completion > /usr/local/etc/bash_completion.d/npm
#

if type complete &>/dev/null; then
  _npm_completion () {
    local words cword
    if type _get_comp_words_by_ref &>/dev/null; then
      _get_comp_words_by_ref -n = -n @ -n : -w words -i cword
    else
      cword="$COMP_CWORD"
      words=("${COMP_WORDS[@]}")
    fi

    local si="$IFS"
    if ! IFS=$'\n' COMPREPLY=($(COMP_CWORD="$cword" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           npm completion -- "${words[@]}" \
                           2>/dev/null)); then
      local ret=$?
      IFS="$si"
      return $ret
    fi
    IFS="$si"
    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "${words[cword]}"
    fi
  }
  complete -o default -F _npm_completion npm
elif type compdef &>/dev/null; then
  _npm_completion() {
    local si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 npm completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef _npm_completion npm
elif type compctl &>/dev/null; then
  _npm_completion () {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    if ! IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       npm completion -- "${words[@]}" \
                       2>/dev/null)); then

      local ret=$?
      IFS="$si"
      return $ret
    fi
    IFS="$si"
  }
  compctl -K _npm_completion npm
fi
###-end-npm-completion-###

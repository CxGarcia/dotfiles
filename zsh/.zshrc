# =============================================================================
# Oh-My-Zsh
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_DISABLE_COMPFIX=true
DISABLE_AUTO_UPDATE=true
plugins=(git)
source $ZSH/oh-my-zsh.sh

# =============================================================================
# Environment
# =============================================================================

export EDITOR=nvim
export VISUAL=nvim
export GOTOOLCHAIN=auto

export DEV=$HOME/dev
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export BUN_INSTALL="$HOME/.bun"

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# =============================================================================
# PATH
# =============================================================================

export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
export PATH="$PATH:$HOME/dotfiles/mac/mac-scripts"
export PATH="$PATH:$GOBIN"
export PATH="$PATH:/opt/homebrew/opt/node@22/bin"
export PATH="$PATH:/opt/homebrew/opt/mysql-client/bin"
export PATH="$PATH:/opt/homebrew/bin"
export PATH="$PATH:/opt/homebrew/opt/python@3.13/libexec/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/usr/local/sbin"
export PATH="$PATH:$HOME/.asdf/shims"

# =============================================================================
# Helpers
# =============================================================================

lazy_load() {
    local init=$1; shift
    for cmd in "$@"; do
        eval "${cmd}() { unfunction $* 2>/dev/null; ${init}; ${cmd} \"\$@\" }"
    done
}

# =============================================================================
# Version Managers (lazy loaded)
# =============================================================================

lazy_load 'eval "$(fnm env --use-on-cd --shell zsh)"' node npm npx pnpm yarn
lazy_load '. /opt/homebrew/opt/asdf/libexec/asdf.sh' asdf

# =============================================================================
# Completions
# =============================================================================

autoload bashcompinit
fpath+=~/.zfunc
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
compdef _cdd cdd 2>/dev/null

# =============================================================================
# Prompt
# =============================================================================

unsetopt PROMPT_SP

if [[ -o interactive ]] && command -v starship &>/dev/null; then
    starship_cache="$HOME/.cache/starship_init.zsh"
    starship_config="$HOME/.config/starship.toml"
    if [[ ! -f "$starship_cache" ]] || [[ "$starship_config" -nt "$starship_cache" ]]; then
        mkdir -p "$HOME/.cache"
        starship init zsh > "$starship_cache"
    fi
    source "$starship_cache"
fi

# =============================================================================
# Plugins
# =============================================================================

if [[ -o interactive ]]; then
    source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
    {
        source $ZSH/plugins/fzf/fzf.plugin.zsh 2>/dev/null
        source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
    } &!
fi

[ -f ~/.zsh/fzf.zsh ] && source ~/.zsh/fzf.zsh
[ -f ~/.zsh/tmux.zsh ] && source ~/.zsh/tmux.zsh

# =============================================================================
# Aliases
# =============================================================================

# Git
alias gbda="git fetch --prune && git branch -v | grep '\[gone\]' | awk '{print \$1}' | xargs git branch -D"
alias gprs="gho -p"

# Node
alias nmgs='find . -name "node_modules" -type d -prune -print | xargs du -chs'
alias nmda="seekndestroy node_modules"
alias destroynode="seekndestroy node_modules; seekndestroy dist; seekndestroy build; seekndestroy .turbo; seekndestroy turbo;"

# SSH
alias wpcloud="ssh cx@46.101.204.150"
alias cxcloud="ssh cx@159.89.111.58"
alias hotcloud="ssh cx@207.154.201.191"

# Misc
alias retropush="rsync -arv ~/Documents/retropie/* pi@192.168.0.31:~/RetroPie/roms/"

# =============================================================================
# Environment
# =============================================================================

set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx GOTOOLCHAIN auto

set -gx DEV $HOME/dev
set -gx GOPATH $HOME/go
set -gx GOBIN $GOPATH/bin
set -gx BUN_INSTALL $HOME/.bun

set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx HOMEBREW_NO_INSTALL_CLEANUP 1

# =============================================================================
# PATH
# =============================================================================

fish_add_path -g $BUN_INSTALL/bin
fish_add_path -g $HOME/.antigravity/antigravity/bin
fish_add_path -g /opt/homebrew/opt/postgresql@18/bin
fish_add_path -g $HOME/dotfiles/mac/mac-scripts
fish_add_path -g $GOBIN
fish_add_path -g /opt/homebrew/opt/node@22/bin
fish_add_path -g /opt/homebrew/opt/mysql-client/bin
fish_add_path -g /opt/homebrew/bin
fish_add_path -g /opt/homebrew/opt/python@3.13/libexec/bin
fish_add_path -g $HOME/.local/bin
fish_add_path -g /usr/local/sbin
fish_add_path -g $HOME/.asdf/shims
fish_add_path -g /Applications/Tailscale.app/Contents/MacOS

# =============================================================================
# Version Managers
# =============================================================================

# fnm (fast node manager)
if command -q fnm
    fnm env --use-on-cd --shell fish | source
end

# asdf
if test -f /opt/homebrew/opt/asdf/libexec/asdf.fish
    source /opt/homebrew/opt/asdf/libexec/asdf.fish
end

# =============================================================================
# Prompt (Starship)
# =============================================================================

if status is-interactive && command -q starship
    starship init fish | source
end

# =============================================================================
# Completions
# =============================================================================

# Tab opens completions and lets you type to filter (keeps list open)
bind \t complete-and-search

# Up/down arrows search history by prefix (type 'cl' then up to find 'claude')
bind \e\[A history-search-backward
bind \e\[B history-search-forward

# bun completions
if test -f $HOME/.bun/_bun.fish
    source $HOME/.bun/_bun.fish
end

# Completion pager colors (rose-pine)
set -g fish_pager_color_progress e0def4 --background=26233a
set -g fish_pager_color_prefix 9ccfd8 --bold      # foam
set -g fish_pager_color_completion e0def4         # text
set -g fish_pager_color_description f6c177        # gold
set -g fish_pager_color_selected_background --background=26233a

# Syntax highlighting colors (rose-pine)
set -g fish_color_command 9ccfd8           # foam - valid commands
set -g fish_color_error eb6f92             # love - invalid commands
set -g fish_color_param c4a7e7             # iris - parameters
set -g fish_color_quote f6c177             # gold - quoted strings
set -g fish_color_autosuggestion 6e6a86    # muted - autosuggestions
set -g fish_color_comment 6e6a86           # muted - comments
set -g fish_color_operator ebbcba          # rose - operators like * and ~
set -g fish_color_redirection 31748f       # pine - redirections > >> |
set -g fish_color_end 9ccfd8               # foam - ; and &
set -g fish_color_escape ebbcba            # rose - escape sequences
set -g fish_color_selection --background=26233a  # overlay - selection bg
set -g fish_color_search_match --background=26233a

# =============================================================================
# Aliases
# =============================================================================

# Git
alias gbda "git fetch --prune && git branch -v | grep '\[gone\]' | awk '{print \$1}' | xargs git branch -D"
alias gprs "gho -p"

# Node
alias nmgs 'find . -name "node_modules" -type d -prune -print | xargs du -chs'
alias nmda "seekndestroy node_modules"
alias destroynode "seekndestroy node_modules; seekndestroy dist; seekndestroy build; seekndestroy .turbo; seekndestroy turbo"

# SSH
alias wpcloud "ssh cx@46.101.204.150"
alias cxcloud "ssh cx@159.89.111.58"
alias hotcloud "ssh cx@207.154.201.191"

# Listing
alias lsa "ls -lah"
alias ll "ls -lh"
alias la "ls -ah"

# Navigation
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."

# Misc
alias retropush "rsync -arv ~/Documents/retropie/* pi@192.168.0.31:~/RetroPie/roms/"

# Abbreviations
abbr -a pbc pbcopy
abbr -a pbp pbpaste
abbr -a ef "$EDITOR ~/.config/fish/config.fish"
abbr -a sf "source ~/.config/fish/config.fish"
abbr -a cl clear

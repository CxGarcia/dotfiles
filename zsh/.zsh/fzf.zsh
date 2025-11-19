# ==========================================
# FZF Configuration - Rose Pine Theme
# ==========================================
# Matches telescope.nvim Rose Pine theme for consistent UI across tools

# Rose Pine colors (main variant)
export FZF_DEFAULT_OPTS=" \
--color=bg+:#26233a,bg:#191724,spinner:#9ccfd8,hl:#ebbcba \
--color=fg:#e0def4,header:#eb6f92,info:#c4a7e7,pointer:#9ccfd8 \
--color=marker:#eb6f92,fg+:#e0def4,prompt:#c4a7e7,hl+:#ebbcba \
--color=border:#6e6a86 \
--border=rounded \
--border-label-pos=2 \
--preview-window=border-rounded \
--prompt=' ' \
--marker=' ' \
--pointer=' ' \
--separator='─' \
--scrollbar='│' \
--layout=default \
--info=right"

# FZF default command (use fd for better performance)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

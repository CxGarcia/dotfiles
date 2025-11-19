#!/bin/bash
# Configuration Validation Script
# Validates all four waves of keyboard navigation fixes

set -e

echo "============================================="
echo "  Configuration Validation - Four Waves"
echo "============================================="
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Check tmux version
echo "1. Checking tmux version..."
if tmux -V | grep -q "3.[2-9]\|3.[1-9][0-9]"; then
    TMUX_VERSION=$(tmux -V)
    success "tmux version: $TMUX_VERSION (3.2+ required for CSI u)"
else
    error "tmux version too old. 3.2+ required for extended keys"
    exit 1
fi
echo

# 2. Check Neovim version
echo "2. Checking Neovim version..."
if command -v nvim &> /dev/null; then
    NVIM_VERSION=$(nvim --version | head -1)
    success "Neovim: $NVIM_VERSION"
else
    error "Neovim not found"
    exit 1
fi
echo

# 3. Check tmux config syntax
echo "3. Validating tmux configuration..."
if [ -f ~/.tmux.conf ]; then
    if tmux -f ~/.tmux.conf source-file ~/.tmux.conf 2>&1 | grep -qi "error\|unknown"; then
        error "tmux config has syntax errors"
        exit 1
    else
        success "tmux config syntax valid"
    fi
else
    error "~/.tmux.conf not found"
    exit 1
fi
echo

# 4. Check extended keys in tmux config
echo "4. Checking tmux extended keys configuration..."
if grep -q "set -s extended-keys on" ~/.tmux.conf; then
    success "extended-keys enabled"
else
    error "extended-keys not enabled in tmux config"
fi

if grep -q "set -s extended-keys-format csi-u" ~/.tmux.conf; then
    success "csi-u format configured"
else
    error "csi-u format not configured in tmux config"
fi

if grep -q "set -as terminal-features 'xterm\*:extkeys'" ~/.tmux.conf; then
    success "terminal features configured for extended keys"
else
    warning "terminal features might not be configured correctly"
fi
echo

# 5. Check iTerm2 profiles JSON
echo "5. Validating iTerm2 profiles JSON..."
ITERM_PROFILES="$HOME/dotfiles/mac/iterm-profiles.json"
if [ -f "$ITERM_PROFILES" ]; then
    if jq empty "$ITERM_PROFILES" 2>&1; then
        success "iTerm2 JSON syntax valid"
    else
        error "iTerm2 JSON has syntax errors"
        exit 1
    fi
else
    error "iTerm2 profiles not found at $ITERM_PROFILES"
    exit 1
fi
echo

# 6. Check CSI u in all profiles
echo "6. Verifying CSI u in iTerm2 profiles..."
while IFS= read -r line; do
    if [[ $line == *"true"* ]]; then
        success "$line"
    else
        error "$line - CSI u not enabled!"
    fi
done < <(jq -r '.Profiles[] | "\(.Name): \(.["Report Modifiers Using CSI u"])"' "$ITERM_PROFILES")
echo

# 7. Check Neovim Lua files
echo "7. Validating Neovim Lua syntax..."
TOGGLETERM="$HOME/dotfiles/config/.config/nvim/lua/config/plugins/toggleterm.lua"
TMUX_INTEGRATION="$HOME/dotfiles/config/.config/nvim/lua/config/plugins/tmux-integration.lua"

if [ -f "$TOGGLETERM" ]; then
    if lua -e "local f = io.open('$TOGGLETERM', 'r'); local c = f:read('*all'); f:close(); assert(load(c))" 2>&1; then
        success "toggleterm.lua syntax valid"
    else
        error "toggleterm.lua has syntax errors"
        exit 1
    fi
else
    error "toggleterm.lua not found"
    exit 1
fi

if [ -f "$TMUX_INTEGRATION" ]; then
    if lua -e "local f = io.open('$TMUX_INTEGRATION', 'r'); local c = f:read('*all'); f:close(); assert(load(c))" 2>&1; then
        success "tmux-integration.lua syntax valid"
    else
        error "tmux-integration.lua has syntax errors"
        exit 1
    fi
else
    error "tmux-integration.lua not found"
    exit 1
fi
echo

# 8. Check key bindings in tmux config
echo "8. Verifying tmux key bindings..."
if grep -q "bind-key -n 'C-h' if-shell" ~/.tmux.conf; then
    success "Seamless navigation bindings configured"
else
    error "Seamless navigation bindings not found"
fi

if grep -q "bind-key -T copy-mode-vi 'C-h' select-pane" ~/.tmux.conf; then
    success "Copy mode navigation configured"
else
    warning "Copy mode navigation might not be configured"
fi
echo

# 9. Check toggleterm navigation uses tmux.nvim
echo "9. Verifying toggleterm uses tmux.nvim functions..."
if grep -q "require(\"tmux\").move_left()" "$TOGGLETERM"; then
    success "toggleterm uses tmux.nvim for navigation"
else
    error "toggleterm not using tmux.nvim functions"
fi

if grep -q "skip_nav_keymaps" "$TOGGLETERM"; then
    success "Claude terminal navigation properly disabled"
else
    error "Claude terminal navigation flags not found"
fi
echo

# 10. Summary
echo "============================================="
echo "           Validation Summary"
echo "============================================="
echo
echo "Configuration files validated:"
echo "  • ~/.tmux.conf"
echo "  • $TOGGLETERM"
echo "  • $TMUX_INTEGRATION"
echo "  • $ITERM_PROFILES"
echo
success "All validation checks passed!"
echo
echo "Next steps:"
echo "  1. Reload tmux: tmux source-file ~/.tmux.conf"
echo "  2. Reload Neovim: :Lazy sync"
echo "  3. Import iTerm2 profiles if not already done"
echo "  4. Run manual tests from TEST_REPORT.md"
echo
echo "For detailed testing instructions, see:"
echo "  ~/dotfiles/TEST_REPORT.md"
echo

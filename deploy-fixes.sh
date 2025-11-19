#!/bin/bash
# Quick deployment script for Four Waves keyboard navigation fixes
# This script deploys the new tmux configuration

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Four Waves Configuration Deployment${NC}"
echo -e "${BLUE}=============================================${NC}"
echo

# Check if new config exists
if [ ! -f ~/dotfiles/.tmux.conf ]; then
    echo -e "${RED}❌ ERROR: New tmux config not found at ~/dotfiles/.tmux.conf${NC}"
    exit 1
fi

# Check if old config exists
if [ ! -f ~/dotfiles/tmux/.tmux.conf ]; then
    echo -e "${RED}❌ ERROR: Target location ~/dotfiles/tmux/.tmux.conf not found${NC}"
    exit 1
fi

echo -e "${YELLOW}This will replace your current tmux configuration.${NC}"
echo
echo "Current config: ~/dotfiles/tmux/.tmux.conf (41 lines - OLD)"
echo "New config:     ~/dotfiles/.tmux.conf (245 lines - NEW)"
echo
echo "A backup will be created automatically."
echo

# Ask for confirmation
read -p "Do you want to proceed? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Step 1: Backup
echo -e "${BLUE}Step 1: Creating backup...${NC}"
BACKUP_FILE=~/dotfiles/tmux/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)
cp ~/dotfiles/tmux/.tmux.conf "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"
echo

# Step 2: Show diff preview
echo -e "${BLUE}Step 2: Configuration changes preview...${NC}"
echo "Lines in old config: $(wc -l < ~/dotfiles/tmux/.tmux.conf)"
echo "Lines in new config: $(wc -l < ~/dotfiles/.tmux.conf)"
echo
echo "New features being added:"
echo "  • Extended keyboard protocol (CSI u)"
echo "  • Seamless Neovim/tmux navigation"
echo "  • Modern terminal features (true color, focus events)"
echo "  • Plugin management (TPM)"
echo "  • Enhanced copy mode"
echo "  • Catppuccin theme"
echo

# Step 3: Deploy
echo -e "${BLUE}Step 3: Deploying new configuration...${NC}"
mv ~/dotfiles/.tmux.conf ~/dotfiles/tmux/.tmux.conf
echo -e "${GREEN}✅ New config deployed to ~/dotfiles/tmux/.tmux.conf${NC}"
echo

# Step 4: Verify
echo -e "${BLUE}Step 4: Verifying deployment...${NC}"
if grep -q "extended-keys" ~/dotfiles/tmux/.tmux.conf; then
    echo -e "${GREEN}✅ Extended keys configuration found${NC}"
else
    echo -e "${RED}❌ ERROR: Extended keys not found in deployed config!${NC}"
    echo "Rolling back..."
    cp "$BACKUP_FILE" ~/dotfiles/tmux/.tmux.conf
    exit 1
fi

if grep -q "bind-key -n 'C-h' if-shell" ~/dotfiles/tmux/.tmux.conf; then
    echo -e "${GREEN}✅ Seamless navigation bindings found${NC}"
else
    echo -e "${YELLOW}⚠️  Navigation bindings might be formatted differently${NC}"
fi

# Step 5: Test syntax
echo -e "${BLUE}Step 5: Testing configuration syntax...${NC}"
if tmux -f ~/dotfiles/tmux/.tmux.conf list-keys > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Configuration syntax is valid${NC}"
else
    echo -e "${RED}❌ ERROR: Configuration has syntax errors!${NC}"
    echo "Rolling back..."
    cp "$BACKUP_FILE" ~/dotfiles/tmux/.tmux.conf
    exit 1
fi
echo

# Step 6: Check if tmux is running
echo -e "${BLUE}Step 6: Checking tmux status...${NC}"
if tmux list-sessions > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  tmux is currently running${NC}"
    echo
    echo "To apply the changes, choose one:"
    echo "  1. Reload config: ${GREEN}tmux source-file ~/.tmux.conf${NC}"
    echo "  2. Restart tmux:  ${GREEN}tmux kill-server && tmux${NC} (closes all sessions)"
    echo
else
    echo -e "${GREEN}✅ No tmux sessions running - changes will apply on next start${NC}"
fi

# Summary
echo
echo -e "${BLUE}=============================================${NC}"
echo -e "${GREEN}        ✅ Deployment Complete!${NC}"
echo -e "${BLUE}=============================================${NC}"
echo
echo "What was deployed:"
echo "  ✅ New tmux configuration (245 lines)"
echo "  ✅ Extended keyboard protocol (CSI u)"
echo "  ✅ Seamless navigation with Neovim"
echo "  ✅ Modern terminal features"
echo
echo "Backup saved at:"
echo "  ${BACKUP_FILE}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Reload tmux: ${GREEN}tmux source-file ~/.tmux.conf${NC}"
echo "     OR restart: ${GREEN}tmux kill-server && tmux${NC}"
echo
echo "  2. Reload Neovim plugins: ${GREEN}:Lazy sync${NC}"
echo
echo "  3. Import iTerm2 profiles (if not done):"
echo "     iTerm2 → Preferences → Profiles → Import JSON"
echo "     File: ~/dotfiles/mac/iterm-profiles.json"
echo
echo "  4. Run validation: ${GREEN}./validate-config.sh${NC}"
echo
echo "  5. Test navigation: Press Ctrl+h/j/k/l in tmux with Neovim"
echo
echo "For detailed testing instructions, see:"
echo "  ${GREEN}~/dotfiles/TEST_REPORT.md${NC}"
echo
echo "If something goes wrong, restore backup:"
echo "  ${RED}cp $BACKUP_FILE ~/dotfiles/tmux/.tmux.conf${NC}"
echo "  ${RED}tmux source-file ~/.tmux.conf${NC}"
echo

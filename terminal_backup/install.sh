#!/bin/bash

# Terminal Setup Installer for Nobara 42 (Fedora-based)
# This script restores terminal configuration from backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Terminal Setup Installer for Nobara 42 ===${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 1. System Update
echo -e "${GREEN}>>> Updating system...${NC}"
sudo dnf update -y
print_status "System updated"

# 2. Install Core Tools
echo -e "${GREEN}>>> Installing core tools...${NC}"
sudo dnf install -y zsh git curl wget util-linux-user
print_status "Core tools installed (zsh, git, curl, wget, util-linux-user)"

# 3. Install Terminal Tools
echo -e "${GREEN}>>> Installing terminal tools...${NC}"

# Starship
if sudo dnf install -y starship 2>/dev/null; then
    print_status "Starship installed via dnf"
else
    print_warning "Starship not in repos, installing via official script..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    print_status "Starship installed via official script"
fi

# Atuin
if sudo dnf install -y atuin 2>/dev/null; then
    print_status "Atuin installed via dnf"
else
    print_warning "Atuin not in repos, installing via official script..."
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
    print_status "Atuin installed via official script"
fi

# Fastfetch
sudo dnf install -y fastfetch
print_status "Fastfetch installed"

# 4. Install Zsh Plugins
echo -e "${GREEN}>>> Installing Zsh plugins...${NC}"
sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting
print_status "zsh-autosuggestions and zsh-syntax-highlighting installed"

# zsh-autocomplete - check if available in repos or clone from GitHub
ZSH_AUTOCOMPLETE_SYSTEM="/usr/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
ZSH_AUTOCOMPLETE_LOCAL="$HOME/.local/share/zsh/plugins/zsh-autocomplete"

if sudo dnf install -y zsh-autocomplete 2>/dev/null && [ -f "$ZSH_AUTOCOMPLETE_SYSTEM" ]; then
    print_status "zsh-autocomplete installed via dnf"
else
    print_warning "zsh-autocomplete not in repos, cloning from GitHub..."
    mkdir -p "$HOME/.local/share/zsh/plugins"
    if [ -d "$ZSH_AUTOCOMPLETE_LOCAL" ]; then
        rm -rf "$ZSH_AUTOCOMPLETE_LOCAL"
    fi
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_AUTOCOMPLETE_LOCAL"
    print_status "zsh-autocomplete cloned to $ZSH_AUTOCOMPLETE_LOCAL"
fi

# 5. Restore Config Files
echo -e "${GREEN}>>> Restoring configuration files...${NC}"

# .zshrc
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
    cp "$SCRIPT_DIR/.zshrc" ~/
    
    # Update zsh-autocomplete path if using local installation
    if [ ! -f "$ZSH_AUTOCOMPLETE_SYSTEM" ] && [ -d "$ZSH_AUTOCOMPLETE_LOCAL" ]; then
        sed -i "s|source /usr/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh|source $ZSH_AUTOCOMPLETE_LOCAL/zsh-autocomplete.plugin.zsh|g" ~/.zshrc
        print_status ".zshrc copied and updated with local zsh-autocomplete path"
    else
        print_status ".zshrc copied"
    fi
fi

# .bashrc
if [ -f "$SCRIPT_DIR/.bashrc" ]; then
    cp "$SCRIPT_DIR/.bashrc" ~/
    print_status ".bashrc copied"
fi

# Create .config directory if it doesn't exist
mkdir -p ~/.config

# starship.toml
if [ -f "$SCRIPT_DIR/.config/starship/starship.toml" ]; then
    cp "$SCRIPT_DIR/.config/starship/starship.toml" ~/.config/
    print_status "starship.toml copied"
elif [ -f "$SCRIPT_DIR/.config/starship.toml" ]; then
    cp "$SCRIPT_DIR/.config/starship.toml" ~/.config/
    print_status "starship.toml copied"
fi

# atuin config
if [ -d "$SCRIPT_DIR/.config/atuin" ]; then
    mkdir -p ~/.config/atuin
    cp -r "$SCRIPT_DIR/.config/atuin/"* ~/.config/atuin/
    print_status "atuin config copied"
fi

# fastfetch config
if [ -d "$SCRIPT_DIR/.config/fastfetch" ]; then
    mkdir -p ~/.config/fastfetch
    cp -r "$SCRIPT_DIR/.config/fastfetch/"* ~/.config/fastfetch/
    print_status "fastfetch config copied"
fi

# fish config
if [ -d "$SCRIPT_DIR/.config/fish" ]; then
    mkdir -p ~/.config/fish
    cp -r "$SCRIPT_DIR/.config/fish/"* ~/.config/fish/
    print_status "fish config copied"
fi

# 6. Restore Fonts
echo -e "${GREEN}>>> Installing fonts...${NC}"
if [ -d "$SCRIPT_DIR/fonts" ]; then
    mkdir -p ~/.local/share/fonts
    cp "$SCRIPT_DIR/fonts/"*.ttf ~/.local/share/fonts/ 2>/dev/null || true
    fc-cache -fv
    print_status "Fonts installed and cache updated"
else
    print_warning "No fonts directory found in backup"
fi

# 7. Set Default Shell to Zsh
echo -e "${GREEN}>>> Setting default shell to zsh...${NC}"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    print_status "Default shell changed to zsh (will take effect on next login)"
else
    print_status "Zsh is already the default shell"
fi

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Please log out and log back in for the shell change to take effect."
echo "Then open a new terminal to enjoy your restored setup!"
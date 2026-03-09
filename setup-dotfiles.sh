#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════
# Exegol Dotfiles Setup Script
# ═══════════════════════════════════════════════════════════════════
# Syncs configs from this repo to ~/.exegol/my-resources/setup/
# so they're available in all Exegol containers.
#
# Run on your HOST machine after cloning this repo.
# ═══════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"

EXEGOL_RESOURCES="$HOME/.exegol/my-resources"
EXEGOL_SETUP="$EXEGOL_RESOURCES/setup"
EXEGOL_BIN="$EXEGOL_RESOURCES/bin"

echo "=========================================="
echo "  Exegol Dotfiles Setup"
echo "=========================================="
echo ""

# ───────────────────────────────────────────────────────────────────
# Pre-flight checks
# ───────────────────────────────────────────────────────────────────
if [ ! -d "$CONFIGS_DIR" ]; then
    echo -e "${RED}[-]${NC} Configs directory not found: $CONFIGS_DIR"
    exit 1
fi

sudo mkdir -p "$EXEGOL_SETUP" "$EXEGOL_BIN"
sudo chown -R "$USER:$USER" "$EXEGOL_RESOURCES" 2>/dev/null || true

echo -e "${GREEN}[+]${NC} Deploying to $EXEGOL_RESOURCES"

# ───────────────────────────────────────────────────────────────────
# Core setup scripts
# ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}[*]${NC} Core setup scripts..."

# load_user_setup.sh - master init script
if [ -f "$CONFIGS_DIR/load_user_setup.sh" ]; then
    cp "$CONFIGS_DIR/load_user_setup.sh" "$EXEGOL_SETUP/load_user_setup.sh"
    chmod +x "$EXEGOL_SETUP/load_user_setup.sh"
    echo -e "${GREEN}[+]${NC} load_user_setup.sh"
fi

# install-tools.sh - CLI tool installer (runs inside container)
if [ -f "$SCRIPT_DIR/install-tools.sh" ]; then
    cp "$SCRIPT_DIR/install-tools.sh" "$EXEGOL_SETUP/install-tools.sh"
    chmod +x "$EXEGOL_SETUP/install-tools.sh"
    echo -e "${GREEN}[+]${NC} install-tools.sh"
fi

# ───────────────────────────────────────────────────────────────────
# Shell config (zsh)
# ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}[*]${NC} Shell configuration..."

if [ -f "$CONFIGS_DIR/zshrc" ]; then
    mkdir -p "$EXEGOL_SETUP/zsh"
    cp "$CONFIGS_DIR/zshrc" "$EXEGOL_SETUP/zsh/zshrc"
    echo -e "${GREEN}[+]${NC} zsh/zshrc"
fi

# ───────────────────────────────────────────────────────────────────
# Starship prompt
# ───────────────────────────────────────────────────────────────────
if [ -f "$CONFIGS_DIR/starship.toml" ]; then
    mkdir -p "$EXEGOL_SETUP/starship"
    cp "$CONFIGS_DIR/starship.toml" "$EXEGOL_SETUP/starship/starship.toml"
    echo -e "${GREEN}[+]${NC} starship/starship.toml"
fi

# ───────────────────────────────────────────────────────────────────
# Zellij terminal multiplexer
# ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}[*]${NC} Zellij configuration..."

if [ -d "$CONFIGS_DIR/zellij" ]; then
    mkdir -p "$EXEGOL_SETUP/zellij"
    cp -r "$CONFIGS_DIR/zellij/"* "$EXEGOL_SETUP/zellij/"
    chmod +x "$EXEGOL_SETUP/zellij/scripts/"*.sh 2>/dev/null || true
    echo -e "${GREEN}[+]${NC} zellij/ (layout, plugins, scripts)"
fi

# ───────────────────────────────────────────────────────────────────
# Yazi file manager
# ───────────────────────────────────────────────────────────────────
if [ -d "$CONFIGS_DIR/yazi" ]; then
    mkdir -p "$EXEGOL_SETUP/yazi/flavors"
    cp "$CONFIGS_DIR/yazi/theme.toml" "$EXEGOL_SETUP/yazi/theme.toml"
    cp -r "$CONFIGS_DIR/yazi/flavors/"* "$EXEGOL_SETUP/yazi/flavors/"
    echo -e "${GREEN}[+]${NC} yazi/ (Tokyo Night theme)"
fi

# ───────────────────────────────────────────────────────────────────
# Persistence scripts (BloodHound, Firefox, Sliver)
# ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}[*]${NC} Persistence scripts..."

if [ -f "$CONFIGS_DIR/bloodhound/setup-bloodhound.sh" ]; then
    mkdir -p "$EXEGOL_SETUP/bloodhound/data"
    cp "$CONFIGS_DIR/bloodhound/setup-bloodhound.sh" "$EXEGOL_SETUP/bloodhound/setup-bloodhound.sh"
    chmod +x "$EXEGOL_SETUP/bloodhound/setup-bloodhound.sh"
    echo -e "${GREEN}[+]${NC} bloodhound/setup-bloodhound.sh"
fi

if [ -f "$CONFIGS_DIR/firefox/setup-firefox.sh" ]; then
    mkdir -p "$EXEGOL_SETUP/firefox/profile"
    cp "$CONFIGS_DIR/firefox/setup-firefox.sh" "$EXEGOL_SETUP/firefox/setup-firefox.sh"
    chmod +x "$EXEGOL_SETUP/firefox/setup-firefox.sh"
    echo -e "${GREEN}[+]${NC} firefox/setup-firefox.sh"
fi

if [ -f "$CONFIGS_DIR/sliver/setup-sliver.sh" ]; then
    mkdir -p "$EXEGOL_SETUP/sliver"
    cp "$CONFIGS_DIR/sliver/setup-sliver.sh" "$EXEGOL_SETUP/sliver/setup-sliver.sh"
    chmod +x "$EXEGOL_SETUP/sliver/setup-sliver.sh"
    echo -e "${GREEN}[+]${NC} sliver/setup-sliver.sh"
fi

# ───────────────────────────────────────────────────────────────────
# Helper bin scripts
# ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}[*]${NC} Helper scripts..."

if [ -d "$CONFIGS_DIR/bin" ]; then
    for script in "$CONFIGS_DIR/bin/"*; do
        [ -f "$script" ] || continue
        cp "$script" "$EXEGOL_BIN/$(basename "$script")"
        chmod +x "$EXEGOL_BIN/$(basename "$script")"
        echo -e "${GREEN}[+]${NC} bin/$(basename "$script")"
    done
fi

# ───────────────────────────────────────────────────────────────────
# Done
# ───────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo -e "${GREEN}[+]${NC} Dotfiles synced!"
echo "=========================================="
echo ""
echo "Deployed to: $EXEGOL_RESOURCES"
echo ""
echo "Start a new Exegol container to activate:"
echo -e "  ${YELLOW}exegol start mybox full${NC}"
echo ""
echo "Everything runs automatically on first container start."
echo ""

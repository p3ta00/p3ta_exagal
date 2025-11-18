#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# Exegol User Setup Script - Optimized with Precompiled Binaries
# ═══════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BIN_DIR="/opt/my-resources/bin"
SETUP_DIR="/opt/my-resources/setup"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Loading Custom User Setup (Fast Mode)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"

# Create BIN_DIR with proper permissions for all users
mkdir -p "$BIN_DIR"
chmod 755 "$BIN_DIR"  # Ensure everyone can access and execute binaries

# ───────────────────────────────────────────────────────────────────
# Install Starship Prompt (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/starship" ]; then
    echo -e "${BLUE}[*]${NC} Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir="$BIN_DIR"
    echo -e "${GREEN}[✓]${NC} Starship installed"
fi

if [ -f "$SETUP_DIR/starship/starship.toml" ] && [ ! -f /root/.config/starship.toml ]; then
    mkdir -p /root/.config
    cp "$SETUP_DIR/starship/starship.toml" /root/.config/starship.toml
    echo -e "${GREEN}[✓]${NC} Starship config installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Zellij (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/zellij" ]; then
    echo -e "${BLUE}[*]${NC} Installing Zellij..."
    curl -sL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar -xz -C "$BIN_DIR"
    chmod +x "$BIN_DIR/zellij"
    echo -e "${GREEN}[✓]${NC} Zellij installed"
fi

if [ -d "$SETUP_DIR/zellij" ] && [ ! -d /root/.config/zellij ]; then
    mkdir -p /root/.config/zellij
    cp -r "$SETUP_DIR/zellij/"* /root/.config/zellij/
    echo -e "${GREEN}[✓]${NC} Zellij config installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Eza (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/eza" ]; then
    echo -e "${BLUE}[*]${NC} Installing Eza..."
    EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz" | tar -xz -C "$BIN_DIR"
    chmod +x "$BIN_DIR/eza"
    echo -e "${GREEN}[✓]${NC} Eza installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Zoxide (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/zoxide" ]; then
    echo -e "${BLUE}[*]${NC} Installing Zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN_DIR"
    echo -e "${GREEN}[✓]${NC} Zoxide installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Bat (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/bat" ] && ! command -v bat &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing Bat..."
    BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/sharkdp/bat/releases/latest/download/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat" "$BIN_DIR/bat"
    rm -rf "/tmp/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/bat"
    echo -e "${GREEN}[✓]${NC} Bat installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Fd (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/fd" ] && ! command -v fd &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing Fd..."
    FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/sharkdp/fd/releases/latest/download/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" "$BIN_DIR/fd"
    rm -rf "/tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/fd"
    echo -e "${GREEN}[✓]${NC} Fd installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Ripgrep (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/rg" ] && ! command -v rg &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing Ripgrep..."
    RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -sL "https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$BIN_DIR/rg"
    rm -rf "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/rg"
    echo -e "${GREEN}[✓]${NC} Ripgrep installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Delta (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/delta" ]; then
    echo -e "${BLUE}[*]${NC} Installing Git Delta..."
    DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -sL "https://github.com/dandavison/delta/releases/latest/download/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta" "$BIN_DIR/delta"
    rm -rf "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/delta"

    # Configure git to use delta
    git config --global core.pager "delta" 2>/dev/null || true
    git config --global interactive.diffFilter "delta --color-only" 2>/dev/null || true
    git config --global delta.navigate true 2>/dev/null || true
    git config --global delta.side-by-side true 2>/dev/null || true
    git config --global delta.line-numbers true 2>/dev/null || true
    echo -e "${GREEN}[✓]${NC} Git Delta installed and configured"
fi

# ───────────────────────────────────────────────────────────────────
# Install Yazi (precompiled)
# ───────────────────────────────────────────────────────────────────

if [ ! -f "$BIN_DIR/yazi" ]; then
    echo -e "${BLUE}[*]${NC} Installing Yazi..."
    YAZI_VERSION=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip" -o /tmp/yazi.zip
    unzip -q /tmp/yazi.zip -d /tmp
    mv "/tmp/yazi-x86_64-unknown-linux-musl/yazi" "$BIN_DIR/yazi"
    rm -rf /tmp/yazi.zip "/tmp/yazi-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/yazi"
    echo -e "${GREEN}[✓]${NC} Yazi installed"
fi

if [ -d "$SETUP_DIR/yazi" ] && [ ! -d /root/.config/yazi ]; then
    mkdir -p /root/.config/yazi
    cp -r "$SETUP_DIR/yazi/"* /root/.config/yazi/
    echo -e "${GREEN}[✓]${NC} Yazi config installed"
fi

# ───────────────────────────────────────────────────────────────────
# Copy Custom Tools to /opt/resources
# ───────────────────────────────────────────────────────────────────

#if [ -f "$SETUP_DIR/copy_tools.sh" ]; then
#   echo -e "${BLUE}[*]${NC} Copying custom tools to /opt/resources..."
#    bash "$SETUP_DIR/copy_tools.sh"
#fi

# ───────────────────────────────────────────────────────────────────
# Setup Impacket Prefix (Kali-style)
# ───────────────────────────────────────────────────────────────────

if [ -f "$SETUP_DIR/setup_impacket_prefix.sh" ]; then
    bash "$SETUP_DIR/setup_impacket_prefix.sh"
fi

# ───────────────────────────────────────────────────────────────────
# Fix Permissions on All Binaries
# ───────────────────────────────────────────────────────────────────

# Ensure all binaries are executable by everyone
if [ -d "$BIN_DIR" ]; then
    echo -e "${BLUE}[*]${NC} Fixing permissions on all binaries..."
    chmod 755 "$BIN_DIR"
    chmod +x "$BIN_DIR"/* 2>/dev/null || true
    echo -e "${GREEN}[✓]${NC} Permissions fixed"
fi

echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete! Tools installed in $BIN_DIR${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"

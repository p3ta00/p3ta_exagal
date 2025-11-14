#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════
# Impacket Prefix Setup Script
# ═══════════════════════════════════════════════════════════════════
# Creates impacket- prefixed symlinks for all impacket tools
# Similar to Kali Linux behavior

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Paths
IMPACKET_BIN="/root/.local/share/pipx/venvs/impacket/bin"
TARGET_DIR="/usr/local/bin"

echo -e "${BLUE}[*]${NC} Setting up impacket- prefix for tools..."

# Check if impacket is installed
if [ ! -d "$IMPACKET_BIN" ]; then
    echo -e "${YELLOW}[!]${NC} Impacket not found at $IMPACKET_BIN"
    exit 0
fi

# Create symlinks for all impacket tools
tool_count=0

for tool in "$IMPACKET_BIN"/*.py; do
    [ -f "$tool" ] || continue

    # Get the basename without path
    tool_name=$(basename "$tool")

    # Remove .py extension for the main name
    base_name="${tool_name%.py}"

    # Create symlink with impacket- prefix (without .py)
    target_link="$TARGET_DIR/impacket-$base_name"

    if [ ! -e "$target_link" ]; then
        ln -sf "$tool" "$target_link" 2>/dev/null || true
        ((tool_count++))
    fi

    # Also create impacket- prefix with .py extension for compatibility
    target_link_py="$TARGET_DIR/impacket-$tool_name"

    if [ ! -e "$target_link_py" ]; then
        ln -sf "$tool" "$target_link_py" 2>/dev/null || true
    fi

done

if [ $tool_count -gt 0 ]; then
    echo -e "${GREEN}[✓]${NC} Created impacket- prefix for $tool_count tools"
    echo -e "${GREEN}[✓]${NC} Example: impacket-smbexec, impacket-secretsdump, impacket-GetNPUsers"
else
    echo -e "${BLUE}[*]${NC} Impacket prefix already configured"
fi

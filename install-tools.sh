#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BIN_DIR="/opt/my-resources/bin"
SETUP_DIR="/opt/my-resources/setup"
mkdir -p "$BIN_DIR"

install_tool() {
    local name="$1" url="$2" extract_cmd="$3"
    if [ -f "$BIN_DIR/$name" ]; then
        echo -e "${YELLOW}[~]${NC} $name already installed"
        return
    fi
    echo -e "${BLUE}[*]${NC} Installing $name..."
    eval "$extract_cmd"
    chmod +x "$BIN_DIR/$name"
    echo -e "${GREEN}[+]${NC} $name installed"
}

# Starship
if [ ! -f "$BIN_DIR/starship" ]; then
    echo -e "${BLUE}[*]${NC} Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir="$BIN_DIR"
else
    echo -e "${YELLOW}[~]${NC} Starship already installed"
fi

# Zellij
install_tool "zellij" "" \
    "curl -sL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar -xz -C $BIN_DIR"

# eza
install_tool "eza" "" \
    "curl -sL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-musl.tar.gz | tar -xz -C $BIN_DIR"

# bat
if [ ! -f "$BIN_DIR/bat" ]; then
    echo -e "${BLUE}[*]${NC} Installing bat..."
    BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/sharkdp/bat/releases/latest/download/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat" "$BIN_DIR/"
    rm -rf "/tmp/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/bat"
    echo -e "${GREEN}[+]${NC} bat installed"
else
    echo -e "${YELLOW}[~]${NC} bat already installed"
fi

# fd
if [ ! -f "$BIN_DIR/fd" ]; then
    echo -e "${BLUE}[*]${NC} Installing fd..."
    FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/sharkdp/fd/releases/latest/download/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" "$BIN_DIR/"
    rm -rf "/tmp/fd-v${FD_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/fd"
    echo -e "${GREEN}[+]${NC} fd installed"
else
    echo -e "${YELLOW}[~]${NC} fd already installed"
fi

# zoxide
if [ ! -f "$BIN_DIR/zoxide" ]; then
    echo -e "${BLUE}[*]${NC} Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir "$BIN_DIR"
else
    echo -e "${YELLOW}[~]${NC} zoxide already installed"
fi

# delta
if [ ! -f "$BIN_DIR/delta" ]; then
    echo -e "${BLUE}[*]${NC} Installing delta..."
    DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -sL "https://github.com/dandavison/delta/releases/latest/download/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta" "$BIN_DIR/"
    rm -rf "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/delta"
    echo -e "${GREEN}[+]${NC} delta installed"
else
    echo -e "${YELLOW}[~]${NC} delta already installed"
fi

# fzf
if [ ! -f "$BIN_DIR/fzf" ]; then
    echo -e "${BLUE}[*]${NC} Installing fzf..."
    FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
    curl -sL "https://github.com/junegunn/fzf/releases/latest/download/fzf-${FZF_VERSION}-linux_amd64.tar.gz" | tar -xz -C "$BIN_DIR"
    chmod +x "$BIN_DIR/fzf"
    echo -e "${GREEN}[+]${NC} fzf installed"
else
    echo -e "${YELLOW}[~]${NC} fzf already installed"
fi

# ripgrep
if [ ! -f "$BIN_DIR/rg" ]; then
    echo -e "${BLUE}[*]${NC} Installing ripgrep..."
    RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -sL "https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C /tmp
    mv "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$BIN_DIR/"
    rm -rf "/tmp/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl"
    chmod +x "$BIN_DIR/rg"
    echo -e "${GREEN}[+]${NC} ripgrep installed"
else
    echo -e "${YELLOW}[~]${NC} ripgrep already installed"
fi

# yazi
if [ ! -f "$BIN_DIR/yazi" ]; then
    echo -e "${BLUE}[*]${NC} Installing yazi..."
    curl -sL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip" -o /tmp/yazi.zip
    unzip -qo /tmp/yazi.zip -d /tmp/yazi-extract
    mv /tmp/yazi-extract/yazi-x86_64-unknown-linux-musl/yazi "$BIN_DIR/"
    mv /tmp/yazi-extract/yazi-x86_64-unknown-linux-musl/ya "$BIN_DIR/" 2>/dev/null || true
    rm -rf /tmp/yazi.zip /tmp/yazi-extract
    chmod +x "$BIN_DIR/yazi"
    echo -e "${GREEN}[+]${NC} yazi installed"
else
    echo -e "${YELLOW}[~]${NC} yazi already installed"
fi

# btop
if [ ! -f "$BIN_DIR/btop" ]; then
    echo -e "${BLUE}[*]${NC} Installing btop..."
    BTOP_VERSION=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -sL "https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz" | tar -xj -C /tmp
    mv /tmp/btop/bin/btop "$BIN_DIR/"
    rm -rf /tmp/btop
    chmod +x "$BIN_DIR/btop"
    echo -e "${GREEN}[+]${NC} btop installed"
else
    echo -e "${YELLOW}[~]${NC} btop already installed"
fi

# ───────────────────────────────────────────────────────────────────
# Configure tools inside container
# ───────────────────────────────────────────────────────────────────

# Starship config
if [ -f "$SETUP_DIR/starship/starship.toml" ]; then
    mkdir -p /root/.config
    cp "$SETUP_DIR/starship/starship.toml" /root/.config/starship.toml
    echo -e "${GREEN}[+]${NC} Starship config installed"
fi

# Zellij config
if [ -d "$SETUP_DIR/zellij" ]; then
    mkdir -p /root/.config
    rm -rf /root/.config/zellij
    ln -sf /opt/my-resources/setup/zellij /root/.config/zellij
    echo -e "${GREEN}[+]${NC} Zellij config linked"
fi

# Bat config
mkdir -p /root/.config/bat
cat > /root/.config/bat/config << 'BATCFG'
--paging=never
--style=plain
--theme=Dracula
BATCFG
echo -e "${GREEN}[+]${NC} bat config installed"

# Disable Exegol's prompt hook (let Starship handle it)
sed -i 's/add-zsh-hook precmd update_prompt/#add-zsh-hook precmd update_prompt/g' /root/.zshrc 2>/dev/null || true

# Remove zsh-z plugin (conflicts with zoxide)
sed -i 's/zsh-z //' /root/.zshrc 2>/dev/null || true

# Git delta config
git config --global core.pager "delta" 2>/dev/null || true
git config --global interactive.diffFilter "delta --color-only" 2>/dev/null || true
git config --global delta.navigate true 2>/dev/null || true
git config --global delta.line-numbers true 2>/dev/null || true

# Go
if [ ! -f "$BIN_DIR/go/bin/go" ]; then
    echo -e "${BLUE}[*]${NC} Installing Go..."
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
    curl -sL "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" | tar -xz -C "$BIN_DIR"
    ln -sf "$BIN_DIR/go/bin/go" "$BIN_DIR/go-bin"
    ln -sf "$BIN_DIR/go/bin/gofmt" "$BIN_DIR/gofmt"
    echo -e "${GREEN}[+]${NC} Go installed"
else
    echo -e "${YELLOW}[~]${NC} Go already installed"
fi

chmod +x "$BIN_DIR"/* 2>/dev/null || true

echo -e "${GREEN}[✓]${NC} All tools installed to $BIN_DIR"

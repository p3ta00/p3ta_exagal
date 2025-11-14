#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════
# Exegol Dotfiles Setup Script
# ═══════════════════════════════════════════════════════════════════
# This script syncs your personal dotfiles to Exegol's my-resources
# directory so they're available in all Exegol containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source directories (your dotfiles)
CACHYOS_SETUP="/home/p3ta/tools/dev/cachyos-setup"
DOTFILES_DIR="$CACHYOS_SETUP/dotfiles"
CONFIG_DIR="$CACHYOS_SETUP/config"

# Destination (Exegol my-resources)
EXEGOL_RESOURCES="$HOME/.exegol/my-resources"
EXEGOL_SETUP="$EXEGOL_RESOURCES/setup"
EXEGOL_BIN="$EXEGOL_RESOURCES/bin"

# ───────────────────────────────────────────────────────────────────
# Helper Functions
# ───────────────────────────────────────────────────────────────────

print_header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. It will use sudo when needed."
    exit 1
fi

# ───────────────────────────────────────────────────────────────────
# Pre-flight Checks
# ───────────────────────────────────────────────────────────────────

check_requirements() {
    print_header "Checking Requirements"

    # Check if Exegol is installed
    if ! command -v exegol &> /dev/null; then
        print_error "Exegol is not installed. Please run install.sh first."
        exit 1
    fi

    # Check if source directories exist
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi

    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "Config directory not found: $CONFIG_DIR"
        exit 1
    fi

    # Check if my-resources exists
    if [ ! -d "$EXEGOL_RESOURCES" ]; then
        print_warning "Exegol my-resources directory not found. Creating it..."
        sudo mkdir -p "$EXEGOL_SETUP"
        sudo mkdir -p "$EXEGOL_BIN"
    fi

    print_success "All requirements met"
}

# ───────────────────────────────────────────────────────────────────
# Setup Zsh Configuration
# ───────────────────────────────────────────────────────────────────

setup_zsh() {
    print_header "Setting up Zsh Configuration"

    sudo mkdir -p "$EXEGOL_SETUP/zsh"

    # Copy zshrc (will be placed at /root/.zshrc in container)
    print_info "Copying .zshrc..."
    sudo cp "$DOTFILES_DIR/.zshrc" "$EXEGOL_SETUP/zsh/.zshrc"

    # Copy .zshenv if exists
    if [ -f "$DOTFILES_DIR/.zshenv" ]; then
        print_info "Copying .zshenv..."
        sudo cp "$DOTFILES_DIR/.zshenv" "$EXEGOL_SETUP/zsh/.zshenv"
    fi

    # Copy .zsh directory if exists
    if [ -d "$DOTFILES_DIR/.zsh" ]; then
        print_info "Copying .zsh directory..."
        sudo cp -r "$DOTFILES_DIR/.zsh" "$EXEGOL_SETUP/zsh/"
    fi

    print_success "Zsh configuration synced"
}

# ───────────────────────────────────────────────────────────────────
# Setup Neovim Configuration
# ───────────────────────────────────────────────────────────────────

setup_neovim() {
    print_header "Setting up Neovim Configuration"

    # Check if user has nvim config
    if [ -d "$HOME/.config/nvim" ]; then
        print_info "Copying Neovim configuration..."
        sudo mkdir -p "$EXEGOL_SETUP/nvim"
        sudo cp -r "$HOME/.config/nvim/"* "$EXEGOL_SETUP/nvim/"
        print_success "Neovim configuration synced"
    else
        print_warning "No Neovim configuration found at ~/.config/nvim"
    fi
}

# ───────────────────────────────────────────────────────────────────
# Setup Starship Configuration
# ───────────────────────────────────────────────────────────────────

setup_starship() {
    print_header "Setting up Starship Configuration"

    # Create starship config directory in my-resources
    print_info "Copying starship.toml..."
    sudo mkdir -p "$EXEGOL_SETUP/starship"
    sudo cp "$CONFIG_DIR/starship.toml" "$EXEGOL_SETUP/starship/starship.toml"

    print_success "Starship configuration synced"
}

# ───────────────────────────────────────────────────────────────────
# Setup Zellij Configuration
# ───────────────────────────────────────────────────────────────────

setup_zellij() {
    print_header "Setting up Zellij Configuration"

    print_info "Copying Zellij configuration..."
    sudo mkdir -p "$EXEGOL_SETUP/zellij"
    sudo cp -r "$CONFIG_DIR/zellij/"* "$EXEGOL_SETUP/zellij/"

    print_success "Zellij configuration synced"
}

# ───────────────────────────────────────────────────────────────────
# Setup Yazi Configuration
# ───────────────────────────────────────────────────────────────────

setup_yazi() {
    print_header "Setting up Yazi Configuration"

    print_info "Copying Yazi configuration..."
    sudo mkdir -p "$EXEGOL_SETUP/yazi"
    sudo cp -r "$CONFIG_DIR/yazi/"* "$EXEGOL_SETUP/yazi/"

    print_success "Yazi configuration synced"
}

# ───────────────────────────────────────────────────────────────────
# Create load_user_setup.sh Script
# ───────────────────────────────────────────────────────────────────

create_load_user_setup() {
    print_header "Creating load_user_setup.sh Script"

    print_info "Generating load_user_setup.sh..."

    sudo tee "$EXEGOL_SETUP/load_user_setup.sh" > /dev/null << 'EOF'
#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# Exegol User Setup Script
# ═══════════════════════════════════════════════════════════════════
# This script runs on first container startup to install custom tools

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Loading Custom User Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"

# ───────────────────────────────────────────────────────────────────
# Install Oh-My-Zsh and Plugins
# ───────────────────────────────────────────────────────────────────

if [ ! -d "/root/.oh-my-zsh" ]; then
    echo -e "${BLUE}[*]${NC} Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    echo -e "${BLUE}[*]${NC} Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

    echo -e "${BLUE}[*]${NC} Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions

    echo -e "${GREEN}[✓]${NC} Oh-My-Zsh and plugins installed"
else
    echo -e "${YELLOW}[!]${NC} Oh-My-Zsh already installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Starship Prompt (precompiled binary)
# ───────────────────────────────────────────────────────────────────

if ! command -v starship &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo -e "${GREEN}[✓]${NC} Starship installed"
else
    echo -e "${YELLOW}[!]${NC} Starship already installed"
fi

# Copy starship config
if [ -f "/opt/my-resources/setup/starship/starship.toml" ]; then
    mkdir -p /root/.config
    cp /opt/my-resources/setup/starship/starship.toml /root/.config/starship.toml
    echo -e "${GREEN}[✓]${NC} Starship config installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Zellij Terminal Multiplexer (precompiled binary)
# ───────────────────────────────────────────────────────────────────

if ! command -v zellij &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing Zellij..."
    curl -Lo /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
    tar -xzf /tmp/zellij.tar.gz -C /tmp/
    mkdir -p /root/.cargo/bin
    mv /tmp/zellij /root/.cargo/bin/zellij
    chmod +x /root/.cargo/bin/zellij
    rm /tmp/zellij.tar.gz
    echo -e "${GREEN}[✓]${NC} Zellij installed"
else
    echo -e "${YELLOW}[!]${NC} Zellij already installed"
fi

# Copy zellij config
if [ -d "/opt/my-resources/setup/zellij" ]; then
    mkdir -p /root/.config/zellij
    cp -r /opt/my-resources/setup/zellij/* /root/.config/zellij/
    echo -e "${GREEN}[✓]${NC} Zellij config installed"
fi

# ───────────────────────────────────────────────────────────────────
# Install Rust (needed for remaining cargo tools)
# ───────────────────────────────────────────────────────────────────

if ! command -v cargo &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing Rust and Cargo..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo -e "${GREEN}[✓]${NC} Rust installed"
else
    echo -e "${YELLOW}[!]${NC} Rust already installed"
fi

# Make sure cargo is in PATH
export PATH="$HOME/.cargo/bin:$PATH"

# ───────────────────────────────────────────────────────────────────
# Install Additional Modern CLI Tools
# ───────────────────────────────────────────────────────────────────

echo -e "${BLUE}[*]${NC} Installing additional CLI tools..."

# Zoxide (better cd)
if ! command -v zoxide &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing zoxide..."
    cargo install zoxide --quiet 2>&1 | grep -v "Compiling\|Downloading" || true
fi

# Eza (better ls)
if ! command -v eza &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing eza..."
    cargo install eza --quiet 2>&1 | grep -v "Compiling\|Downloading" || true
fi

# Bat (better cat) - check if not already in Exegol
if ! command -v bat &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing bat..."
    cargo install bat --quiet 2>&1 | grep -v "Compiling\|Downloading" || true
fi

# Fd (better find)
if ! command -v fd &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing fd..."
    cargo install fd-find --quiet 2>&1 | grep -v "Compiling\|Downloading" || true
fi

# Ripgrep (better grep) - check if not already in Exegol
if ! command -v rg &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing ripgrep..."
    cargo install ripgrep --quiet 2>&1 | grep -v "Compiling\|Downloading" || true
fi

# Delta (better git diff)
if ! command -v delta &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Installing git-delta..."
    cargo install git-delta --quiet 2>&1 | grep -v "Compiling\|Downloading" || true
fi

echo -e "${GREEN}[✓]${NC} Additional CLI tools installed"

# ───────────────────────────────────────────────────────────────────
# Configure Git with Delta
# ───────────────────────────────────────────────────────────────────

if command -v delta &> /dev/null; then
    echo -e "${BLUE}[*]${NC} Configuring git delta..."
    git config --global core.pager "delta" 2>/dev/null || true
    git config --global interactive.diffFilter "delta --color-only" 2>/dev/null || true
    git config --global delta.navigate true 2>/dev/null || true
    git config --global delta.side-by-side true 2>/dev/null || true
    git config --global delta.line-numbers true 2>/dev/null || true
    echo -e "${GREEN}[✓]${NC} Git delta configured"
fi

# ───────────────────────────────────────────────────────────────────
# Final Message
# ───────────────────────────────────────────────────────────────────

echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Custom User Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Your shell environment is now configured with:${NC}"
echo "  • Oh-My-Zsh with syntax highlighting and autosuggestions"
echo "  • Starship prompt (Catppuccin Mocha theme)"
echo "  • Zellij terminal multiplexer (Dracula theme)"
echo "  • Zoxide, Eza, Bat, Fd, Ripgrep, Delta"
echo "  • Neovim with your custom config"
echo ""
EOF

    sudo chmod +x "$EXEGOL_SETUP/load_user_setup.sh"
    print_success "load_user_setup.sh created"
}

# ───────────────────────────────────────────────────────────────────
# Create README
# ───────────────────────────────────────────────────────────────────

create_readme() {
    print_header "Creating README"

    print_info "Generating README.md..."

    sudo tee "$EXEGOL_SETUP/README.md" > /dev/null << 'EOF'
# Exegol Custom Dotfiles Setup

This directory contains custom configurations for Exegol containers.

## Structure

```
my-resources/
├── setup/
│   ├── zsh/              # Zsh configuration (.zshrc, .zshenv, .zsh/)
│   ├── nvim/             # Neovim configuration
│   ├── starship/         # Starship prompt config
│   ├── zellij/           # Zellij terminal multiplexer config
│   ├── yazi/             # Yazi file manager config
│   └── load_user_setup.sh # Custom installation script
└── bin/                  # Custom binaries (auto-added to PATH)
```

## What Gets Installed

### Officially Supported (via Exegol)
- **Zsh**: Configuration files are automatically deployed
- **Neovim**: Configuration is synced to /root/.config/nvim

### Custom Installations (via load_user_setup.sh)
- **Oh-My-Zsh** with plugins:
  - zsh-syntax-highlighting
  - zsh-autosuggestions
- **Starship**: Custom prompt with Catppuccin Mocha theme
- **Zellij**: Terminal multiplexer with Dracula theme
- **Yazi**: File manager with custom configuration
- **Modern CLI Tools**:
  - Zoxide (better cd)
  - Eza (better ls)
  - Bat (better cat)
  - Fd (better find)
  - Ripgrep (better grep)
  - Delta (better git diff)

## How It Works

1. When you create a new Exegol container, it automatically:
   - Mounts ~/.exegol/my-resources/ at /opt/my-resources
   - Copies supported configs (zsh, nvim) to the appropriate locations
   - Runs load_user_setup.sh on first startup

2. The load_user_setup.sh script:
   - Installs Rust/Cargo (needed for modern tools)
   - Installs Oh-My-Zsh and plugins
   - Installs all custom tools via cargo
   - Copies configurations to the correct locations

## Updating Configs

To sync updated dotfiles from your host to Exegol:

```bash
cd /home/p3ta/tools/dev/exegol
./setup-dotfiles.sh
```

Then restart your Exegol container or create a new one to apply changes.

## Notes

- First container startup may take 5-10 minutes due to cargo installations
- Subsequent containers will be faster if the tools are cached
- All tools are installed to /root/.cargo/bin and automatically added to PATH
- Configurations are persistent across container restarts

## Manual Testing

To test your setup in a new container:

```bash
exegol start test-env
```

Then verify:
- `echo $SHELL` - should show /bin/zsh
- `starship --version` - should show starship version
- `zellij --version` - should show zellij version
- `yazi --version` - should show yazi version
- `eza --version`, `bat --version`, etc.
EOF

    print_success "README.md created"
}

# ───────────────────────────────────────────────────────────────────
# Summary
# ───────────────────────────────────────────────────────────────────

show_summary() {
    print_header "Setup Complete!"

    echo -e "${GREEN}Your dotfiles have been synced to Exegol!${NC}\n"
    echo "Configurations synced:"
    echo "  ✓ Zsh (.zshrc, .zshenv, .zsh/)"
    echo "  ✓ Neovim (full config)"
    echo "  ✓ Starship (starship.toml)"
    echo "  ✓ Zellij (full config)"
    echo "  ✓ Yazi (full config)"
    echo "  ✓ Custom installation script (load_user_setup.sh)"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Test your setup:"
    echo "     exegol start test-env"
    echo ""
    echo "  2. In the container, verify everything is working:"
    echo "     - Your custom prompt should appear (Starship)"
    echo "     - Try: zellij, yazi, eza, bat, etc."
    echo ""
    echo "  3. To update configs later, run this script again:"
    echo "     ./setup-dotfiles.sh"
    echo ""
    echo -e "${YELLOW}Note:${NC} First container startup may take 5-10 minutes"
    echo "      due to cargo installing tools. Be patient!"
    echo ""
    print_info "Configuration location: $EXEGOL_SETUP"
}

# ───────────────────────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────────────────────

main() {
    clear
    print_header "Exegol Dotfiles Setup"

    check_requirements
    setup_zsh
    setup_neovim
    setup_starship
    setup_zellij
    setup_yazi
    create_load_user_setup
    create_readme
    show_summary
}

# Run main function
main "$@"

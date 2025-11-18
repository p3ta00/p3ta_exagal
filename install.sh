#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════
# Exegol Custom Environment Installer
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Destination paths
EXEGOL_RESOURCES="$HOME/.exegol/my-resources"
SETUP_DIR="$EXEGOL_RESOURCES/setup"
BIN_DIR="$EXEGOL_RESOURCES/bin"
TOOLS_DIR="$EXEGOL_RESOURCES/tools"

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

# ───────────────────────────────────────────────────────────────────
# Pre-flight Checks
# ───────────────────────────────────────────────────────────────────

check_requirements() {
    print_header "Checking Requirements"

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        exit 1
    fi

    # Check for required commands
    local required_cmds=("curl" "tar" "git")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "$cmd is not installed. Please install it first."
            exit 1
        fi
    done

    # Check if Exegol is installed (optional warning)
    if ! command -v exegol &> /dev/null; then
        print_warning "Exegol not found. This setup requires Exegol to be installed."
        print_info "Install Exegol: pipx install exegol"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    print_success "All requirements met"
}

# ───────────────────────────────────────────────────────────────────
# Directory Setup
# ───────────────────────────────────────────────────────────────────

setup_directories() {
    print_header "Setting Up Directories"

    # Create directory structure
    sudo mkdir -p "$SETUP_DIR"/{zsh,starship,zellij}
    sudo mkdir -p "$BIN_DIR"
    sudo mkdir -p "$TOOLS_DIR"/{windows,linux}

    # Set proper permissions
    # BIN_DIR needs 755 so all users can execute binaries
    # Other dirs can use 2775 (setgid for group sharing)
    sudo chmod 2775 "$EXEGOL_RESOURCES" "$SETUP_DIR" "$TOOLS_DIR"
    sudo chmod 2775 "$TOOLS_DIR"/{windows,linux}
    sudo chmod 755 "$BIN_DIR"  # Allow all users to access binaries
    sudo chown -R "$USER:$USER" "$EXEGOL_RESOURCES"

    print_success "Directory structure created"
}

# ───────────────────────────────────────────────────────────────────
# Copy Setup Scripts
# ───────────────────────────────────────────────────────────────────

copy_setup_scripts() {
    print_header "Installing Setup Scripts"

    # Copy main setup scripts
    if [ -f "$SCRIPT_DIR/load_user_setup.sh" ]; then
        sudo cp "$SCRIPT_DIR/load_user_setup.sh" "$SETUP_DIR/"
        sudo chmod +x "$SETUP_DIR/load_user_setup.sh"
        print_success "Copied load_user_setup.sh"
    fi

    if [ -f "$SCRIPT_DIR/copy_tools.sh" ]; then
        sudo cp "$SCRIPT_DIR/copy_tools.sh" "$SETUP_DIR/"
        sudo chmod +x "$SETUP_DIR/copy_tools.sh"
        print_success "Copied copy_tools.sh"
    fi

    # Copy dotfiles setup if it exists
    if [ -f "$SCRIPT_DIR/setup-dotfiles.sh" ]; then
        sudo cp "$SCRIPT_DIR/setup-dotfiles.sh" "$SETUP_DIR/"
        sudo chmod +x "$SETUP_DIR/setup-dotfiles.sh"
        print_success "Copied setup-dotfiles.sh"
    fi

    sudo chown -R "$USER:$USER" "$SETUP_DIR"
}

# ───────────────────────────────────────────────────────────────────
# Copy Configs
# ───────────────────────────────────────────────────────────────────

copy_configs() {
    print_header "Installing Configuration Files"

    local configs_found=0

    # Check for configs in script directory
    if [ -d "$SCRIPT_DIR/configs" ]; then
        print_info "Found configs directory..."

        # Copy zsh configs
        if [ -f "$SCRIPT_DIR/configs/zshrc" ]; then
            sudo cp "$SCRIPT_DIR/configs/zshrc" "$SETUP_DIR/zsh/zshrc"
            print_success "Copied zshrc"
            configs_found=1
        fi

        # Copy starship config
        if [ -f "$SCRIPT_DIR/configs/starship.toml" ]; then
            sudo cp "$SCRIPT_DIR/configs/starship.toml" "$SETUP_DIR/starship/"
            print_success "Copied starship config"
            configs_found=1
        fi

        # Copy zellij config
        if [ -d "$SCRIPT_DIR/configs/zellij" ]; then
            sudo cp -r "$SCRIPT_DIR/configs/zellij/"* "$SETUP_DIR/zellij/"
            print_success "Copied zellij config"
            configs_found=1
        fi
    fi

    # Fallback: Check if there's a sibling cachyos-setup directory
    if [ $configs_found -eq 0 ]; then
        local cachyos_setup="$SCRIPT_DIR/../cachyos-setup"

        if [ -d "$cachyos_setup/dotfiles" ]; then
            print_info "Found cachyos-setup dotfiles, copying..."

            # Copy zsh configs
            if [ -f "$cachyos_setup/dotfiles/.zshrc" ]; then
                sudo cp "$cachyos_setup/dotfiles/.zshrc" "$SETUP_DIR/zsh/zshrc"
                print_success "Copied zshrc"
                configs_found=1
            fi

            # Copy starship config
            if [ -f "$cachyos_setup/config/starship.toml" ]; then
                sudo cp "$cachyos_setup/config/starship.toml" "$SETUP_DIR/starship/"
                print_success "Copied starship config"
                configs_found=1
            fi

            # Copy zellij config
            if [ -d "$cachyos_setup/config/zellij" ]; then
                sudo cp -r "$cachyos_setup/config/zellij/"* "$SETUP_DIR/zellij/"
                print_success "Copied zellij config"
                configs_found=1
            fi
        fi
    fi

    if [ $configs_found -eq 0 ]; then
        print_warning "No config files found, skipping"
        print_info "Setup will still work with default configs"
        print_info "You can manually add your configs to $SETUP_DIR/"
    fi

    sudo chown -R "$USER:$USER" "$SETUP_DIR"
}

# ───────────────────────────────────────────────────────────────────
# Summary
# ───────────────────────────────────────────────────────────────────

print_summary() {
    print_header "Installation Complete"

    echo -e "${GREEN}✓ Setup scripts installed${NC}"
    echo -e "${GREEN}✓ Directory structure created${NC}"
    echo -e "${GREEN}✓ Configuration files copied${NC}"
    echo ""
    echo -e "${BLUE}Location:${NC} $EXEGOL_RESOURCES"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Add custom tools:"
    echo -e "     sudo cp your-tool.exe $TOOLS_DIR/windows/"
    echo -e "     sudo cp your-tool $TOOLS_DIR/linux/"
    echo ""
    echo -e "  2. Start an Exegol container:"
    echo -e "     exegol start my-pentest full"
    echo ""
    echo -e "  3. Your custom environment will load automatically!"
    echo ""
    echo -e "${GREEN}Happy hacking! 🔐${NC}"
}

# ───────────────────────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────────────────────

main() {
    print_header "Exegol Custom Environment Installer"

    check_requirements
    setup_directories
    copy_setup_scripts
    copy_configs
    print_summary
}

main

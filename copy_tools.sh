#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════
# Copy Custom Tools to /opt/resources
# ═══════════════════════════════════════════════════════════════════
# This script copies custom tools from persistent my-resources to
# /opt/resources (non-persistent) directories in Exegol containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source and destination paths
MY_RESOURCES_TOOLS="/opt/my-resources/tools"
OPT_RESOURCES="/opt/resources"

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
# Copy Tools Function
# ───────────────────────────────────────────────────────────────────

copy_tools_from_dir() {
    local source_dir="$1"
    local dest_dir="$2"
    local platform="$3"

    if [ ! -d "$source_dir" ]; then
        print_warning "$platform tools directory not found: $source_dir"
        return 0
    fi

    print_info "Copying $platform tools..."

    # Create destination directory
    mkdir -p "$dest_dir"

    # Use rsync for much faster copying, excluding .git directories
    if command -v rsync &> /dev/null; then
        rsync -a --exclude='.git/' "$source_dir/" "$dest_dir/" 2>/dev/null
        local file_count=$(find "$dest_dir" -type f 2>/dev/null | wc -l)

        # Make common executable file types executable
        find "$dest_dir" -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.ps1" -o -name "*.sh" -o -name "*.py" -o -name "*.rb" -o -name "*.pl" \) -exec chmod +x {} + 2>/dev/null

        print_success "Copied $file_count $platform tool(s) to $dest_dir"
    else
        # Fallback to cp if rsync is not available
        cp -rp "$source_dir"/* "$dest_dir/" 2>/dev/null

        # Remove .git directories
        find "$dest_dir" -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true

        local file_count=$(find "$dest_dir" -type f 2>/dev/null | wc -l)

        # Make common executable file types executable
        find "$dest_dir" -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.ps1" -o -name "*.sh" -o -name "*.py" -o -name "*.rb" -o -name "*.pl" \) -exec chmod +x {} + 2>/dev/null

        print_success "Copied $file_count $platform tool(s) to $dest_dir"
    fi
}

# ───────────────────────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────────────────────

main() {
    print_header "Copying Custom Tools to /opt/resources"

    # Check if my-resources tools directory exists
    if [ ! -d "$MY_RESOURCES_TOOLS" ]; then
        print_error "Tools directory not found: $MY_RESOURCES_TOOLS"
        print_info "Please create it and add your tools"
        exit 1
    fi

    # Copy Windows tools
    copy_tools_from_dir \
        "$MY_RESOURCES_TOOLS/windows" \
        "$OPT_RESOURCES/windows" \
        "Windows"

    # Copy Linux tools
    copy_tools_from_dir \
        "$MY_RESOURCES_TOOLS/linux" \
        "$OPT_RESOURCES/linux" \
        "Linux"

    print_header "Tool Copy Complete"
    print_success "All tools have been copied to /opt/resources"
    print_info "Windows tools: $OPT_RESOURCES/windows/"
    print_info "Linux tools: $OPT_RESOURCES/linux/"
}

# Run main function
main

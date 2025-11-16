#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════
# Copy Custom Tools to /opt/resources (MERGED)
# ═══════════════════════════════════════════════════════════════════
# This script merges custom tools from persistent my-resources to
# /opt/resources (non-persistent) directory in Exegol containers
# ALL Windows and Linux tools are merged into a single /opt/resources folder

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
# Merge Tools Function
# ───────────────────────────────────────────────────────────────────

merge_tools_from_dir() {
    local source_dir="$1"
    local dest_dir="$2"
    local platform="$3"

    if [ ! -d "$source_dir" ]; then
        print_warning "$platform tools directory not found: $source_dir"
        return 0
    fi

    print_info "Merging $platform tools into $dest_dir..."

    # Create destination directory if it doesn't exist
    mkdir -p "$dest_dir"

    # Use rsync to MERGE (not replace) files
    if command -v rsync &> /dev/null; then
        # rsync will merge/overwrite files but NOT delete existing files
        rsync -av --exclude='.git/' "$source_dir/" "$dest_dir/" 2>/dev/null
        local file_count=$(find "$source_dir" -type f 2>/dev/null | wc -l)

        # Make common executable file types executable
        find "$dest_dir" -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.ps1" -o -name "*.sh" -o -name "*.py" -o -name "*.rb" -o -name "*.pl" \) -exec chmod +x {} + 2>/dev/null

        print_success "Merged $file_count $platform tool(s) into $dest_dir"
    else
        # Fallback to cp if rsync is not available
        # cp -n will NOT overwrite existing files (keeps both)
        # Use find to copy all files while preserving structure
        (cd "$source_dir" && find . -type f -exec cp --parents -n {} "$dest_dir/" \; 2>/dev/null) || \
        (cd "$source_dir" && find . -type f | cpio -pdm "$dest_dir" 2>/dev/null)

        # Remove .git directories
        find "$dest_dir" -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true

        local file_count=$(find "$source_dir" -type f 2>/dev/null | wc -l)

        # Make common executable file types executable
        find "$dest_dir" -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.ps1" -o -name "*.sh" -o -name "*.py" -o -name "*.rb" -o -name "*.pl" \) -exec chmod +x {} + 2>/dev/null

        print_success "Merged $file_count $platform tool(s) into $dest_dir"
    fi
}

# ───────────────────────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────────────────────

main() {
    print_header "Merging Custom Tools to /opt/resources"

    # Check if my-resources tools directory exists
    if [ ! -d "$MY_RESOURCES_TOOLS" ]; then
        print_error "Tools directory not found: $MY_RESOURCES_TOOLS"
        print_info "Please create it and add your tools"
        exit 1
    fi

    print_info "Merging Windows and Linux tools into single directory: $OPT_RESOURCES"
    echo ""

    # Merge Windows tools into /opt/resources
    merge_tools_from_dir \
        "$MY_RESOURCES_TOOLS/windows" \
        "$OPT_RESOURCES" \
        "Windows"

    # Merge Linux tools into /opt/resources
    merge_tools_from_dir \
        "$MY_RESOURCES_TOOLS/linux" \
        "$OPT_RESOURCES" \
        "Linux"

    # Count total files
    local total_files=$(find "$OPT_RESOURCES" -type f 2>/dev/null | wc -l)

    print_header "Tool Merge Complete"
    print_success "All tools have been merged to $OPT_RESOURCES"
    print_info "Total files: $total_files"
    print_info "All Windows and Linux tools are now in: $OPT_RESOURCES/"
    echo ""
    print_warning "Note: Files are MERGED, not replaced. Existing files are preserved."
    print_warning "New files with same names will overwrite old ones."
}

# Run main function
main

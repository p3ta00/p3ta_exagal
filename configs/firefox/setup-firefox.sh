#!/bin/bash
# Restore persistent Firefox profile from my-resources
# This script is called from load_user_setup.sh on first container startup

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

PERSISTENT_PROFILE="/opt/my-resources/setup/firefox/profile/.mozilla"

if [ -d "$PERSISTENT_PROFILE" ]; then
    echo -e "${BLUE}[*]${NC} Restoring Firefox profile from my-resources..."
    rm -rf /root/.mozilla
    ln -sf "$PERSISTENT_PROFILE" /root/.mozilla
    echo -e "${GREEN}[+]${NC} Firefox profile linked (bookmarks preserved)"
else
    echo -e "${BLUE}[*]${NC} No persistent Firefox profile found, skipping"
fi

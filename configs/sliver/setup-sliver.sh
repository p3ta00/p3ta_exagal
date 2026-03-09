#!/bin/bash
# Symlink sliver data dirs to persistent storage

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SLIVER_PERSISTENT="/opt/my-resources/setup/sliver"

# Symlink .sliver (server data, DB, implants)
if [ -d "$SLIVER_PERSISTENT/.sliver" ] && [ ! -L /root/.sliver ]; then
    echo -e "${BLUE}[*]${NC} Linking Sliver server data to persistent storage..."
    rm -rf /root/.sliver
    ln -s "$SLIVER_PERSISTENT/.sliver" /root/.sliver
    echo -e "${GREEN}[+]${NC} Sliver server data linked"
fi

# Symlink .sliver-client (aliases, extensions/armory, configs)
if [ -d "$SLIVER_PERSISTENT/.sliver-client" ] && [ ! -L /root/.sliver-client ]; then
    echo -e "${BLUE}[*]${NC} Linking Sliver client data to persistent storage..."
    rm -rf /root/.sliver-client
    ln -s "$SLIVER_PERSISTENT/.sliver-client" /root/.sliver-client
    echo -e "${GREEN}[+]${NC} Sliver client data linked (armory extensions persist)"
fi

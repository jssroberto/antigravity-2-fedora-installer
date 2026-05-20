#!/usr/bin/env bash

# Antigravity 2.0 Fedora Uninstaller
# Safe, robust, and clean removal utility.

set -euo pipefail

# Text formatters
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Antigravity Uninstaller ===${NC}"

# Define target paths
SYSTEM_OPT_DIR="/opt/Antigravity-Linux"
SYSTEM_BIN_LINK="/usr/local/bin/antigravity"
SYSTEM_DESKTOP_DIR="/usr/share/applications"

USER_SHARE_DIR="$HOME/.local/share/Antigravity-Linux"
USER_BIN_DIR="$HOME/.local/bin"
USER_DESKTOP_DIR="$HOME/.local/share/applications"

# Function to safely delete files/folders
safe_remove() {
    local target="$1"
    local use_sudo="${2:-false}"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo -e "${YELLOW}Removing: $target${NC}"
        if [ "$use_sudo" = "true" ]; then
            sudo rm -rf "$target"
        else
            rm -rf "$target"
        fi
    fi
}

# 1. Check System-wide installations
if [ -d "$SYSTEM_OPT_DIR" ] || [ -f "$SYSTEM_DESKTOP_DIR/antigravity.desktop" ] || [ -L "$SYSTEM_BIN_LINK" ]; then
    echo -e "${BLUE}Found system-wide installation files. Requesting removal...${NC}"
    
    # Safely remove opt dir, symlink, and desktop entries
    safe_remove "$SYSTEM_OPT_DIR" "true"
    safe_remove "$SYSTEM_BIN_LINK" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity.desktop" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-2.desktop" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-url-handler.desktop" "true"
    
    echo -e "${YELLOW}Refreshing system-wide desktop database...${NC}"
    sudo update-desktop-database "$SYSTEM_DESKTOP_DIR" || true
fi

# 2. Check User-local installations
if [ -d "$USER_SHARE_DIR" ] || [ -f "$USER_DESKTOP_DIR/antigravity.desktop" ] || [ -f "$USER_DESKTOP_DIR/antigravity-2.desktop" ] || [ -f "$USER_BIN_DIR/antigravity" ]; then
    echo -e "${BLUE}Found user-local installation files. Removing...${NC}"
    
    # Safely remove local share, bin link, and desktop entries
    safe_remove "$USER_SHARE_DIR" "false"
    safe_remove "$USER_BIN_DIR/antigravity" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity.desktop" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity-2.desktop" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity-legacy.desktop" "false"
    
    echo -e "${YELLOW}Refreshing user desktop database...${NC}"
    update-desktop-database "$USER_DESKTOP_DIR" || true
fi

echo -e "${GREEN}✓ Uninstallation complete. Antigravity has been cleanly removed.${NC}"

#!/usr/bin/env bash

# Antigravity 2.0 Fedora Uninstaller
# Safe, robust, and clean removal utility with interactive menu.

set -euo pipefail

# Text formatters
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}=== Antigravity Uninstaller ===${NC}"

# --- INTERACTIVE MENU ---
echo -e "\n${BOLD}Select what you want to uninstall:${NC}"
echo -e "  ${GREEN}1)${NC} Uninstall Antigravity 2.0 ${BOLD}IDE${NC} only"
echo -e "  ${GREEN}2)${NC} Uninstall Antigravity 2.0 ${BOLD}Agent${NC} only"
echo -e "  ${GREEN}3)${NC} Uninstall ${BOLD}Both${NC} (Complete Cleanup)"
echo -ne "\nEnter an option [1-3]: "

read -r OPTION

REMOVE_IDE=false
REMOVE_AGENT=false

case "$OPTION" in
    1)
        REMOVE_IDE=true
        ;;
    2)
        REMOVE_AGENT=true
        ;;
    3)
        REMOVE_IDE=true
        REMOVE_AGENT=true
        ;;
    *)
        echo -e "${RED}Invalid option. Canceling uninstallation.${NC}" >&2
        exit 1
        ;;
esac

# Define target paths
SYSTEM_DESKTOP_DIR="/usr/share/applications"
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

# --- UNINSTALLATION PROCESS ---

# 1. System-wide removal (Requires sudo if components exist)
if [ "$REMOVE_AGENT" = "true" ]; then
    echo -e "\n${BLUE}Checking for system-wide Agent components...${NC}"
    safe_remove "/opt/Antigravity-Linux" "true"
    safe_remove "/opt/Antigravity-x64" "true"
    safe_remove "/usr/local/bin/antigravity" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity.desktop" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-legacy.desktop" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-2.desktop" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-url-handler.desktop" "true"
fi

if [ "$REMOVE_IDE" = "true" ]; then
    echo -e "\n${BLUE}Checking for system-wide IDE components...${NC}"
    safe_remove "/opt/antigravity-ide-Linux" "true"
    safe_remove "/usr/local/bin/antigravity-ide" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-ide.desktop" "true"
    safe_remove "$SYSTEM_DESKTOP_DIR/antigravity-ide-legacy.desktop" "true"
fi

# Refresh system-wide desktop database if needed
if [ -d "$SYSTEM_DESKTOP_DIR" ]; then
    sudo update-desktop-database "$SYSTEM_DESKTOP_DIR" || true
fi


# 2. User-local removal (No sudo required)
if [ "$REMOVE_AGENT" = "true" ]; then
    echo -e "\n${BLUE}Checking for user-local Agent components...${NC}"
    safe_remove "$HOME/.local/share/Antigravity-Linux" "false"
    safe_remove "$HOME/.local/share/Antigravity-x64" "false"
    safe_remove "$HOME/.local/bin/antigravity" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity.desktop" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity-legacy.desktop" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity-2.desktop" "false"
fi

if [ "$REMOVE_IDE" = "true" ]; then
    echo -e "\n${BLUE}Checking for user-local IDE components...${NC}"
    safe_remove "$HOME/.local/share/antigravity-ide-Linux" "false"
    safe_remove "$HOME/.local/bin/antigravity-ide" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity-ide.desktop" "false"
    safe_remove "$USER_DESKTOP_DIR/antigravity-ide-legacy.desktop" "false"
fi

# Refresh user desktop database if needed
if [ -d "$USER_DESKTOP_DIR" ]; then
    update-desktop-database "$USER_DESKTOP_DIR" || true
fi

echo -e "\n${GREEN}${BOLD}✓ Uninstallation task completed successfully!${NC}"

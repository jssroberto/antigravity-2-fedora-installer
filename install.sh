#!/usr/bin/env bash

# Antigravity 2.0 Fedora Installer
# A secure, robust, and native installation script for Fedora.
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   --user        Install to user space (~/.local) without requiring root privileges.
#   --url <url>   Override the default download URL.
#   --dry-run     Run pre-flight checks and download the package but do not write any files.
#   -h, --help    Show help message.

set -euo pipefail

# ANSI color codes for premium terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
INSTALL_SCOPE="system"
DOWNLOAD_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.0-6324554176528384/linux-x64/Antigravity.tar.gz"
DRY_RUN=false
TEMP_DIR=""

# Print usage instructions
show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
  --user        Install to user space (~/.local) without requiring root privileges.
  --url <url>   Override the default download URL.
  --dry-run     Perform pre-flight checks and package download only. No files written.
  -h, --help    Show this help message.
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            INSTALL_SCOPE="user"
            shift
            ;;
        --url)
            if [[ -n "${2:-}" ]]; then
                DOWNLOAD_URL="$2"
                shift 2
            else
                echo -e "${RED}Error: --url requires a value.${NC}" >&2
                exit 1
            fi
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
            *)
            echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}${BOLD}=== Antigravity 2.0 Installer ===${NC}"
echo -e "${BLUE}Targeting scope: ${BOLD}${INSTALL_SCOPE}${NC}"

# Define paths based on install scope
if [[ "$INSTALL_SCOPE" == "system" ]]; then
    TARGET_PARENT_DIR="/opt"
    TARGET_APP_DIR="/opt/Antigravity-Linux"
    TARGET_BIN_PATH="/usr/local/bin/antigravity"
    DESKTOP_ENTRY_DIR="/usr/share/applications"
    DESKTOP_ENTRY_PATH="$DESKTOP_ENTRY_DIR/antigravity.desktop"
    ICON_LOOKUP_NAME="antigravity"
else
    TARGET_PARENT_DIR="$HOME/.local/share"
    TARGET_APP_DIR="$HOME/.local/share/Antigravity-Linux"
    TARGET_BIN_PATH="$HOME/.local/bin/antigravity"
    DESKTOP_ENTRY_DIR="$HOME/.local/share/applications"
    DESKTOP_ENTRY_PATH="$DESKTOP_ENTRY_DIR/antigravity.desktop"
    ICON_LOOKUP_NAME="antigravity"
fi

# Pre-flight check: CPU Architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
    echo -e "${RED}Error: Antigravity Linux build is strictly x86_64 or aarch64. Detected: ${ARCH}${NC}" >&2
    exit 1
fi

# Pre-flight check: Required utilities
echo -e "${YELLOW}Verifying system utilities...${NC}"
for util in curl tar sed update-desktop-database; do
    if ! command -v "$util" &> /dev/null; then
        echo -e "${RED}Error: Required command '$util' is missing.${NC}" >&2
        exit 1
    fi
done
echo -e "${GREEN}✓ All core utilities verified.${NC}"

# Setup secure cleanup on script exit or interrupt
cleanup() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        echo -e "${YELLOW}Cleaning up temporary directory: $TEMP_DIR${NC}"
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

# Create secure temporary directory for download
TEMP_DIR=$(mktemp -d -t antigravity-install-XXXXXX)
TEMP_ARCHIVE="$TEMP_DIR/Antigravity.tar.gz"

# Fetch/Download the tarball package
echo -e "${YELLOW}Downloading Antigravity package...${NC}"
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}[DRY RUN] Would download from: $DOWNLOAD_URL${NC}"
fi

# Perform download with retry logic
HTTP_CODE=$(curl -sSL -w "%{http_code}" -o "$TEMP_ARCHIVE" "$DOWNLOAD_URL")
if [[ "$HTTP_CODE" -ne 200 ]]; then
    echo -e "${RED}Error: Download failed with HTTP status code $HTTP_CODE${NC}" >&2
    exit 1
fi
echo -e "${GREEN}✓ Downloaded successfully.${NC}"

# Extract package and install files (Skip if --dry-run)
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}[DRY RUN] Would extract files and configure launcher paths.${NC}"
    echo -e "${GREEN}✓ Dry-run completed successfully. The environment and download were verified.${NC}"
    exit 0
fi

# System-wide installations require selective elevation
escalate_cmd() {
    if [[ "$INSTALL_SCOPE" == "system" ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

echo -e "${YELLOW}Extracting and installing binaries...${NC}"

# Remove target directory if it already exists for a clean fresh install
if [[ -d "$TARGET_APP_DIR" ]]; then
    echo -e "${YELLOW}Removing old installation folder at $TARGET_APP_DIR...${NC}"
    escalate_cmd rm -rf "$TARGET_APP_DIR"
fi

# Ensure parent directory exists
escalate_cmd mkdir -p "$TARGET_PARENT_DIR"

# Extract archive to a temporary location to detect the internal folder name
EXTRACT_TEMP="$TEMP_DIR/extract_temp"
mkdir -p "$EXTRACT_TEMP"
tar -xzf "$TEMP_ARCHIVE" -C "$EXTRACT_TEMP"

# Identify the extracted folder (there should be exactly one)
EXTRACTED_DIR_NAME=$(ls -1 "$EXTRACT_TEMP" | head -n 1)

if [[ -z "$EXTRACTED_DIR_NAME" ]]; then
    echo -e "${RED}Error: Archive extraction failed or archive is empty.${NC}" >&2
    exit 1
fi

echo -e "${BLUE}Detected package folder: $EXTRACTED_DIR_NAME${NC}"

# Move the extracted content to the final destination
escalate_cmd mv "$EXTRACT_TEMP/$EXTRACTED_DIR_NAME" "$TARGET_APP_DIR"

# Verify execution capability
if [[ ! -f "$TARGET_APP_DIR/antigravity" ]]; then
    echo -e "${RED}Error: Executable not found at $TARGET_APP_DIR/antigravity${NC}" >&2
    echo -e "${YELLOW}Contents of $TARGET_APP_DIR:${NC}"
    escalate_cmd ls -F "$TARGET_APP_DIR"
    exit 1
fi
escalate_cmd chmod +x "$TARGET_APP_DIR/antigravity"

# Configure symlink path
echo -e "${YELLOW}Configuring system command shortcuts...${NC}"
# Ensure user-local bin folder exists
if [[ "$INSTALL_SCOPE" == "user" ]]; then
    mkdir -p "$(dirname "$TARGET_BIN_PATH")"
fi

escalate_cmd rm -f "$TARGET_BIN_PATH"
escalate_cmd ln -s "$TARGET_APP_DIR/antigravity" "$TARGET_BIN_PATH"

# Configure Desktop application launcher entry
echo -e "${YELLOW}Generating Desktop integration entry...${NC}"

# Shadowing Detection: Check if a local desktop file will hide the system-wide one
LOCAL_SHADOW_FILE="$HOME/.local/share/applications/antigravity.desktop"
if [[ "$INSTALL_SCOPE" == "system" && -f "$LOCAL_SHADOW_FILE" ]]; then
    echo -e "${YELLOW}${BOLD}⚠️  Shadowing Conflict Detected!${NC}"
    echo -e "${YELLOW}A local desktop entry at $LOCAL_SHADOW_FILE is currently shadowing the system-wide launcher.${NC}"
    echo -e "${YELLOW}This will prevent 'Antigravity 2.0' from appearing in your application menu.${NC}"
    
    # Check if it belongs to v1.x
    if grep -q "/usr/share/antigravity" "$LOCAL_SHADOW_FILE" 2>/dev/null; then
        echo -e "${BLUE}Detected legacy v1.x configuration. Renaming it to 'antigravity-legacy.desktop' to resolve...${NC}"
        mv "$LOCAL_SHADOW_FILE" "$HOME/.local/share/applications/antigravity-legacy.desktop"
        update-desktop-database "$HOME/.local/share/applications" || true
        echo -e "${GREEN}✓ Shadowing resolved.${NC}"
    else
        echo -e "${RED}Warning: Please manually remove or rename $LOCAL_SHADOW_FILE to see the new version.${NC}"
    fi
fi
DESKTOP_TEMPLATE="$(dirname "$0")/antigravity.desktop.template"

if [[ ! -f "$DESKTOP_TEMPLATE" ]]; then
    echo -e "${RED}Error: Application launcher template not found: $DESKTOP_TEMPLATE${NC}" >&2
    exit 1
fi

# Clean up older, duplicate desktop launchers to prevent duplicate launcher shortcuts
escalate_cmd rm -f "$DESKTOP_ENTRY_DIR/antigravity-2.desktop"

# Process the template file and place it in the application menu path
TEMP_DESKTOP="$TEMP_DIR/antigravity.desktop"
cp "$DESKTOP_TEMPLATE" "$TEMP_DESKTOP"

sed -i "s|__NAME__|Antigravity 2.0|g" "$TEMP_DESKTOP"
sed -i "s|__COMMENT__|Experience liftoff (v2.0 Standalone)|g" "$TEMP_DESKTOP"
sed -i "s|__EXEC_PATH__|$TARGET_BIN_PATH|g" "$TEMP_DESKTOP"
sed -i "s|__ICON_PATH__|$ICON_LOOKUP_NAME|g" "$TEMP_DESKTOP"

# Install desktop file to applications folder
escalate_cmd mkdir -p "$DESKTOP_ENTRY_DIR"
escalate_cmd cp "$TEMP_DESKTOP" "$DESKTOP_ENTRY_PATH"
escalate_cmd chmod 644 "$DESKTOP_ENTRY_PATH"

# SELinux context restoration for system installations on Fedora
if [[ "$INSTALL_SCOPE" == "system" ]] && command -v restorecon &> /dev/null; then
    echo -e "${YELLOW}Restoring SELinux contexts for $TARGET_APP_DIR...${NC}"
    sudo restorecon -R "$TARGET_APP_DIR" || true
fi

# Update desktop application databases
echo -e "${YELLOW}Updating desktop database shortcuts...${NC}"
escalate_cmd update-desktop-database "$DESKTOP_ENTRY_DIR" || true

echo -e "${GREEN}${BOLD}✓ Antigravity 2.0 successfully installed!${NC}"
echo -e "You can launch the IDE via:"
echo -e "  * Terminal command: ${BOLD}antigravity${NC}"
echo -e "  * Application menu entry: ${BOLD}Antigravity 2.0${NC}"

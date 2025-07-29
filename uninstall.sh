#!/bin/bash

# Uninstall Script
# This script removes all components installed by the install.sh script

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

                    UNINSTALLER
EOF
echo -e "${NC}"

echo -e "${YELLOW}[!] This will completely remove all installed components${NC}"
echo -e "${YELLOW}[!] Including kernel module, agent binary, and persistence mechanisms${NC}"
echo ""

# Confirmation
read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}[*] Uninstall cancelled${NC}"
    exit 0
fi

echo -e "${BLUE}[*] Starting uninstall process...${NC}"
echo ""

# 1. Remove kernel module if loaded
echo -e "${BLUE}[*] Removing kernel module...${NC}"
if lsmod | grep -q intel_rapl_headers; then
    if sudo rmmod intel_rapl_headers; then
        echo -e "${GREEN}[+] Kernel module removed${NC}"
    else
        echo -e "${YELLOW}[!] Failed to remove kernel module (may not be loaded)${NC}"
    fi
else
    echo -e "${YELLOW}[!] Kernel module not loaded${NC}"
fi

# 2. Remove agent binary
echo -e "${BLUE}[*] Removing agent binary...${NC}"
if [ -f "/usr/bin/intelheaders_gnu" ]; then
    if sudo rm -f /usr/bin/intelheaders_gnu; then
        echo -e "${GREEN}[+] Agent binary removed${NC}"
    else
        echo -e "${RED}[!] Failed to remove agent binary${NC}"
    fi
else
    echo -e "${YELLOW}[!] Agent binary not found${NC}"
fi

# 3. Remove kernel module files
echo -e "${BLUE}[*] Removing kernel module files...${NC}"
if [ -d "/lib/modules/$(uname -r)/kernel/drivers/intel_rapl_headers" ]; then
    if sudo rm -rf /lib/modules/$(uname -r)/kernel/drivers/intel_rapl_headers; then
        echo -e "${GREEN}[+] Kernel module files removed${NC}"
    else
        echo -e "${RED}[!] Failed to remove kernel module files${NC}"
    fi
else
    echo -e "${YELLOW}[!] Kernel module files not found${NC}"
fi

# 4. Remove modules-load.d configuration
echo -e "${BLUE}[*] Removing auto-load configuration...${NC}"
if [ -f "/etc/modules-load.d/intel_rapl_headers.conf" ]; then
    if sudo rm -f /etc/modules-load.d/intel_rapl_headers.conf; then
        echo -e "${GREEN}[+] modules-load.d configuration removed${NC}"
    else
        echo -e "${RED}[!] Failed to remove modules-load.d configuration${NC}"
    fi
else
    echo -e "${YELLOW}[!] modules-load.d configuration not found${NC}"
fi

# 5. Remove from /etc/modules
echo -e "${BLUE}[*] Removing from /etc/modules...${NC}"
if [ -f "/etc/modules" ]; then
    if grep -q "intel_rapl_headers" /etc/modules; then
        if sudo sed -i '/intel_rapl_headers/d' /etc/modules; then
            echo -e "${GREEN}[+] Removed from /etc/modules${NC}"
        else
            echo -e "${RED}[!] Failed to remove from /etc/modules${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Not found in /etc/modules${NC}"
    fi
else
    echo -e "${YELLOW}[!] /etc/modules not found${NC}"
fi

# 6. Remove from rc.local
echo -e "${BLUE}[*] Removing from rc.local...${NC}"
if [ -f "/etc/rc.local" ]; then
    if grep -q "modprobe intel_rapl_headers" /etc/rc.local; then
        if sudo sed -i '/modprobe intel_rapl_headers/d' /etc/rc.local; then
            echo -e "${GREEN}[+] Removed from rc.local${NC}"
        else
            echo -e "${RED}[!] Failed to remove from rc.local${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Not found in rc.local${NC}"
    fi
else
    echo -e "${YELLOW}[!] rc.local not found${NC}"
fi

# 7. Remove init script
echo -e "${BLUE}[*] Removing init script...${NC}"
if [ -f "/etc/init.d/intel-rapl-headers" ]; then
    sudo update-rc.d intel-rapl-headers remove 2>/dev/null || true
    if sudo rm -f /etc/init.d/intel-rapl-headers; then
        echo -e "${GREEN}[+] Init script removed${NC}"
    else
        echo -e "${RED}[!] Failed to remove init script${NC}"
    fi
else
    echo -e "${YELLOW}[!] Init script not found${NC}"
fi

# 8. Remove from crontab
echo -e "${BLUE}[*] Removing from root crontab...${NC}"
if sudo crontab -l 2>/dev/null | grep -q "modprobe intel_rapl_headers"; then
    if (sudo crontab -l 2>/dev/null | grep -v "modprobe intel_rapl_headers") | sudo crontab -; then
        echo -e "${GREEN}[+] Removed from root crontab${NC}"
    else
        echo -e "${RED}[!] Failed to remove from root crontab${NC}"
    fi
else
    echo -e "${YELLOW}[!] Not found in root crontab${NC}"
fi

# 9. Remove systemd service
echo -e "${BLUE}[*] Removing systemd service...${NC}"
if [ -f "/etc/systemd/system/intel-rapl-headers.service" ]; then
    sudo systemctl stop intel-rapl-headers.service 2>/dev/null || true
    sudo systemctl disable intel-rapl-headers.service 2>/dev/null || true
    if sudo rm -f /etc/systemd/system/intel-rapl-headers.service; then
        sudo systemctl daemon-reload 2>/dev/null || true
        echo -e "${GREEN}[+] Systemd service removed${NC}"
    else
        echo -e "${RED}[!] Failed to remove systemd service${NC}"
    fi
else
    echo -e "${YELLOW}[!] Systemd service not found${NC}"
fi

# 10. Update module dependencies
echo -e "${BLUE}[*] Updating module dependencies...${NC}"
sudo depmod -a

# 11. Clean build files (optional)
echo -e "${BLUE}[*] Cleaning build files...${NC}"
if [ -f "Makefile" ]; then
    make clean > /dev/null 2>&1 || true
    echo -e "${GREEN}[+] Build files cleaned${NC}"
else
    echo -e "${YELLOW}[!] Makefile not found${NC}"
fi

echo ""
echo -e "${GREEN}[+] Uninstall completed successfully!${NC}"
echo ""
echo -e "${BLUE}[*] Summary of removed components:${NC}"
echo -e "  - Kernel module (intel_rapl_headers)"
echo -e "  - Agent binary (/usr/bin/intelheaders_gnu)"
echo -e "  - Module files (/lib/modules/*/kernel/drivers/intel_rapl_headers/)"
echo -e "  - Auto-load configurations (modules-load.d, /etc/modules, rc.local)"
echo -e "  - Init script (/etc/init.d/intel-rapl-headers)"
echo -e "  - Crontab entries"
echo -e "  - Systemd service"
echo -e "  - Build files"
echo ""
echo -e "${YELLOW}[!] Please reboot to ensure all components are fully removed${NC}"

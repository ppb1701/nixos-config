#!/usr/bin/env bash
# install-nixos.sh
# Manual NixOS installation script with swap file
# 
# Usage: sudo ./install-nixos.sh
#
# This script will:
# - ERASE /dev/sda completely
# - Create boot (512MB) and root partitions
# - Create a 4GB swap file
# - Install NixOS with your configuration
#
# WARNING: This will destroy all data on /dev/sda!

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TARGET_DISK="/dev/sda"
SWAP_SIZE="4G"  # Adjust as needed

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   NixOS AdGuard Home Installation     ║${NC}"
echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo ""
echo -e "${RED}WARNING: This will ERASE all data on ${TARGET_DISK}!${NC}"
echo ""
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Installation cancelled."
    exit 1
fi

echo ""
echo -e "${GREEN}[1/8] Partitioning disk...${NC}"
parted ${TARGET_DISK} -- mklabel gpt
parted ${TARGET_DISK} -- mkpart primary 512MiB 100%
parted ${TARGET_DISK} -- mkpart ESP fat32 1MiB 512MiB
parted ${TARGET_DISK} -- set 2 esp on

echo -e "${GREEN}[2/8] Formatting partitions...${NC}"
mkfs.ext4 -L nixos ${TARGET_DISK}1
mkfs.fat -F 32 -n boot ${TARGET_DISK}2

echo -e "${GREEN}[3/8] Mounting filesystems...${NC}"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

echo -e "${GREEN}[4/8] Creating ${SWAP_SIZE} swap file...${NC}"
dd if=/dev/zero of=/mnt/swapfile bs=1M count=$((${SWAP_SIZE%G} * 1024)) status=progress
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

echo -e "${GREEN}[5/8] Copying configuration...${NC}"
mkdir -p /mnt/etc/nixos
cp -r /etc/nixos-config/* /mnt/etc/nixos/

echo -e "${GREEN}[6/8] Generating hardware configuration...${NC}"
nixos-generate-config --root /mnt

echo -e "${GREEN}[7/8] Detecting network interface...${NC}"
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n1)
echo "Detected interface: ${INTERFACE}"

# Update interface name in networking.nix
sed -i "s/enp0s3/${INTERFACE}/g" /mnt/etc/nixos/modules/networking.nix

# Add swap file to hardware-configuration.nix
echo "" >> /mnt/etc/nixos/hardware-configuration.nix
echo "  # Swap file" >> /mnt/etc/nixos/hardware-configuration.nix
echo "  swapDevices = [ { device = \"/swapfile\"; } ];" >> /mnt/etc/nixos/hardware-configuration.nix

echo -e "${GREEN}[8/8] Installing NixOS...${NC}"
echo "This will take 10-20 minutes..."
nixos-install --no-root-passwd

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "1. Remove the USB drive"
echo "2. Reboot: sudo reboot"
echo "3. SSH in: ssh ppb1701@<ip-address>"
echo "4. Edit /etc/nixos/modules/networking.nix to set static IP"
echo "5. Run: sudo nixos-rebuild switch"
echo ""
echo "Your AdGuard Home server is ready!"

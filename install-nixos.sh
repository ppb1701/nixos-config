#!/usr/bin/env bash
set -e

echo "═══════════════════════════════════════════════════════════════════════════"
echo "NixOS Automated Installation"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Available disks:"
lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
echo ""
echo "⚠️  WARNING: Installation will ERASE ALL DATA on the selected disk!"
echo ""
read -p "Enter disk to install to (e.g., nvme0n1, sda) or press Ctrl+C to cancel: " DISK

if [ -z "$DISK" ]; then
    echo "Error: No disk specified"
    exit 1
fi

DISK_PATH="/dev/$DISK"

if [ ! -b "$DISK_PATH" ]; then
    echo "Error: $DISK_PATH is not a valid block device"
    exit 1
fi

echo ""
echo "Installing to $DISK_PATH - ALL DATA WILL BE ERASED"
echo "Starting in 3 seconds... (Ctrl+C to cancel)"
sleep 3

# ═══════════════════════════════════════════════════════════════════════════
# PARTITIONING
# ═══════════════════════════════════════════════════════════════════════════
echo "Partitioning..."

if [[ "$DISK" == nvme* ]] || [[ "$DISK" == mmcblk* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

BOOT_PART="/dev/${PART_PREFIX}1"
ROOT_PART="/dev/${PART_PREFIX}2"

wipefs -af "$DISK_PATH"
parted "$DISK_PATH" --script mklabel gpt
parted "$DISK_PATH" --script mkpart ESP fat32 1MiB 512MiB
parted "$DISK_PATH" --script set 1 esp on
parted "$DISK_PATH" --script mkpart primary 512MiB 100%

# ═══════════════════════════════════════════════════════════════════════════
# FORMATTING
# ═══════════════════════════════════════════════════════════════════════════
echo "Formatting..."
mkfs.fat -F 32 -n boot "$BOOT_PART"
mkfs.ext4 -F -L nixos "$ROOT_PART"

# ═══════════════════════════════════════════════════════════════════════════
# MOUNTING
# ═══════════════════════════════════════════════════════════════════════════
echo "Mounting..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot

# ═══════════════════════════════════════════════════════════════════════════
# COPY CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
echo "Copying configuration..."

mkdir -p /mnt/etc/nixos

cp /etc/nixos/configuration.nix /mnt/etc/nixos/
cp /etc/nixos/iso-config.nix /mnt/etc/nixos/ 2>/dev/null || true

[ -d /etc/nixos/modules ] && cp -r /etc/nixos/modules /mnt/etc/nixos/
[ -d /etc/nixos/private ] && cp -r /etc/nixos/private /mnt/etc/nixos/

cp /etc/nixos/build-iso.sh /mnt/etc/nixos/ 2>/dev/null || true
cp /etc/nixos/install-nixos.sh /mnt/etc/nixos/ 2>/dev/null || true
cp /etc/nixos/.gitignore /mnt/etc/nixos/ 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════
# GENERATE HARDWARE CONFIG
# ═══════════════════════════════════════════════════════════════════════════
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt

# ═══════════════════════════════════════════════════════════════════════════
# INSTALL
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "Installing NixOS (this may take several minutes)..."
echo ""

nixos-install --no-root-passwd

# ═══════════════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "Installation complete!"
echo ""
echo "⚠️  SECURITY: This system has NO PASSWORD"
echo "After reboot: ssh ppb1701@YOUR_IP (press Enter), then run 'passwd'"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Rebooting in 5 seconds..."
sleep 5
reboot

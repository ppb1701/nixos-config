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
read -p "Enter disk to install to (e.g., nvme0n1, sda) or Ctrl+C to cancel: " DISK

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
echo "Select bootloader type:"
echo "1) UEFI (modern systems, systemd-boot)"
echo "2) BIOS/Legacy (older systems, GRUB)"
echo ""
read -p "Enter choice (1 or 2): " BOOT_CHOICE

if [ "$BOOT_CHOICE" = "1" ]; then
    CONFIG_FILE="configuration-uefi.nix"
    USE_UEFI=true
    echo "Using UEFI configuration"
elif [ "$BOOT_CHOICE" = "2" ]; then
    CONFIG_FILE="configuration.nix"
    USE_UEFI=false
    echo "Using BIOS/GRUB configuration"
else
    echo "Invalid choice"
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

wipefs -af "$DISK_PATH"

if [ "$USE_UEFI" = true ]; then
    # UEFI partitioning
    BOOT_PART="/dev/${PART_PREFIX}1"
    ROOT_PART="/dev/${PART_PREFIX}2"

    parted "$DISK_PATH" --script mklabel gpt
    parted "$DISK_PATH" --script mkpart ESP fat32 1MiB 512MiB
    parted "$DISK_PATH" --script set 1 esp on
    parted "$DISK_PATH" --script mkpart primary 512MiB 100%
else
    # BIOS partitioning
    BOOT_PART="/dev/${PART_PREFIX}1"
    ROOT_PART="/dev/${PART_PREFIX}2"

    parted "$DISK_PATH" --script mklabel msdos
    parted "$DISK_PATH" --script mkpart primary ext4 1MiB 512MiB
    parted "$DISK_PATH" --script set 1 boot on
    parted "$DISK_PATH" --script mkpart primary 512MiB 100%
fi

# ═══════════════════════════════════════════════════════════════════════════
# FORMATTING
# ═══════════════════════════════════════════════════════════════════════════
echo "Formatting..."

if [ "$USE_UEFI" = true ]; then
    mkfs.fat -F 32 -n boot "$BOOT_PART"
else
    mkfs.ext4 -F -L boot "$BOOT_PART"
fi

mkfs.ext4 -F -L nixos "$ROOT_PART"

# ═══════════════════════════════════════════════════════════════════════════
# MOUNTING
# ═══════════════════════════════════════════════════════════════════════════
echo "Mounting..."

mount "$ROOT_PART" /mnt
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to mount root partition"
    exit 1
fi

mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to mount boot partition"
    umount /mnt
    exit 1
fi

echo "Mounts verified:"
mount | grep /mnt

# ═══════════════════════════════════════════════════════════════════════════
# COPY CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
echo "Copying configuration..."

mkdir -p /mnt/etc/nixos/modules
mkdir -p /mnt/etc/nixos/private

# Copy the selected configuration as configuration.nix
cp /etc/nixos/$CONFIG_FILE /mnt/etc/nixos/configuration.nix || {
    echo "Error: Failed to copy $CONFIG_FILE"
    exit 1
}

# Copy both config variants for future use
cp /etc/nixos/configuration.nix /mnt/etc/nixos/configuration-bios.nix 2>/dev/null || true
cp /etc/nixos/configuration-uefi.nix /mnt/etc/nixos/ 2>/dev/null || true
cp /etc/nixos/iso-config.nix /mnt/etc/nixos/ 2>/dev/null || true

if [ -d /etc/nixos/modules ] && [ "$(ls -A /etc/nixos/modules)" ]; then
    cp -r /etc/nixos/modules/* /mnt/etc/nixos/modules/
    echo "Copied modules directory"
else
    echo "No modules directory found - creating empty"
fi

if [ -d /etc/nixos/private ] && [ "$(ls -A /etc/nixos/private)" ]; then
    cp -r /etc/nixos/private/* /mnt/etc/nixos/private/
    echo "Copied private directory"
else
    echo "No private directory found - creating empty"
fi

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
echo "⚠️⚠️⚠️  INSTALLATION COMPLETE - SECURITY ACTION REQUIRED  ⚠️⚠️⚠️"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "🔓 This system is using a TEMPORARY, INSECURE PASSWORD!"
echo ""
echo "Default password: nixos"
echo ""
echo "This password is publicly known and MUST be changed immediately."
echo ""
echo "DO NOT expose this system to the internet before securing it!"
echo ""
echo "REQUIRED STEPS (do these NOW, before anything else):"
echo ""
echo "  1. After reboot, SSH into the system:"
echo "     ssh ppb1701@YOUR_IP"
echo "     Password: nixos"
echo ""
echo "  2. Change your password IMMEDIATELY:"
echo "     passwd"
echo ""
echo "  3. Secure the configuration:"
echo "     sudo micro /etc/nixos/configuration.nix"
echo "     - Remove the line: initialPassword = \"nixos\";"
echo "     - Change: security.sudo.wheelNeedsPassword = true;"
echo ""
echo "  4. Apply the changes:"
echo "     sudo nixos-rebuild switch"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Rebooting in 10 seconds..."
sleep 10
reboot

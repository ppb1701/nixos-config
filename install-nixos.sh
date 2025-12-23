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
echo "3) Exit to live environment"
echo ""
read -p "Enter choice (1, 2, or 3): " BOOT_CHOICE

if [ "$BOOT_CHOICE" = "1" ]; then
    CONFIG_FILE="configuration-uefi.nix"
    USE_UEFI=true
    echo "Using UEFI configuration"
elif [ "$BOOT_CHOICE" = "2" ]; then
    CONFIG_FILE="configuration-bios.nix"
    USE_UEFI=false
    echo "Using BIOS/GRUB configuration"
elif [ "$BOOT_CHOICE" = "3" ]; then
    echo "Exiting to live environment..."
    exit 0
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
mkdir -p /mnt/etc/nixos/home

# Copy the selected configuration as configuration.nix (FOLLOW SYMLINKS WITH -L)
cp -L /etc/nixos/$CONFIG_FILE /mnt/etc/nixos/configuration.nix || {
    echo "Error: Failed to copy $CONFIG_FILE"
    exit 1
}

# Copy both config variants for future use (FOLLOW SYMLINKS WITH -L)
cp -L /etc/nixos/configuration-bios.nix /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/configuration-uefi.nix /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/iso-config.nix /mnt/etc/nixos/ 2>/dev/null || true

if [ -d /etc/nixos/modules ] && [ "$(ls -A /etc/nixos/modules)" ]; then
    cp -rL /etc/nixos/modules/* /mnt/etc/nixos/modules/
    echo "Copied modules directory"
else
    echo "No modules directory found - creating empty"
fi

# Copy private directory - prioritize existing backup, fall back to examples
if [ -d /etc/nixos/private ] && [ "$(ls -A /etc/nixos/private)" ]; then
    # User has backed up their private configs - use those
    cp -rL /etc/nixos/private/* /mnt/etc/nixos/private/
    echo "Copied private directory (from backup)"
elif [ -d /etc/nixos/private-example ] && [ "$(ls -A /etc/nixos/private-example)" ]; then
    # No backup found - use example files
    cp -rL /etc/nixos/private-example/* /mnt/etc/nixos/private/
    echo "Copied private-example files to private directory (fresh install)"
else
    # Neither exists - create empty directory
    echo "No private or private-example directory found - creating empty private directory"
fi

if [ -d /etc/nixos/home ] && [ "$(ls -A /etc/nixos/home)" ]; then
    cp -rL /etc/nixos/home/* /mnt/etc/nixos/home/
    echo "Copied home directory"
else
    echo "No home directory found - creating empty"
fi

cp -L /etc/nixos/build-iso.sh /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/install-nixos.sh /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/.gitignore /mnt/etc/nixos/ 2>/dev/null || true

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
echo "⚠️⚠️⚠️  INSTALLATION COMPLETE - CONFIGURATION REQUIRED  ⚠️⚠️⚠️"
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
echo "  2. Add the home-manager channel:"
echo "     sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager"
echo "     sudo nix-channel --update"
echo ""
echo "  3. Change your password IMMEDIATELY:"
echo "     passwd"
echo ""
echo "  4. Secure the configuration:"
echo "     sudo micro /etc/nixos/configuration.nix"
echo "     - Remove the line: initialPassword = \"nixos\";"
echo "     - Change: security.sudo.wheelNeedsPassword = true;"
echo ""
echo "  5. Configure SSH keys (see documentation for details)"
echo "     sudo micro /etc/nixos/private/ssh-keys.nix"
echo ""
echo "  6. Apply the changes:"
echo "     sudo nixos-rebuild switch"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "📧 OPTIONAL: Configure Email Alerting"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Alertmanager will fail to start until you provide real SMTP credentials."
echo "This will NOT affect other services (Prometheus, Grafana, ntfy, AdGuard)."
echo ""
echo "To enable email alerts:"
echo "  1. Generate an app-specific password from your email provider"
echo "     (e.g., Gmail, Fastmail, Outlook, etc.)"
echo ""
echo "  2. Edit the environment file:"
echo "     sudo micro /etc/nixos/private/alertmanager.env"
echo "     - SMTP_USERNAME: Your full email address"
echo "     - SMTP_PASSWORD: Your app-specific password"
echo "     - EMAIL_TO: Where you want to receive alerts"
echo ""
echo "  3. Rebuild the system:"
echo "     sudo nixos-rebuild switch"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "📝 OPTIONAL: Configure NoteDiscovery (Web-based Knowledge Base)"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "NoteDiscovery will auto-install on first boot but needs configuration."
echo ""
echo "To enable NoteDiscovery:"
echo "  1. Edit /etc/nixos/private/notediscovery-config.nix (set notes path)"
echo "  2. Edit /etc/nixos/private/notediscovery-config.yaml (set password hash)"
echo "  3. Generate password: cd /var/lib/notediscovery && sudo -u notediscovery ./venv/bin/python3 generate_password.py"
echo "  4. sudo nixos-rebuild switch"
echo "  5. Add DNS rewrite: notes.home -> YOUR_IP"
echo ""
echo "To disable NoteDiscovery:"
echo "  Comment out the NoteDiscovery section in /etc/nixos/modules/services.nix"
echo ""
echo "Rebooting in 10 seconds..."
sleep 10
reboot

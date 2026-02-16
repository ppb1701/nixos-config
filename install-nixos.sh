#!/usr/bin/env bash
set -e

# Error handler
error_exit() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ ERROR: $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
}

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

[ -z "$DISK" ] && error_exit "No disk specified"

DISK_PATH="/dev/$DISK"

[ ! -b "$DISK_PATH" ] && error_exit "$DISK_PATH is not a valid block device"

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
    error_exit "Invalid choice"
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

wipefs -af "$DISK_PATH" || error_exit "Failed to wipe disk"

if [ "$USE_UEFI" = true ]; then
    BOOT_PART="/dev/${PART_PREFIX}1"
    ROOT_PART="/dev/${PART_PREFIX}2"

    parted "$DISK_PATH" --script mklabel gpt || error_exit "Failed to create GPT partition table"
    parted "$DISK_PATH" --script mkpart ESP fat32 1MiB 512MiB || error_exit "Failed to create EFI partition"
    parted "$DISK_PATH" --script set 1 esp on || error_exit "Failed to set ESP flag"
    parted "$DISK_PATH" --script mkpart primary 512MiB 100% || error_exit "Failed to create root partition"
else
    BOOT_PART="/dev/${PART_PREFIX}1"
    ROOT_PART="/dev/${PART_PREFIX}2"

    parted "$DISK_PATH" --script mklabel msdos || error_exit "Failed to create MBR partition table"
    parted "$DISK_PATH" --script mkpart primary ext4 1MiB 512MiB || error_exit "Failed to create boot partition"
    parted "$DISK_PATH" --script set 1 boot on || error_exit "Failed to set boot flag"
    parted "$DISK_PATH" --script mkpart primary 512MiB 100% || error_exit "Failed to create root partition"
fi

# ═══════════════════════════════════════════════════════════════════════════
# FORMATTING
# ═══════════════════════════════════════════════════════════════════════════
echo "Formatting..."

if [ "$USE_UEFI" = true ]; then
    mkfs.fat -F 32 -n boot "$BOOT_PART" || error_exit "Failed to format EFI partition"
else
    mkfs.ext4 -F -L boot "$BOOT_PART" || error_exit "Failed to format boot partition"
fi

mkfs.ext4 -F -L nixos "$ROOT_PART" || error_exit "Failed to format root partition"

# ═══════════════════════════════════════════════════════════════════════════
# MOUNTING
# ═══════════════════════════════════════════════════════════════════════════
echo "Mounting..."

mount "$ROOT_PART" /mnt || error_exit "Failed to mount root partition"

mkdir -p /mnt/boot || error_exit "Failed to create boot directory"
mount "$BOOT_PART" /mnt/boot || error_exit "Failed to mount boot partition"

echo "Mounts verified:"
mount | grep /mnt

# ═══════════════════════════════════════════════════════════════════════════
# COPY CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════
echo "Copying configuration..."

mkdir -p /mnt/etc/nixos/modules || error_exit "Failed to create modules directory"
mkdir -p /mnt/etc/nixos/private || error_exit "Failed to create private directory"
mkdir -p /mnt/etc/nixos/home || error_exit "Failed to create home directory"
mkdir -p /mnt/etc/nixos/private-example || error_exit "Failed to create private-example directory"

# Copy the selected configuration as configuration.nix (FOLLOW SYMLINKS WITH -L)
cp -L /etc/nixos/$CONFIG_FILE /mnt/etc/nixos/configuration.nix || error_exit "Failed to copy $CONFIG_FILE"

# Copy both config variants for future use (FOLLOW SYMLINKS WITH -L)
cp -L /etc/nixos/configuration-bios.nix /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/configuration-uefi.nix /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/iso-config.nix /mnt/etc/nixos/ 2>/dev/null || true

if [ -d /etc/nixos/modules ] && [ "$(ls -A /etc/nixos/modules)" ]; then
    cp -rL /etc/nixos/modules/* /mnt/etc/nixos/modules/ || error_exit "Failed to copy modules directory"
    echo "✓ Copied modules directory"
else
    echo "⚠ No modules directory found - creating empty"
fi

# Copy private directory - prioritize existing backup, fall back to examples
if [ -d /etc/nixos/private ] && [ "$(ls -A /etc/nixos/private)" ]; then
    cp -rL /etc/nixos/private/* /mnt/etc/nixos/private/ || error_exit "Failed to copy private directory"
    echo "✓ Copied private directory (from backup)"
elif [ -d /etc/nixos/private-example ] && [ "$(ls -A /etc/nixos/private-example)" ]; then
    cp -rL /etc/nixos/private-example/* /mnt/etc/nixos/private/ || error_exit "Failed to copy private-example to private directory"
    echo "✓ Copied private-example files to private directory (fresh install)"
else
    echo "⚠ No private or private-example directory found - creating empty private directory"
fi

# Ensure private-example directory exists for reference
if [ -d /etc/nixos/private-example ] && [ "$(ls -A /etc/nixos/private-example)" ]; then
    echo "Copying private-example templates for reference..."
    cp -rL /etc/nixos/private-example/* /mnt/etc/nixos/private-example/ || error_exit "Failed to copy private-example templates"

    # Verify the copy worked
    if [ ! -f /mnt/etc/nixos/private-example/README.md ]; then
        error_exit "private-example templates missing after copy (README.md not found)"
    fi

    echo "✓ private-example templates copied successfully"
else
    echo "⚠ No private-example directory found in ISO"
fi

if [ -d /etc/nixos/home ] && [ "$(ls -A /etc/nixos/home)" ]; then
    cp -rL /etc/nixos/home/* /mnt/etc/nixos/home/ || error_exit "Failed to copy home directory"
    echo "✓ Copied home directory"
else
    echo "⚠ No home directory found - creating empty"
fi

cp -L /etc/nixos/build-iso.sh /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/install-nixos.sh /mnt/etc/nixos/ 2>/dev/null || true
cp -L /etc/nixos/.gitignore /mnt/etc/nixos/ 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════
# GENERATE HARDWARE CONFIG
# ═══════════════════════════════════════════════════════════════════════════
echo "Generating hardware configuration..."
nixos-generate-config --root /mnt || error_exit "Failed to generate hardware configuration"

# ═══════════════════════════════════════════════════════════════════════════
# INSTALL
# ═══════════════════════════════════════════════════════════════════════════
echo ""
echo "Installing NixOS (this may take several minutes)..."
echo ""

nixos-install --no-root-passwd || error_exit "NixOS installation failed"

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
echo "🔀 BRANCH NOTE: VM vs Main Branch Service States"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "The MAIN branch (production) has most services ENABLED by default."
echo "The VM branch (testing/repo clone) has several services DISABLED for clean testing."
echo ""
echo "If you installed from the VM branch or cloned the repo, these services"
echo "are DISABLED and need to be manually enabled in /etc/nixos/modules/services.nix:"
echo ""
echo "  DISABLED in VM branch (enable = false):"
echo "    - Tailscale      (VPN mesh network)"
echo "    - Vaultwarden    (Password manager)"
echo "    - SearX          (Self-hosted search)"
echo "    - Nextcloud      (Private cloud storage)"
echo "    - Linkwarden     (Bookmark manager - systemd service)"
echo ""
echo "  To enable a service:"
echo "    1. Edit /etc/nixos/modules/services.nix"
echo "    2. Find the service section and change: enable = false; to enable = true;"
echo "    3. For Linkwarden (systemd service), remove the 'enable = false;' line"
echo "    4. Configure required secrets (see sections below)"
echo "    5. Rebuild: sudo nixos-rebuild switch"
echo ""
echo "  DISABLED in BOTH branches:"
echo "    - Gitea          (Git hosting - configured but disabled, enabled in nixos2-config repo)"
echo ""
echo "If you installed from the pre-built ISO (main branch), most services"
echo "are already enabled - just configure the required secrets below."
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "💾 BACKUPS: Configure Restic Password"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "By default, only system configuration backups are enabled."
echo ""
echo "REQUIRED - Set Restic backup password:"
echo "  1. Generate a strong password:"
echo "     openssl rand -base64 32"
echo ""
echo "  2. Save it securely:"
echo "     echo 'YOUR_GENERATED_PASSWORD' | sudo tee /etc/nixos/private/restic-password"
echo "     sudo chmod 600 /etc/nixos/private/restic-password"
echo ""
echo "  3. Rebuild to enable backups:"
echo "     sudo nixos-rebuild switch"
echo ""
echo "  4. ⚠️  IMPORTANT: Store this password somewhere safe (NOT on this server)!"
echo "     You'll need it to restore backups."
echo ""
echo "Currently enabled backup:"
echo "  - System configs (/etc/nixos/private) - runs daily at 03:15"
echo ""
echo "To enable additional backups:"
echo ""
echo "  Nextcloud database backup (when Nextcloud is enabled):"
echo "    Uncomment 'nextcloud-db' section in /etc/nixos/modules/backups.nix"
echo "    Runs daily at 02:15, keeps 7 daily/4 weekly/12 monthly"
echo ""
echo "  Vaultwarden backup (when Vaultwarden is enabled):"
echo "    Uncomment 'vaultwarden' section in /etc/nixos/modules/backups.nix"
echo "    Runs hourly, keeps 7 daily/4 weekly/12 monthly"
echo ""
echo "Backup location: /var/local/backups/restic/"
echo ""
echo "To sync backups offsite:"
echo "  - Configure Syncthing in /etc/nixos/private/syncthing-devices.nix"
echo "  - Share folder: /var/local/backups/"
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
echo "═══════════════════════════════════════════════════════════════════════════"
echo "☁️  CONFIGURE: Nextcloud (Private Cloud Storage)"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Nextcloud status by branch:"
echo "  - MAIN branch (pre-built ISO): ENABLED - configure secrets below"
echo "  - VM branch (repo clone): DISABLED - enable in services.nix first"
echo ""
echo "⚠️  CRITICAL SECURITY WARNING:"
echo "    The default configuration is INSECURE and designed for LOCAL/TAILSCALE"
echo "    access ONLY. It uses HTTP without encryption and has these protections"
echo "    DISABLED:"
echo "      - auth.bruteforce.protection.enabled = false"
echo "      - ratelimit.protection.enabled = false"
echo ""
echo "    🚨 IF YOU PLAN TO EXPOSE NEXTCLOUD TO THE INTERNET:"
echo "       1. Enable HTTPS with proper SSL certificates"
echo "       2. Change auth.bruteforce.protection.enabled = true"
echo "       3. Change ratelimit.protection.enabled = true"
echo "       4. Review Nextcloud security hardening documentation"
echo ""
echo "    DO NOT expose this default config to the internet - IT IS NOT SECURE AND WOULD BE EASILY HACKED!"
echo ""
echo "To enable Nextcloud (local/Tailscale access only):"
echo ""
echo "  1. Prepare external storage (if using external drive):"
echo "     lsblk  # Find your drive"
echo "     sudo mkfs.ext4 -L nextcloud-data /dev/sdX1  # Format (DESTRUCTIVE!)"
echo "     sudo blkid /dev/sdX1  # Get UUID"
echo ""
echo "  2. Add mount point to /etc/nixos/hardware-configuration.nix:"
echo "     fileSystems.\"/mnt/nextcloud-data\" = {"
echo "       device = \"/dev/disk/by-uuid/YOUR-UUID-HERE\";"
echo "       fsType = \"ext4\";"
echo "       options = [ \"nofail\" ];"
echo "     };"
echo ""
echo "  3. Create admin password file:"
echo "     openssl rand -base64 32 | sudo tee /etc/nixos/private/nextcloud-admin-pass"
echo "     sudo chmod 600 /etc/nixos/private/nextcloud-admin-pass"
echo ""
echo "  4. If using VM branch, enable Nextcloud:"
echo "     - Edit /etc/nixos/modules/services.nix"
echo "     - Change: services.nextcloud.enable = true;"
echo "     (Main branch: already enabled, skip this step)"
echo ""
echo "  5. Rebuild and reboot:"
echo "     sudo nixos-rebuild switch"
echo "     sudo reboot"
echo ""
echo "  6. Access Nextcloud:"
echo "     - Local: http://nextcloud.home:8280"
echo "     - Tailscale: http://nextcloud.vpn:8280"
echo "     - Username: root"
echo "     - Password: (from /etc/nixos/private/nextcloud-admin-pass)"
echo ""
echo "  7. Add DNS rewrite in AdGuard Home:"
echo "     nextcloud.home -> YOUR_IP"
echo ""
echo "To disable Nextcloud:"
echo "  Set services.nextcloud.enable = false; in services.nix"
echo ""
echo ""
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "🔐 CONFIGURE: Vaultwarden (Self-Hosted Password Manager)"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Vaultwarden status by branch:"
echo "  - MAIN branch (pre-built ISO): ENABLED - configure secrets below"
echo "  - VM branch (repo clone): DISABLED - enable in services.nix first"
echo ""
echo "⚠️  IMPORTANT: Vaultwarden uses Tailscale Funnel for HTTPS access."
echo "    This exposes your password manager to the PUBLIC INTERNET."
echo "    Ensure you:"
echo "      - Use a STRONG master password"
echo "      - Enable 2FA immediately after first login"
echo "      - Disable signups after creating your account"
echo ""
echo "To enable Vaultwarden:"
echo ""
echo "  1. Generate admin token:"
echo "     nix-shell -p openssl --run \"openssl rand -base64 48\""
echo ""
echo "  2. Create environment file:"
echo "     sudo nano /etc/nixos/private/vaultwarden.env"
echo "     Add: ADMIN_TOKEN='your_generated_token_here'"
echo "     sudo chmod 600 /etc/nixos/private/vaultwarden.env"
echo ""
echo "  3. Add Tailscale hostname to secrets:"
echo "     sudo nano /etc/nixos/private/secrets.nix"
echo "     Add: tailscaleHostname = \"nixos.tailXXXXXX.ts.net\";"
echo "     (Get your hostname from: tailscale status)"
echo ""
echo "  4. Enable Tailscale Funnel (requires admin console setup):"
echo "     - Go to: https://login.tailscale.com/admin/settings"
echo "     - Click 'Access controls' -> 'JSON editor'"
echo "     - Add to your ACL:"
echo "       \"nodeAttrs\": ["
echo "         {"
echo "           \"target\": [\"*\"],"
echo "           \"attr\": [\"funnel\"]"
echo "         }"
echo "       ]"
echo "     - Save the ACL"
echo "     - Run: sudo tailscale funnel --bg --https=443 http://127.0.0.1:8222"
echo ""
echo "  5. If using VM branch, enable Vaultwarden:"
echo "     sudo nano /etc/nixos/modules/services.nix"
echo "     Change: services.vaultwarden.enable = true;"
echo "     (Main branch: already enabled, skip this step)"
echo ""
echo "  6. Rebuild and access:"
echo "     sudo nixos-rebuild switch"
echo "     Access at: https://nixos.tailXXXXXX.ts.net"
echo ""
echo "  7. IMMEDIATELY after first login:"
echo "     - Enable 2FA (Settings -> Security -> Two-step Login)"
echo "     - Save recovery code somewhere safe (NOT in Vaultwarden!)"
echo "     - Change SIGNUPS_ALLOWED = false in services.nix"
echo "     - Rebuild: sudo nixos-rebuild switch"
echo ""
echo "To disable Vaultwarden:"
echo "  Set services.vaultwarden.enable = false; in services.nix"
echo ""
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "🏠 CONFIGURE: Homepage Dashboard (Service Launchpad)"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Homepage provides a clean dashboard with links to all your services."
echo ""
echo "To access Homepage:"
echo ""
echo "  1. Add DNS rewrite in AdGuard Home:"
echo "     Go to Filters → DNS rewrites, add:"
echo "     home.home → YOUR_IP (e.g., 192.168.1.154)"
echo ""
echo "  2. Access the dashboard:"
echo "     http://home.home"
echo ""
echo "  3. (Optional) Customize theme:"
echo "     Edit /etc/nixos/modules/homepage.nix"
echo "     Change color: slate, blue, indigo, cyan, etc."
echo "     sudo nixos-rebuild switch"
echo ""
echo "Homepage shows up/down status for all enabled services and provides"
echo "quick links to access them. Services are automatically shown/hidden"
echo "based on your configuration in services.nix."
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ Installation complete! Review the output above."
echo "Press any key to reboot..."
echo "═══════════════════════════════════════════════════════════════"
read -n 1 -s -r
sleep 10
reboot

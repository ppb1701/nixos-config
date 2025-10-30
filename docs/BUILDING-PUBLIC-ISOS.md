# Building Public ISOs

This guide explains how to build sanitized ISOs for public distribution without exposing your private configuration.

## Why Separate Public and Private ISOs?

### Private ISO (for you)

- Contains all your device IDs (Syncthing)
- Contains your network configuration
- Contains your customizations
- For disaster recovery

### Public ISO (for sharing)

- No device IDs
- Generic configuration
- Example templates
- For others to use as starting point

## Method 1: Clean Checkout Build

The simplest and safest method.

### Steps

1. **Clone your public repository:**

   ```bash
   # In a temporary directory
   cd /tmp
   git clone https://github.com/ppb1701/nixos-adguard-home
   cd nixos-adguard-home
   ```

2. **Verify no private config:**

   ```bash
   # Should not exist or should be empty
   ls -la private/syncthing-devices.nix

   # Should only have .example file
   ls -la private/
   ```

3. **Build the ISO:**

   ```bash
   ./build-iso.sh
   ```

   **Result:** ISO contains:
   - All public configuration
   - Example templates
   - No device IDs
   - No private information

4. **Share the ISO:**

   ```bash
   # Copy to public location
   cp nixos-adguard-home.iso ~/public-isos/

   # Or upload to GitHub Releases
   # Or share via other means
   ```

## Method 2: Dedicated Builder VM

More automated, guaranteed clean builds.

### Initial Setup

**Create minimal NixOS VM:**

Specs:
- 2 CPU cores
- 4GB RAM
- 20GB disk
- NAT networking

**Install minimal NixOS:**

```nix
# /etc/nixos/configuration.nix on builder VM
{ config, pkgs, ... }:

{
  boot.loader.grub.device = "/dev/sda";

  networking = {
    hostName = "iso-builder";
    useDHCP = true;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  users.users.builder = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "builder";  # Change this!
  };

  system.stateVersion = "25.05";
}
```

**Install and shutdown:**

```bash
sudo nixos-install
sudo shutdown -h now
```

### Building ISOs

**Manual build:**

```bash
# 1. Start VM
# (via VirtualBox/VMware GUI or CLI)

# 2. SSH in
ssh builder@iso-builder

# 3. Clone and build
cd ~
rm -rf nixos-adguard-home
git clone https://github.com/ppb1701/nixos-adguard-home
cd nixos-adguard-home
./build-iso.sh

# 4. Copy ISO out (via shared folder or SCP)
# Via SCP:
scp nixos-adguard-home.iso yourhost:~/Downloads/

# 5. Shutdown
sudo shutdown -h now
```

**Automated build script:**

Create `build-public-iso.sh` on your host:

```bash
#!/usr/bin/env bash
set -e

VM_NAME="iso-builder"
VM_USER="builder"
VM_HOST="iso-builder"
SHARED_FOLDER="/path/to/shared/folder"
REPO_URL="https://github.com/ppb1701/nixos-adguard-home"

echo "==> Starting builder VM..."
VBoxManage startvm "$VM_NAME" --type headless

echo "==> Waiting for VM to boot..."
sleep 30

echo "==> Building ISO..."
ssh "$VM_USER@$VM_HOST" << EOF
  set -e
  cd ~
  rm -rf nixos-adguard-home
  git clone $REPO_URL
  cd nixos-adguard-home
  ./build-iso.sh
  cp nixos-adguard-home.iso /media/sf_shared/ || true
EOF

echo "==> Copying ISO..."
# If shared folder didn't work, use SCP
if [ ! -f "$SHARED_FOLDER/nixos-adguard-home.iso" ]; then
  scp "$VM_USER@$VM_HOST:~/nixos-adguard-home/nixos-adguard-home.iso" "$SHARED_FOLDER/"
fi

echo "==> Shutting down VM..."
ssh "$VM_USER@$VM_HOST" "sudo shutdown -h now"

echo "==> Done! ISO is in $SHARED_FOLDER"
```

**Usage:**

```bash
chmod +x build-public-iso.sh
./build-public-iso.sh
# Go make coffee ☕
# Come back to fresh public ISO!
```

## Method 3: GitHub Actions (CI/CD)

Fully automated builds on every release.

### Setup

Create `.github/workflows/build-iso.yml`:

```yaml
name: Build Public ISO

on:
  release:
    types: [created]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install Nix
        uses: cachix/install-nix-action@v20
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Build ISO
        run: |
          ./build-iso.sh

      - name: Get ISO path
        id: iso
        run: |
          ISO_PATH=$(find /nix/store -name "*.iso" -type f -mtime -1 | head -n 1)
          echo "path=$ISO_PATH" >> $GITHUB_OUTPUT

      - name: Upload ISO to Release
        if: github.event_name == 'release'
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ${{ steps.iso.outputs.path }}
          asset_name: nixos-adguard-home-${{ github.event.release.tag_name }}.iso
          asset_content_type: application/octet-stream

      - name: Upload ISO as Artifact
        if: github.event_name != 'release'
        uses: actions/upload-artifact@v3
        with:
          name: nixos-adguard-home-iso
          path: ${{ steps.iso.outputs.path }}
```

### Usage

**Create a release:**

```bash
git tag v1.0.0
git push origin v1.0.0

# Go to GitHub → Releases → Create Release
# Tag: v1.0.0
# Title: "Version 1.0.0"
# Description: "Initial public release"
# Publish release
```

GitHub Actions will:
1. Automatically build ISO
2. Upload to release assets
3. Available for download

**Manual trigger:**

Go to GitHub → Actions → Build Public ISO → Run workflow

## Method 4: Sanitize Before Building

Build on your configured system but remove private data first.

### Steps

1. **Backup private config:**

   ```bash
   cd /etc/nixos
   cp private/syncthing-devices.nix private/syncthing-devices.nix.backup
   ```

2. **Remove private config:**

   ```bash
   rm private/syncthing-devices.nix
   ```

3. **Build ISO:**

   ```bash
   ./build-iso.sh
   ```

4. **Restore private config:**

   ```bash
   mv private/syncthing-devices.nix.backup private/syncthing-devices.nix
   ```

5. **Verify ISO is clean:**

   ```bash
   # Mount ISO and check
   mkdir /tmp/iso-mount
   sudo mount -o loop nixos-adguard-home.iso /tmp/iso-mount
   ls -la /tmp/iso-mount/etc/nixos-config/private/
   # Should not contain syncthing-devices.nix
   sudo umount /tmp/iso-mount
   ```

### Automated Script

Create `build-public-iso-safe.sh`:

```bash
#!/usr/bin/env bash
set -e

PRIVATE_CONFIG="private/syncthing-devices.nix"
BACKUP_CONFIG="${PRIVATE_CONFIG}.backup"

echo "==> Backing up private configuration..."
if [ -f "$PRIVATE_CONFIG" ]; then
  cp "$PRIVATE_CONFIG" "$BACKUP_CONFIG"
  rm "$PRIVATE_CONFIG"
  echo "Private config backed up and removed"
fi

echo "==> Building public ISO..."
./build-iso.sh

echo "==> Restoring private configuration..."
if [ -f "$BACKUP_CONFIG" ]; then
  mv "$BACKUP_CONFIG" "$PRIVATE_CONFIG"
  echo "Private config restored"
fi

echo "==> Done! Public ISO built successfully"
echo "ISO location: nixos-adguard-home.iso"
```

**Usage:**

```bash
chmod +x build-public-iso-safe.sh
./build-public-iso-safe.sh
```

## Verifying Public ISOs

Always verify your public ISO doesn't contain private information.

### Manual Verification

```bash
# Mount the ISO
mkdir /tmp/iso-check
sudo mount -o loop nixos-adguard-home.iso /tmp/iso-check

# Check for private config
ls -la /tmp/iso-check/etc/nixos-config/private/
# Should only show .example files

# Check for device IDs
grep -r "ABCDEFG-1234567" /tmp/iso-check/etc/nixos-config/ || echo "No device IDs found (good!)"

# Check for your personal info
grep -r "your-actual-username" /tmp/iso-check/etc/nixos-config/ || echo "No personal info found (good!)"

# Unmount
sudo umount /tmp/iso-check
```

### Automated Verification Script

Create `verify-public-iso.sh`:

```bash
#!/usr/bin/env bash
set -e

ISO_FILE="nixos-adguard-home.iso"
MOUNT_POINT="/tmp/iso-verify"

if [ ! -f "$ISO_FILE" ]; then
  echo "Error: $ISO_FILE not found"
  exit 1
fi

echo "==> Mounting ISO..."
mkdir -p "$MOUNT_POINT"
sudo mount -o loop "$ISO_FILE" "$MOUNT_POINT"

echo "==> Checking for private configuration..."
if [ -f "$MOUNT_POINT/etc/nixos-config/private/syncthing-devices.nix" ]; then
  echo "❌ FAIL: Private Syncthing config found!"
  FAILED=1
else
  echo "✅ PASS: No private Syncthing config"
fi

echo "==> Checking for device IDs..."
if grep -r "ABCDEFG-1234567" "$MOUNT_POINT/etc/nixos-config/" > /dev/null 2>&1; then
  echo "❌ FAIL: Device IDs found!"
  FAILED=1
else
  echo "✅ PASS: No device IDs found"
fi

echo "==> Checking for personal usernames..."
if grep -r "ppb1701" "$MOUNT_POINT/etc/nixos-config/" > /dev/null 2>&1; then
  echo "⚠️  WARNING: Personal username found (might be intentional)"
else
  echo "✅ PASS: No personal usernames"
fi

echo "==> Unmounting ISO..."
sudo umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

if [ -n "$FAILED" ]; then
  echo ""
  echo "❌ Verification FAILED - Do not distribute this ISO!"
  exit 1
else
  echo ""
  echo "✅ Verification PASSED - ISO is safe to distribute"
  exit 0
fi
```

**Usage:**

```bash
chmod +x verify-public-iso.sh
./verify-public-iso.sh
```

## Distribution

### GitHub Releases

1. Create release on GitHub
2. Upload ISO as release asset
3. Add release notes

**Example release notes:**

```
## NixOS AdGuard Home Server v1.0.0

A fully declarative AdGuard Home DNS server configuration for NixOS.

### What's Included

- AdGuard Home with 12 curated filter lists
- Automated installation script
- Modular configuration structure
- Optional Syncthing support
- Complete documentation

### Installation

1. Download `nixos-adguard-home-v1.0.0.iso`
2. Flash to USB drive
3. Boot and run: `sudo /etc/nixos-config/install-nixos.sh`
4. Follow the prompts

### Documentation

See the [README](https://github.com/ppb1701/nixos-adguard-home) for complete setup instructions.

### Checksums

SHA256: `abc123...`
```

### Other Distribution Methods

**Direct download:**
- Host on your own server
- Share via cloud storage (Mega, Google Drive, etc.)

**Torrent:**
- Create torrent file
- Seed from your server
- Distribute magnet link

**Package repositories:**
- Submit to NixOS community repos
- Create Flake for easy installation

## Maintaining Two Versions

### Your Workflow

**Private ISO (for you):**

```bash
# On your configured system
./build-iso.sh
# Keep this ISO private
# Use for disaster recovery
```

**Public ISO (for sharing):**

```bash
# Use one of the methods above
./build-public-iso-safe.sh
# Or use builder VM
# Or use GitHub Actions

# Verify before sharing
./verify-public-iso.sh
```

### Version Naming

**Private ISOs:**

```
nixos-adguard-home-private-2025-01-30.iso
nixos-adguard-home-backup-v2.iso
```

**Public ISOs:**

```
nixos-adguard-home-v1.0.0.iso
nixos-adguard-home-v1.1.0.iso
```

### Storage

**Private ISOs:**
- Keep on encrypted backup drive
- Don't upload to public locations
- Use for personal disaster recovery

**Public ISOs:**
- GitHub Releases
- Your website
- Public cloud storage
- Share freely

## Best Practices

- Always verify public ISOs before distribution
- Use dedicated builder VM for guaranteed clean builds
- Automate with CI/CD for consistency
- Document what's included in release notes
- Provide checksums for verification
- Keep private ISOs separate from public ones
- Test public ISOs in clean VM before sharing

## Troubleshooting

### ISO Contains Private Data

**Problem:** Verification script found private information

**Solution:**
1. Don't distribute this ISO
2. Delete it
3. Use clean checkout method or builder VM
4. Rebuild and verify again

### Builder VM Won't Start

**Problem:** VM fails to boot

**Solution:**
- Check VM settings (RAM, disk space)
- Verify ISO is valid
- Check virtualization is enabled in BIOS
- Try different VM software

### GitHub Actions Build Fails

**Problem:** CI/CD build fails

**Solution:**
- Check workflow logs
- Verify build script works locally
- Check Nix installation step
- Ensure sufficient runner resources

## Getting Help

- **This repo's issues:** https://github.com/ppb1701/nixos-adguard-home/issues
- **NixOS Discourse:** https://discourse.nixos.org/
- **Mastodon:** [@ppb1701@ppb.social](https://ppb.social/@ppb1701)

#!/usr/bin/env bash
set -e

echo "Building custom NixOS ISO..."
echo "This will take 10-20 minutes depending on your system."
echo ""

# Clean previous builds
rm -f result nixos-adguard-home.iso

# Build the ISO
echo "[1/3] Building ISO..."
nix-shell -p nixos-generators --run \
  "nixos-generate -f iso -c ./iso-config.nix"

# Find the ISO in the Nix store
echo "[2/3] Locating ISO..."
ISO_PATH=$(find /nix/store -name "*nixos*.iso" -type f 2>/dev/null | grep -v "\.drv" | tail -n 1)

if [ -z "$ISO_PATH" ]; then
  echo "❌ Error: Could not find built ISO in /nix/store"
  exit 1
fi

echo "Found ISO: $ISO_PATH"

# Copy it to current directory with a friendly name
echo "[3/3] Copying ISO..."
cp "$ISO_PATH" ./nixos-adguard-home.iso

# Report success
ISO_SIZE=$(du -h nixos-adguard-home.iso | cut -f1)
echo ""
echo "✅ Build complete!"
echo ""
echo "ISO: nixos-adguard-home.iso"
echo "Size: $ISO_SIZE"
echo ""
echo "Next steps:"
echo "1. Copy ISO to host machine"
echo "2. Flash to USB: sudo dd if=nixos-adguard-home.iso of=/dev/sdX bs=4M status=progress"
echo "3. Boot from USB and run: sudo /etc/nixos-config/install-nixos.sh"


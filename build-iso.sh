#!/usr/bin/env bash
# build-iso.sh
# Builds a custom NixOS ISO with your AdGuard Home configuration
#
# Usage: ./build-iso.sh
#
# Requirements:
# - NixOS system (or VM)
# - nixos-generators (will be installed automatically)
# - Internet connection
#
# Output: ./result/iso/nixos-*.iso

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║   Building Custom NixOS ISO           ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if iso-config.nix exists
if [ ! -f "iso-config.nix" ]; then
    echo "Error: iso-config.nix not found!"
    echo "Make sure you're in the /etc/nixos directory."
    exit 1
fi

# Clean previous builds
echo -e "${GREEN}[1/3] Cleaning previous builds...${NC}"
rm -rf result

# Build the ISO
echo -e "${GREEN}[2/3] Building ISO (this will take 10-20 minutes)...${NC}"
nix-shell -p nixos-generators --run \
  "nixos-generate -f iso -c ./iso-config.nix"

# Get ISO info
echo -e "${GREEN}[3/3] Build complete!${NC}"
echo ""

if [ -d "result/iso" ]; then
    ISO=$(ls result/iso/*.iso 2>/dev/null | head -n1)
    if [ -n "$ISO" ]; then
        SIZE=$(du -h "$ISO" | cut -f1)
        echo "✅ ISO built successfully!"
        echo "📦 Location: $ISO"
        echo "💾 Size: $SIZE"
        echo ""

        # Optional: Copy to shared folder
        if [ -d "/mnt/shared" ]; then
            echo "📋 Copying to shared folder..."
            cp "$ISO" /mnt/shared/
            echo "✅ ISO available on host machine at /mnt/shared/"
        else
            echo "💡 To copy to host machine:"
            echo "   scp -P 2222 $ISO user@host:~/Downloads/"
        fi
    else
        echo "⚠️  Build completed but ISO not found in expected location."
        echo "Check ./result/ directory."
    fi
else
    echo "⚠️  Build completed but result directory not found."
    ls -la result/ 2>/dev/null || echo "No result directory."
fi

echo ""
echo "Next steps:"
echo "1. Copy ISO to host machine"
echo "2. Flash to USB: sudo dd if=nixos-*.iso of=/dev/sdX bs=4M status=progress"
echo "3. Boot from USB and run: sudo /etc/nixos-config/install-nixos.sh"

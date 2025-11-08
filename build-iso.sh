#!/usr/bin/env bash
set -e

echo "Building NixOS custom ISO..."
echo ""

# Build the ISO
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso-config.nix

# Find the ISO
ISO_PATH=$(find result/iso -name "*.iso" | head -n 1)

if [ -z "$ISO_PATH" ]; then
    echo "Error: ISO not found in result/iso/"
    exit 1
fi

echo ""
echo "ISO built successfully!"
echo "Location: $ISO_PATH"
echo ""
echo "Copy to Ventoy USB with:"
echo "sudo cp $ISO_PATH /path/to/ventoy/"

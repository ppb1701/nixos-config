#!/usr/bin/env bash
set -e

echo "Building custom NixOS ISO..."

# Clean previous builds
rm -rf result result-* *.iso

# Build ISO
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage \
  -I nixos-config=./iso-config.nix

# Copy and rename result
if [ -f result/iso/*.iso ]; then
  cp result/iso/*.iso ./nixos-config.iso
  echo "ISO built successfully: nixos-config.iso"
  ls -lh nixos-config.iso
else
  echo "Error: ISO file not found"
  exit 1
fi

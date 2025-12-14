#!/usr/bin/env bash
# setup-config.sh - Extract configuration files to /etc/nixos/

set -e

TARBALL="/nix/store-contents/nixos-config.tar.gz"
TARGET_DIR="/etc/nixos"

echo "Setting up NixOS configuration files..."

# Check if tarball exists
if [ ! -f "$TARBALL" ]; then
    echo "Error: Configuration tarball not found at $TARBALL"
    exit 1
fi

# Extract tarball
echo "Extracting configuration files..."
sudo tar -xzf "$TARBALL" -C "$TARGET_DIR"

echo "Configuration files extracted successfully!"
echo "Files are now available in $TARGET_DIR"
ls -la "$TARGET_DIR"
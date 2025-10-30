
#!/usr/bin/env bash
set -e

echo "Building custom NixOS ISO..."

# Clean previous builds
rm -rf result result-* *.iso

# Create a clean temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy only tracked Git files
git archive HEAD | tar -x -C "$TEMP_DIR"

# Build ISO using the clean copy
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage \
  -I nixos-config="$TEMP_DIR/iso-config.nix"

# Copy result
if [ -f result/iso/*.iso ]; then
  cp result/iso/*.iso ./nixos-config.iso
  echo "ISO built successfully: nixos-config.iso"
  ls -lh nixos-config.iso
else
  echo "Error: ISO file not found"
  exit 1
fi
#!/usr/bin/env bash

echo "=========================================="
echo "  NixOS System Cleanup Script"
echo "=========================================="
echo ""

# Show current disk usage
echo "Current disk usage:"
df -h / /nix/store /tmp 2>/dev/null || df -h /
echo ""

# Show Nix store size before cleanup
echo "Nix store size before cleanup:"
du -sh /nix/store 2>/dev/null || echo "Unable to calculate /nix/store size"
echo ""

read -p "Continue with cleanup? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "  Step 1: Removing old system generations"
echo "=========================================="
# Delete all generations older than 7 days
sudo nix-collect-garbage --delete-older-than 7d

echo ""
echo "=========================================="
echo "  Step 2: Running full garbage collection"
echo "=========================================="
# Remove all unreachable store paths
sudo nix-collect-garbage -d

echo ""
echo "=========================================="
echo "  Step 3: Optimizing Nix store"
echo "=========================================="
# Hard-link identical files to save space
sudo nix-store --optimise

echo ""
echo "=========================================="
echo "  Step 4: Cleaning temporary files"
echo "=========================================="
# Clean /tmp (safe to do)
sudo rm -rf /tmp/* 2>/dev/null || echo "Some /tmp files in use, skipped"

echo ""
echo "=========================================="
echo "  Step 5: Removing result symlinks"
echo "=========================================="
# Find and remove all 'result' symlinks in common locations
find /etc/nixos -name "result*" -type l -delete 2>/dev/null || true
find ~ -name "result*" -type l -delete 2>/dev/null || true

echo ""
echo "=========================================="
echo "  Cleanup Complete!"
echo "=========================================="
echo ""

# Show disk usage after cleanup
echo "Disk usage after cleanup:"
df -h / /nix/store /tmp 2>/dev/null || df -h /
echo ""

# Show Nix store size after cleanup
echo "Nix store size after cleanup:"
du -sh /nix/store 2>/dev/null || echo "Unable to calculate /nix/store size"
echo ""

echo "Space freed!"

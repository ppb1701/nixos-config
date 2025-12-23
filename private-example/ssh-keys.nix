# EXAMPLE FILE - DO NOT USE AS-IS
# Copy to /etc/nixos/private/ssh-keys.nix and add your SSH public keys
# Generate keys with: ssh-keygen -t ed25519 -C "your-email@example.com"
{
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAEXAMPLEKEYDONOTUSE <mailto:your-email@example.com>"
  ];
}

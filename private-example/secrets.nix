# EXAMPLE FILE - DO NOT USE AS-IS
# Copy to /etc/nixos/private/secrets.nix and fill in real passwords
# Generate strong passwords with: openssl rand -base64 32

{
  tailscaleIP = "Your_Tailscale_IP";
  tailscaleHostname = "Your_Tailscale_Hostname";
  grafanaPassword = "CHANGE_ME_TO_STRONG_PASSWORD";
}

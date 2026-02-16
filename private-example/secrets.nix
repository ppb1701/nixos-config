# EXAMPLE FILE - DO NOT USE AS-IS
# Copy to /etc/nixos/private/secrets.nix and fill in real passwords
# Generate strong passwords with: openssl rand -base64 32

{
  tailscaleIP = "Your_Tailscale_IP";
  tailscaleHostname = "Your_Tailscale_Hostname";
  tailscaleIP2 = "Your_Tailscale_IP2";
  tailscaleHostname2 = "Your_Tailscale_Hostname2";
  grafanaPassword = "CHANGE_ME_TO_STRONG_PASSWORD";
  searxSecret = "CHANGE_ME_TO_RANDOM_SECRET";  # openssl rand -hex 32
  linkwardenNextAuthSecret = "CHANGE_ME_TO_STRONG_PASSWORD";  # openssl rand -base64 32
  linkwardenDbPassword = "CHANGE_ME_TO_STRONG_PASSWORD";  # openssl rand -hex 32
}

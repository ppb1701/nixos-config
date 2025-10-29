cat > README.md << 'EOF'
# NixOS AdGuard Home Server Configuration

Declarative NixOS configuration for a headless AdGuard Home DNS server.

## Features

- **AdGuard Home**: Network-wide ad blocking
- **Client Identification**: See device names, not just IPs
- **RustDesk**: Headless remote access (LAN-only)
- **Home Manager**: Declarative user environment
- **Modular Structure**: Easy to maintain and extend

## Quick Start

### Initial Installation

1. Boot from NixOS installer USB
2. Install NixOS with basic config
3. Clone this repo:
   ```bash
   git clone https://github.com/yourusername/your-repo.git /etc/nixos
   cd /etc/nixos

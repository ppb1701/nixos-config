# NixOS AdGuard Home Server

A fully declarative, reproducible AdGuard Home DNS server built with NixOS. This configuration is designed to be:

- **Declarative:** Everything defined in code
- **Reproducible:** Rebuild identical systems anytime
- **Disaster-proof:** Complete recovery in 20 minutes
- **Privacy-focused:** Ad-blocking DNS with local control

## ⚠️ Security Warning

This configuration uses a **temporary, publicly-known password** for initial convenience:

**Default Password:** `nixos`

### Why This Approach?

- Keeps passwords out of public GitHub repositories
- Allows you to set your own secure password after installation
- Prevents being locked out of a freshly installed system

### CRITICAL: Change Password Immediately

**After installation, you MUST:**

1. SSH into the system: `ssh ppb1701@YOUR_IP` (password: `nixos`)
2. Change your password: `passwd`
3. Edit `/etc/nixos/configuration.nix`:
   - Remove: `initialPassword = "nixos";`
   - Change: `security.sudo.wheelNeedsPassword = true;`
4. Rebuild: `sudo nixos-rebuild switch`

**DO NOT expose this system to the internet before changing the password!**

## Blog Series

This repository is the companion code for my blog series:

**Building a Resilient Home Server Series**
https://blog.ppb1701.com/building-a-resilient-home-server-series

**Discussion:** [@ppb1701@ppb.social](https://ppb.social/@ppb1701)

## Repository Branches

This repository has two main branches serving different purposes:

- **`main`:** Production server configuration - battle-tested and running on physical hardware
  - Most services are **enabled** and ready to configure
- **`vm`:** Testing branch - for VM testing and development of new features
  - Several services are **disabled** for clean testing environments

**Services disabled in VM branch (enabled in main):**
- Tailscale (VPN mesh network)
- Vaultwarden (Password manager)
- SearX (Self-hosted search)
- Nextcloud (Private cloud storage)
- Linkwarden (Bookmark manager)

**Services disabled in both branches:**
- Gitea (Git hosting - configured but disabled)

If you clone the repo or use the VM branch, enable services by editing `/etc/nixos/modules/services.nix` and changing `enable = false` to `enable = true`, then run `sudo nixos-rebuild switch`.

When deploying to production, use the `main` branch. Use `vm` for testing changes safely before deploying.

## Features

### Core Services

- **AdGuard Home:** Network-wide ad blocking and DNS filtering
  - Configurable upstream DNS (Control D, Quad9)
  - DNSSEC enabled for security
  - Web UI accessible via Nginx reverse proxy (http://adguard.home)
- **Homepage Dashboard:** Centralized service dashboard
  - Auto-discovers enabled services via NixOS module system
  - Real-time CPU, memory, and disk usage widgets
  - Dark theme with organized categories (Network, Services, Monitoring)
  - Web UI accessible at http://home.home
- **Syncthing:** Cross-platform file synchronization
  - Works with Windows, macOS, Linux, Android
  - Private device configuration
  - Secure LAN-only sync
  - Web UI accessible via Nginx reverse proxy (http://syncthing.home)
- **Nextcloud:** Private cloud storage and collaboration platform
  - File sync and sharing with desktop/mobile clients
  - External drive support for large storage
  - Calendar, contacts, and collaborative editing
  - Integrated monitoring and alerting
  - Web UI accessible at http://cloud.home
- **Vaultwarden:** Self-hosted password manager (Bitwarden compatible)
  - Secure password vault with 2FA support
  - Accessible remotely via Tailscale Funnel (HTTPS)
  - Automatic HTTPS certificates
  - Bitwarden client compatibility (desktop, mobile, browser extensions)
  - Accessible at https://nixos.tailXXXXXX.ts.net (your Tailscale hostname)
- **Nginx:** Reverse proxy for clean local URLs
  - Access services via friendly names (adguard.home, syncthing.home, grafana.home, notes.home, etc.)
  - No need to remember port numbers
- **Tailscale:** Secure remote access VPN
  - Access your server from anywhere
  - Zero-config mesh networking
- **SSH Access:** Secure remote management
  - Key-based authentication support
  - Auto-restart on failure
- **NoteDiscovery:** Web-based knowledge base (optional)
  - Full-text search across markdown notes
  - Web UI accessible via Nginx reverse proxy (http://notes.home)
  - Integrates with Syncthing for note synchronization
  - Password-protected with configurable authentication
- **SearX:** Self-hosted metasearch engine
  - Privacy-respecting search aggregating multiple engines
  - Dark theme, autocomplete, image proxy
  - Web UI accessible at http://search.home
- **Linkwarden:** Self-hosted bookmark manager
  - Save, organize, and archive bookmarks
  - Automatic page archiving with screenshots
  - Browser extensions available
  - Web UI accessible at http://links.home

### Backup System

- **Restic Backups:** Automated, encrypted backup system
  - **Vaultwarden:** Hourly backups with service stop/start for SQLite safety
  - **Nextcloud Database:** Daily PostgreSQL dumps at 2:15 AM
  - **Linkwarden:** Daily PostgreSQL dumps + archived pages at 2:40 AM
  - **Private Configs:** Daily backup of `/etc/nixos/private` at 3:15 AM
  - Retention policy: 24 hourly, 7 daily, 4 weekly, 12 monthly
  - All backups stored in `/var/local/backups/restic`

- **Nextcloud Data Synchronization:** For syncing Nextcloud actual data between servers
  - Initial sync via rsync: `rsync -avP -e "ssh -p 2212" /mnt/nextcloud-data/data/ user@host:/mnt/nextcloud-data/nextcloud/`
  - Ongoing sync via Syncthing for continuous replication
  - Provides disaster recovery capability to secondary server

See `docs/SERVICES.md` for detailed backup configuration and restore procedures.

### Monitoring and Alerting Stack

- **Prometheus:** Metrics collection and time-series database
  - 30-day retention, system and service metrics
  - Node, Nginx, Nextcloud, and Blackbox exporters
  - Syncthing metrics monitoring
  - HTTP health checks for services
  - Web UI at http://prometheus.home
- **Grafana:** Beautiful dashboards and visualization
  - Pre-configured Prometheus and Loki data sources
  - Import community dashboards
  - Web UI at http://grafana.home
- **Alertmanager:** Alert routing and notifications
  - Email alerts via Fastmail SMTP
  - Push notifications via ntfy
  - Web UI at http://alertmanager.home
- **Loki + Promtail:** Log aggregation and collection
  - 7-day log retention
  - Query logs through Grafana
  - Systemd journal collection
- **ntfy:** Self-hosted push notifications
  - Instant alerts to mobile/desktop
  - 24-hour message cache
  - Web UI and mobile apps at http://ntfy.home

**Note:** Monitoring configuration is now in its own module (`modules/monitoring.nix`) for better organization.

See `docs/SERVICES.md` and `docs/NEXTCLOUD-SETUP.md` for detailed setup and configuration.

### Desktop Environment

- **LXQT Desktop:** Lightweight desktop environment for VM/local access
  - LightDM display manager with auto-login
  - PipeWire audio support
  - NetworkManager applet for easy network configuration

### Infrastructure Features

- **Modular Configuration:** Services organized in logical modules
  - `services.nix` - Core service configurations (AdGuard, Syncthing, Tailscale, Nginx, Nextcloud, SearX, Linkwarden, NoteDiscovery)
  - `homepage.nix` - Homepage Dashboard (auto-discovers enabled services, system resource widgets)
  - `nginx-virtualhosts.nix` - Nginx reverse proxy virtual hosts (split out for readability)
  - `monitoring.nix` - Complete monitoring stack (Prometheus, Grafana, Alertmanager, Loki, Promtail)
  - `backups.nix` - Restic backup configuration
  - `networking.nix` - Network and firewall settings
  - `system.nix` - System packages, users, desktop
  - `boot-bios.nix` / `boot-uefi.nix` - Boot configurations
- **Private Configuration:** Sensitive data kept out of Git
  - `private/` directory gitignored for security
  - `private-example/` provides templates for required config files
  - Automated installer copies examples to `private/` as starting point
  - Files: `syncthing-secrets.nix`, `ssh-keys.nix`, `secrets.nix`, `alertmanager.env`, `notediscovery-config.*`, `nextcloud-admin-pass`
- **Home Manager:** User environment management
  - Custom ZSH configuration with starship prompt
  - Extensive shell aliases for system management
- **Custom ISO Builder:** Bootable installation images
- **Automated Installation:** Zero-touch deployment script with BIOS/UEFI selection

## Quick Start

### Option 1: Pre-built ISO (Easiest)

**Download the latest ISO:**

https://github.com/ppb1701/nixos-config/releases/tag/nixos

**Install:**

1. Download the ISO from the releases page
2. Flash ISO to USB drive (Rufus on Windows, `dd` on Linux/Mac, or Ventoy)
3. Boot target machine from USB
4. Run: `sudo /etc/nixos-config/install-nixos.sh`
5. Choose UEFI or BIOS boot mode
6. Follow prompts
7. Reboot into your configured system!

### Option 2: Build Your Own ISO

**Build the ISO:**

```bash
git clone https://github.com/ppb1701/nixos-config
cd nixos-config
./build-iso.sh
```

**Install:**

1. Flash ISO to USB drive
2. Boot target machine from USB
3. Run: `sudo /etc/nixos-config/install-nixos.sh`
4. Follow prompts
5. Reboot into your configured system!

### Option 3: Manual Installation

On an existing NixOS system:

```bash
git clone https://github.com/ppb1701/nixos-config /etc/nixos
cd /etc/nixos
sudo nixos-rebuild switch
```

> **Note:** You'll need to adjust `hardware-configuration.nix` for your hardware.

## Configuration

### Required Setup

#### Network Settings

Edit `modules/networking.nix`:

**For VM testing (DHCP):**

```nix
networking.useDHCP = true;
```

**For production (Static IP):**

```nix
networking = {
  useDHCP = false;
  interfaces.eno1 = {
    ipv4.addresses = [{
      address = "192.168.1.154";
      prefixLength = 24;
    }];
  };
  defaultGateway = "192.168.1.1";
  nameservers = [ "127.0.0.1" ];
};
```

- Change `eno1` to your interface name
- Change `192.168.1.154` to your desired IP
- Change `192.168.1.1` to your router IP

#### User Configuration

Edit `configuration.nix`:

```nix
users.users.ppb1701 = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  hashedPassword = "...";
};
```

- `hashedPassword` will be set during installation

#### Hardware Configuration

**Important:** Replace `hardware-configuration.nix` with output from:

```bash
nixos-generate-config --show-hardware-config
```

### Optional Services

#### Monitoring and Alerting

**Prerequisites:**

Create required private configuration files:

1. **Grafana password file:**
   ```bash
   sudo micro /etc/nixos/private/secrets.nix
   ```

   Add content:
   ```nix
   {
     grafanaPassword = "your-secure-password-here";
   }
   ```

2. **Alertmanager SMTP configuration:**
   ```bash
   sudo micro /etc/nixos/private/alertmanager.env
   ```

   Add content:
   ```bash
   SMTP_USERNAME=your-email@fastmail.com
   SMTP_PASSWORD=your-fastmail-app-password
   EMAIL_TO=alerts@your-domain.com
   ```

3. **Rebuild system:**
   ```bash
   sudo nixos-rebuild switch
   ```

4. **Configure DNS rewrites in AdGuard Home:**

   Open AdGuard Home web UI → Filters → DNS rewrites, and add:

   ```
   grafana.home       → 192.168.1.154
   prometheus.home    → 192.168.1.154
   alertmanager.home  → 192.168.1.154
   ntfy.home          → 192.168.1.154
   notes.home         → 192.168.1.154
   ```

5. **Access monitoring services:**
   - **Grafana:** http://grafana.home (username: admin, password: from secrets.nix)
   - **Prometheus:** http://prometheus.home
   - **Alertmanager:** http://alertmanager.home
   - **ntfy:** http://ntfy.home

6. **Set up mobile notifications:**
   - Install ntfy app (iOS/Android)
   - Subscribe to: `http://YOUR_SERVER_IP:2586/nixos`
   - Test: `curl -d "Test" http://localhost:2586/nixos`

> **Note:** See `docs/SERVICES.md` for complete monitoring stack documentation including alert rules, Grafana dashboard setup, and troubleshooting.

#### Syncthing (File Sync)

**Setup:**

1. Create secrets configuration (for monitoring):
   ```bash
   sudo micro /etc/nixos/private/syncthing-secrets.nix
   ```

   Add content:
   ```nix
   {
     guiPassword = "your-strong-password-here";

     prometheus_auth = {
       username = "ppb1701";
       password = "your-strong-password-here";
     };
   }
   ```

2. Create devices configuration:
   ```bash
   sudo micro /etc/nixos/private/syncthing-devices.nix
   ```

   Add content:
   ```nix
   {
     devices = {
       "my-laptop" = {
         id = "ABCDEFG-HIJKLMN-OPQRSTU-VWXYZAB-CDEFGHI-JKLMNOP-QRSTUVW-XYZABCD";
       };
     };

     folders = {
       "Documents" = {
         path = "/home/ppb1701/Documents";
         devices = [ "my-laptop" ];
       };
     };
   }
   ```

   **Note:** The `prometheus_auth` in syncthing-secrets.nix allows Prometheus to scrape Syncthing metrics for monitoring.

3. Get device IDs from each device:
   - Install Syncthing on the device
   - Open web UI: http://localhost:8384
   - Go to Actions → Show ID
   - Copy the full device ID

4. Add more devices and folders as needed to `syncthing-devices.nix`

5. Rebuild:
   ```bash
   sudo nixos-rebuild switch
   ```

6. Access Syncthing web UI:
   - **Via Nginx:** http://syncthing.home (requires DNS rewrite in AdGuard Home - see below)
   - **Direct access:** http://192.168.1.154:8384
   - **Username:** ppb1701
   - **Password:** (what you set in syncthing-secrets.nix)

> **Note:** The `private/` directory is gitignored to protect your device IDs and password.

#### Vaultwarden (Password Manager)

**Prerequisites:**

Vaultwarden requires Tailscale for remote access via Tailscale Funnel, providing secure HTTPS access to your password manager from anywhere.

**Setup:**

1. **Generate admin token:**
   ```bash
   nix-shell -p openssl --run "openssl rand -base64 48"
   ```

2. **Create environment file:**
   ```bash
   sudo mkdir -p /etc/nixos/private
   sudo micro /etc/nixos/private/vaultwarden.env
   ```

   Add content:
   ```bash
   ADMIN_TOKEN='your_generated_token_here'
   ```

3. **Add Tailscale hostname to secrets:**
   ```bash
   sudo micro /etc/nixos/private/secrets.nix
   ```

   Update to include your Tailscale hostname:
   ```nix
   {
     grafanaPassword = "your-secure-password-here";
     tailscaleIP = "100.x.y.z";  # Your Tailscale IP
     tailscaleHostname = "nixos.tailXXXXXX.ts.net";  # Your Tailscale hostname
   }
   ```

   **Finding your Tailscale hostname:**
   - Run: `tailscale status`
   - Or visit: https://login.tailscale.com/admin/machines
   - Look for your machine's hostname (e.g., nixos.taild891fe71.ts.net)

4. **Rebuild system:**
   ```bash
   sudo nixos-rebuild switch
   ```

5. **Enable Tailscale Funnel:**

   a. Enable Funnel in your Tailscale account:
   - Go to https://login.tailscale.com/admin/settings
   - Under "Access Controls", click "Edit"
   - Add the following to your ACL configuration:
     ```json
     "nodeAttrs": [
       {
         "target": ["autogroup:member"],
         "attr": ["funnel"]
       }
     ]
     ```
   - Click "Save"

   b. Start Tailscale Funnel:
   ```bash
   sudo tailscale funnel --bg --https=443 http://127.0.0.1:8222
   ```

6. **Access Vaultwarden and complete setup:**
   - Open: https://nixos.tailXXXXXX.ts.net (use your Tailscale hostname)
   - Create your account (first account is admin)
   - Enable 2FA in Account Settings for security
   - Disable signups in admin panel (/admin):
     - Go to https://nixos.tailXXXXXX.ts.net/admin
     - Login with your admin token
     - Disable "Allow new signups"
     - Save settings

7. **Optional - Rebuild to disable signups permanently:**

   Edit `/etc/nixos/modules/services.nix` and ensure:
   ```nix
   SIGNUPS_ALLOWED = false;
   ```

   Then rebuild: `sudo nixos-rebuild switch`

**Using Vaultwarden:**

- **Web Vault:** https://nixos.tailXXXXXX.ts.net
- **Admin Panel:** https://nixos.tailXXXXXX.ts.net/admin
- **Mobile/Desktop Apps:** Use official Bitwarden apps
  - Download from: https://bitwarden.com/download/
  - Configure server URL: https://nixos.tailXXXXXX.ts.net
  - Login with your credentials

> **Security Notes:**
> - Vaultwarden only listens on localhost (127.0.0.1) for security
> - Access is only available via Tailscale Funnel with automatic HTTPS
> - Enable 2FA immediately after creating your account
> - Store your admin token securely - you'll need it for admin panel access
> - Disable signups after creating your accounts to prevent unauthorized access

#### DNS Configuration for Clean URLs

To access services via clean URLs (adguard.home, syncthing.home, etc.), configure DNS rewrites in AdGuard Home:

**Setup:**

1. Open AdGuard Home web UI: http://192.168.1.154:3000
2. Go to **Filters** → **DNS rewrites**
3. Add these DNS rewrites:

```
adguard.home       → 192.168.1.154
home.home          → 192.168.1.154
syncthing.home     → 192.168.1.154
search.home        → 192.168.1.154
links.home         → 192.168.1.154
```

If you've also set up monitoring, knowledge management, and cloud storage services, add:

```
grafana.home       → 192.168.1.154
prometheus.home    → 192.168.1.154
alertmanager.home  → 192.168.1.154
ntfy.home          → 192.168.1.154
notes.home         → 192.168.1.154
cloud.home         → 192.168.1.154
```

**How it works:**
- AdGuard Home acts as your network's DNS server
- DNS rewrites map `.home` domains to your server's IP
- Split DNS: `.home` domains resolve on both LAN and Tailscale networks
- Works automatically for all devices using AdGuard Home as DNS
- No need to edit /etc/hosts on every device

**Alternative (if not using AdGuard Home as DNS):**

Add to `/etc/hosts` on each client device:

```
192.168.1.154  adguard.home home.home syncthing.home search.home links.home grafana.home prometheus.home alertmanager.home ntfy.home notes.home cloud.home
```

#### Other Services

See documentation for detailed guides:

- `docs/SERVICES.md` - Comprehensive monitoring and alerting stack, alternative services, and integrations
- `docs/NEXTCLOUD-SETUP.md` - Complete Nextcloud setup, troubleshooting, and iOS app configuration
- Additional service options: Netdata, Uptime Kuma, WireGuard, Samba, Jellyfin, Navidrome, Home Assistant, Gitea, Fail2ban, Vaultwarden

## System Maintenance

### Cleaning Up Old Generations

Over time, NixOS accumulates old system generations that consume disk space. Use these commands or the convenient shell alias to recover space:

```bash
# Using shell alias (easiest)
cleanup

# Or manually
sudo nix-collect-garbage -d
sudo nix-store --optimize
```

**What it does:**
- `cleanup` alias removes all old generations and optimizes the store
- `nix-collect-garbage -d` removes all unreachable store paths
- `nix-store --optimize` hard-links identical files to save space

**When to run:**
- Monthly as routine maintenance
- Before major system upgrades
- When disk space is running low
- After experimenting with multiple configurations

**Expected results:**
- Can free 5-20GB depending on how many old generations exist
- Store optimization typically saves 10-30% through hard-linking

**Other useful aliases:**
- `optimize` - Just run store optimization
- `diskspace` - Check current disk usage (df -h)

> **Tip:** Keep at least one or two recent generations in case you need to rollback. You can rollback with the `rollback` alias.

## Repository Structure

```
nixos-config/
├── configuration.nix              # Main system configuration (BIOS boot)
├── configuration-bios.nix         # BIOS/Legacy boot variant
├── configuration-uefi.nix         # UEFI boot variant
├── hardware-configuration.nix     # Hardware-specific settings (auto-generated)
├── build-iso.sh                   # ISO build script
├── install-nixos.sh               # Automated installation script
├── setup.config.sh                # Configuration extraction script
├── modules/                       # Service modules
│   ├── services.nix              # Core services (AdGuard, Syncthing, Tailscale, Nginx, Nextcloud, SearX, Linkwarden, etc.)
│   ├── homepage.nix              # Homepage Dashboard (service landing page with system monitoring)
│   ├── nginx-virtualhosts.nix    # Nginx reverse proxy virtual hosts (split out for readability)
│   ├── monitoring.nix            # Monitoring stack (Prometheus, Grafana, Alertmanager, Loki, Promtail)
│   ├── backups.nix               # Restic backup configuration (Vaultwarden, Nextcloud DB, Linkwarden, private configs)
│   ├── networking.nix            # Network & firewall configuration
│   ├── system.nix                # System packages, users, desktop, SSH
│   ├── boot-bios.nix             # BIOS/GRUB boot configuration
│   └── boot-uefi.nix             # UEFI/systemd-boot configuration
├── home/                          # Home Manager configurations
│   └── ppb1701.nix               # User environment (ZSH, Starship, aliases)
├── private/                       # Private config (gitignored)
│   ├── syncthing-secrets.nix     # Syncthing settings and device IDs
│   ├── syncthing-devices.nix     # Symlink to syncthing-secrets.nix
│   ├── ssh-keys.nix              # SSH authorized keys
│   ├── secrets.nix               # Service passwords (Grafana, Tailscale, SearX, Linkwarden, etc.)
│   ├── alertmanager.env          # SMTP credentials for email alerts
│   ├── vaultwarden.env           # Vaultwarden admin token
│   ├── notediscovery-config.nix  # NoteDiscovery notes path
│   ├── notediscovery-config.yaml # NoteDiscovery app configuration
│   ├── nextcloud-admin-pass      # Nextcloud admin password
│   └── restic-password           # Restic backup encryption password
├── private-example/               # Example templates for private config
│   ├── README.md                 # Instructions for private config
│   ├── secrets.nix               # Example secrets file (Grafana, Tailscale)
│   ├── ssh-keys.nix              # Example SSH keys file
│   ├── alertmanager.env          # Example SMTP config
│   ├── vaultwarden.env           # Example Vaultwarden admin token
│   ├── syncthing-secrets.nix     # Example Syncthing config
│   ├── syncthing-devices.nix     # Example Syncthing devices
│   ├── notediscovery-config.nix  # Example NoteDiscovery path config
│   ├── notediscovery-config.yaml # Example NoteDiscovery app config
│   ├── nextcloud-admin-pass      # Example Nextcloud password file
│   └── restic-password           # Example Restic backup password file
├── docs/                          # Documentation
│   ├── CUSTOMIZATION.md          # How to customize services
│   ├── SERVICES.md               # Additional services guide
│   ├── NEXTCLOUD-SETUP.md        # Complete Nextcloud setup and troubleshooting
│   ├── TROUBLESHOOTING.md        # Common issues & solutions
│   └── BUILDING-PUBLIC-ISOS.md   # ISO building guide
├── iso-config.nix                 # Custom ISO configuration
└── README.md                      # This file
```

## Building a Custom ISO

> **Note:** A pre-built ISO is available at https://github.com/ppb1701/nixos-config/releases/tag/nixos
>
> Only build your own ISO if you need to customize the configuration before installation.

### Prerequisites

- NixOS system (or VM)
- Git
- 20GB free disk space

### Build Process

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ppb1701/nixos-config
   cd nixos-config
   ```

2. **Build the ISO:**
   ```bash
   ./build-iso.sh
   ```

**Result:** `nixos-config.iso` (~1GB)

### What's Included

The custom ISO contains:

- Complete NixOS installation environment
- Your configuration files (from this repo)
- Automated installation script
- Useful tools (git, vim, parted, etc.)
- SSH enabled (user: `nixos`, password: `nixos`)

### Flashing to USB

**Linux/Mac:**

```bash
sudo dd if=nixos-config.iso of=/dev/sdX bs=4M status=progress
sync
```

- Replace `/dev/sdX` with your USB drive (e.g., `/dev/sdb`)
- **WARNING:** This will erase all data on the USB drive!

**Windows:**

Use [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/)

## Installation

1. Boot from USB
2. Login (user: `nixos`, password: `nixos`)
3. Run: `sudo /etc/nixos-config/install-nixos.sh`
4. Follow prompts
5. Reboot

> **Note:** The install script will:
> - Erase `/dev/sda` (configurable)
> - Create partitions (boot + root)
> - Create 4GB swap file
> - Install NixOS with this configuration

## Privacy & Security

### What's Safe to Share

This repository contains:

- Generic system configuration
- Service configurations (AdGuard Home, etc.)
- Network settings (private IP ranges)
- Build scripts and automation

This repository does **NOT** contain:

- Passwords or password hashes
- SSH keys
- Personal device names/IDs (Syncthing)
- API tokens or secrets

### Private Configuration

Sensitive configuration is stored in the `private/` directory, which is gitignored:

```
private/
├── syncthing-secrets.nix          # Syncthing GUI password and device IDs (gitignored)
├── syncthing-devices.nix          # Symlink to syncthing-secrets.nix (gitignored)
├── ssh-keys.nix                   # SSH authorized keys (gitignored)
├── secrets.nix                    # Grafana password, Tailscale hostname (gitignored)
├── alertmanager.env               # SMTP credentials for alerts (gitignored)
├── vaultwarden.env                # Vaultwarden admin token (gitignored)
├── notediscovery-config.nix       # NoteDiscovery notes path (gitignored)
├── notediscovery-config.yaml      # NoteDiscovery app config (gitignored)
```

**Example Templates:**

The `private-example/` directory contains template files showing the required structure for private configuration. During installation, if no private configuration backup exists, these example files are automatically copied to `/etc/nixos/private/` as a starting point.

**What's kept private:**

- Syncthing device IDs and GUI password (syncthing-secrets.nix)
- SSH authorized keys (ssh-keys.nix)
- Grafana admin password and Tailscale hostname (secrets.nix)
- Email SMTP credentials for alerting (alertmanager.env)
- Vaultwarden admin token (vaultwarden.env)
- NoteDiscovery configuration and password hash (notediscovery-config.nix/yaml)
- Any other sensitive credentials

**What's public:**

- Username (ppb1701) - already public on GitHub, Mastodon, etc.
- Configuration structure
- System architecture and design

**Setting up private files:**

The automated installer copies example files from `private-example/` to `private/` automatically. You can also set them up manually:

```bash
# Option 1: Copy all example files at once
sudo cp -r private-example/* /etc/nixos/private/
sudo chmod 600 /etc/nixos/private/*

# Option 2: Create individual files
# Create syncthing-secrets.nix
sudo micro /etc/nixos/private/syncthing-secrets.nix

# Create ssh-keys.nix (list of SSH public keys)
sudo micro /etc/nixos/private/ssh-keys.nix

# Create secrets.nix (Grafana password)
sudo micro /etc/nixos/private/secrets.nix

# Create alertmanager.env (SMTP credentials)
sudo micro /etc/nixos/private/alertmanager.env

# Create vaultwarden.env (admin token)
sudo micro /etc/nixos/private/vaultwarden.env

# Create NoteDiscovery config (optional)
sudo micro /etc/nixos/private/notediscovery-config.nix
sudo micro /etc/nixos/private/notediscovery-config.yaml

# Example ssh-keys.nix content:
[
  "ssh-ed25519 AAAAC3... user@hostname"
  "ssh-rsa AAAAB3... user@another-host"
]

# Example secrets.nix content:
{
  grafanaPassword = "your-secure-password-here";
  tailscaleIP = "100.x.y.z";
  tailscaleHostname = "nixos.tailXXXXXX.ts.net";
  searxSecret = "your-random-secret-key";  # openssl rand -hex 32
  linkwardenDbPassword = "your-db-password";  # openssl rand -hex 32
  linkwardenNextAuthSecret = "your-nextauth-secret";  # openssl rand -base64 32
}

# Example alertmanager.env content:
SMTP_USERNAME=your-email@fastmail.com
SMTP_PASSWORD=your-app-password
EMAIL_TO=alerts@your-domain.com

# Example vaultwarden.env content:
ADMIN_TOKEN='your_generated_token_here'
```

### Building Public ISOs

If you fork this repo and want to share ISOs publicly:

1. Ensure `private/syncthing-devices.nix` is not present (or is the .example file)
2. Build ISO from clean checkout
3. The resulting ISO will not contain device IDs or passwords

See `docs/building-public-isos.md` for details.

## Customization

### Convenient Shell Aliases

The system includes extensive shell aliases for quick configuration editing. Run `help` to see all available aliases:

```bash
# Edit configurations quickly
ec      # Edit configuration.nix
es      # Edit modules/services.nix (AdGuard, Syncthing, monitoring, etc.)
en      # Edit modules/networking.nix
esy     # Edit modules/system.nix
eh      # Edit home/ppb1701.nix
eb/eu   # Edit BIOS/UEFI configuration
escrt   # Edit private/secrets.nix (Grafana password)
ea      # Edit private/alertmanager.env (SMTP credentials)

# System management
rebuild # Rebuild and switch to new config (auto-reloads shell)
test    # Test new config without switching
rollback# Rollback to previous generation
update  # Update system and rebuild

# Service management
ags/agr/agl # AdGuard status/restart/logs
sts/str/stl # Syncthing status/restart/logs
```

### Adding Services to modules/services.nix

Edit `modules/services.nix` to add or configure services:

```bash
# Quick edit with alias
es

# Or manually
sudo micro /etc/nixos/modules/services.nix
```

Example - Add a new service section:

```nix
# ═══════════════════════════════════════════════════════════════════════════
# YOUR NEW SERVICE
# ═══════════════════════════════════════════════════════════════════════════
services.your-service = {
  enable = true;
  # Service-specific options
};
```

Then rebuild: `rebuild` (or `sudo nixos-rebuild switch`)

### Modifying Network Settings

Edit `modules/networking.nix` for:

- Static IP configuration
- Interface selection
- DNS settings (currently using Control D: 76.76.2.2, 76.76.10.2)
- Firewall rules
- NetworkManager configuration

Quick edit: `en` or `sudo micro /etc/nixos/modules/networking.nix`

### Automatic Generations Cleaning

NixOS keeps previous system configurations (called "generations") as a safety feature. Every time you run `sudo nixos-rebuild switch`, it creates a new generation while keeping old ones. This is incredibly useful—if a configuration breaks your system, you can boot into a previous working generation during startup.

However, these old generations accumulate over time and consume disk space. Here's how to automatically clean them up while keeping recent ones for safety.

**Add to `configuration.nix`:**

```nix
{ config, pkgs, ... }:

{
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Keep last 5 generations in bootloader menu
  boot.loader.systemd-boot.configurationLimit = 5;

  # Optimize Nix store to save space (deduplication)
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];
}
```

**What this does:**

- **Garbage collection:** Automatically removes old generations older than 30 days every week
- **Boot entries:** Keeps only the 5 most recent generations in your boot menu (prevents clutter)
- **Store optimization:** Deduplicates identical files in the Nix store to save space

**Manual cleanup:**

If you need to clean up immediately:

```bash
# Delete all old generations
sudo nix-collect-garbage -d

# Delete generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Optimize the store now
sudo nix-store --optimise
```

> **Tip:** After major changes, wait a few days before letting automatic cleanup run. This gives you time to ensure the new configuration is stable.

## Troubleshooting

### Common Issues

**AdGuard Home web UI not accessible:**

- Check firewall: `sudo iptables -L`
- Verify service: `ags` (or `systemctl status adguardhome`)
- Check binding: `ss -tlnp | grep 3000`
- View logs: `agl` (or `journalctl -u adguardhome -f`)
- Try accessing via Nginx: http://adguard.home

**Syncthing not syncing:**

- Check web UI: http://syncthing.home or http://192.168.1.154:8384
- Verify device IDs in `/etc/nixos/private/syncthing-secrets.nix`
- Check service status: `sts` (or `systemctl status syncthing`)
- View logs: `stl` (or `journalctl -u syncthing -f`)
- Verify firewall ports (22000, 21027, 8384)

**Network issues after config changes:**

- Check NetworkManager status: `systemctl status NetworkManager`
- Verify interface name in `modules/networking.nix` (currently enp1s0)
- Check DNS settings: `cat /etc/resolv.conf`
- Test connectivity: `ping 1.1.1.1`

**ISO build fails:**

- Ensure sufficient disk space (20GB+): `diskspace` or `df -h`
- Clean old generations: `cleanup`
- Check Nix store: `nix-store --verify --check-contents`
- Try clean build: `rm -rf result && ./build-iso.sh`

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more detailed solutions.

## Reporting Issues

Want to discuss? Have a suggestion?

- **Mastodon:** [@ppb1701@ppb.social](https://ppb.social/@ppb1701)
- **Blog:** https://blog.ppb1701.com

## License

MIT License - See [LICENSE](LICENSE) file for details

## Acknowledgments

- NixOS community
- AdGuard Home project
- Everyone who contributed ideas and feedback

---

**Built with ❤️ and NixOS**

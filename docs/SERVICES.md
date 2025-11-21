# Additional Services Guide

This guide covers services in your NixOS configuration and how to add more.

## Currently Included Services

Your configuration already includes these services (configured in `modules/services.nix`):

- **AdGuard Home** - DNS filtering and ad blocking (port 53, web UI port 3000)
- **Syncthing** - File synchronization (ports 22000, 21027, 8384)
- **Tailscale** - VPN for secure remote access
- **Nginx** - Reverse proxy for clean local URLs (ports 80, 443)

Plus desktop environment (LXQT), SSH server, and system utilities.

## File Synchronization

### Syncthing

Syncthing provides continuous file synchronization across multiple devices. It works on Windows, macOS, Linux, Android, and more.

**Already Included:** Syncthing is configured in `modules/services.nix` but requires device-specific configuration in `private/syncthing-secrets.nix`.

#### Why Syncthing?

- **Cross-platform:** Works on all major operating systems
- **Private:** Direct peer-to-peer sync, no cloud service
- **Secure:** All communication is encrypted
- **LAN-optimized:** Fast local sync without internet dependency
- **Conflict handling:** Automatic conflict detection and resolution
- **Versioning:** Optional file versioning for safety

#### Complete Setup Guide

**1. Create Private Configuration**

```bash
# Create the private secrets file
sudo micro /etc/nixos/private/syncthing-secrets.nix
```

**2. Add Settings to syncthing-secrets.nix**

```nix
{
  gui = {
    user = "ppb1701";
    password = "your-strong-password-here";
  };

  devices = {
    # Your devices will go here
  };

  folders = {
    # Your folders will go here
  };
}
```

**3. Get Device IDs**

On **each device** you want to sync:

- **Windows:** Install Syncthing from https://syncthing.net/ or via `winget install Syncthing.Syncthing`
- **macOS:** Install via `brew install syncthing` or download from website
- **Linux:** Usually available via package manager
- **Android:** Install from Google Play or F-Droid

After installation:
1. Open web UI: `http://localhost:8384`
2. Go to Actions → Show ID
3. Copy the device ID (format: `ABCDEFG-HIJKLMN-OPQRSTU-...`)

**4. Configure Devices and Folders**

Continue editing `private/syncthing-secrets.nix`:

```nix
{
  gui = {
    user = "ppb1701";
    password = "your-strong-password-here";
  };

  devices = {
    "windows-desktop" = {
      id = "ABCDEFG-HIJKLMN-OPQRSTU-VWXYZAB-CDEFGHI-JKLMNOP-QRSTUVW-XYZABCD";
    };
    "macbook-pro" = {
      id = "BCDEFGH-IJKLMNO-PQRSTUV-WXYZABC-DEFGHIJ-KLMNOPQ-RSTUVWX-YZABCDE";
    };
    "android-phone" = {
      id = "CDEFGHI-JKLMNOP-QRSTUVW-XYZABCD-EFGHIJK-LMNOPQR-STUVWXY-ZABCDEF";
    };
  };

  folders = {
    "Documents" = {
      path = "/home/ppb1701/Documents";
      devices = [ "windows-desktop" "macbook-pro" ];
      versioning = {
        type = "simple";
        params.keep = "5";
      };
    };
    "Photos" = {
      path = "/home/ppb1701/Pictures";
      devices = [ "android-phone" "macbook-pro" ];
      ignorePerms = false;
    };
    "Projects" = {
      path = "/home/ppb1701/Projects";
      devices = [ "windows-desktop" "macbook-pro" ];
      versioning = {
        type = "staggered";
        params = {
          maxAge = "365";
          cleanInterval = "3600";
        };
      };
    };
  };
}
```

**5. Rebuild System**

```bash
rebuild  # Use alias for quick rebuild
# Or: sudo nixos-rebuild switch
```

**6. Complete Connection on Other Devices**

On each device:
1. Open Syncthing web UI: `http://localhost:8384`
2. Add the NixOS server as a device:
   - Click "Add Remote Device"
   - Enter the server's device ID
   - Give it a name (e.g., "NixOS Server")
   - Save
3. Accept the folder share request when it appears

**Important:** On the NixOS server, you need to **accept the device connection**:
- Open http://syncthing.home (or http://192.168.1.154:8384)
- A notification will appear asking to add the new device
- Click "Add Device"
- Confirm

**7. Verify Sync**

- Check web UI for sync status
- Create test file on one device
- Verify it appears on other devices
- Check Syncthing logs: `stl` (or `journalctl -u syncthing -f`)

#### Accessing Syncthing Web UI

**On the server (NixOS):**
```
Via Nginx: http://syncthing.home (requires DNS entry)
Direct: http://192.168.1.154:8384
Username: ppb1701
Password: (from syncthing-secrets.nix)
```

**On other devices:**
```
http://localhost:8384
(Usually no authentication required for localhost)
```

#### Advanced Syncthing Configuration

**Folder Options:**

```nix
folders = {
  "My Folder" = {
    path = "/home/ppb1701/MyFolder";
    devices = [ "device1" "device2" ];
    
    # Ignore patterns (like .gitignore)
    ignorePerms = false;  # Preserve file permissions
    
    # Rescan interval (seconds)
    rescanIntervalS = 3600;
    
    # Watch for file changes (faster sync)
    fsWatcherEnabled = true;
    
    # File pull order
    order = "random";  # or "alphabetic", "smallestFirst", "largestFirst"
    
    # Versioning
    versioning = {
      type = "simple";  # Keep X versions
      params.keep = "10";
    };
    # Other types: "trashcan", "staggered", "external"
  };
};
```

**Staggered Versioning (Recommended for Important Data):**

```nix
versioning = {
  type = "staggered";
  params = {
    maxAge = "365";        # Keep versions for 1 year
    cleanInterval = "3600"; # Clean old versions hourly
    versionsPath = "";      # Use default .stversions folder
  };
};
```

**Global Syncthing Options:**

```nix
settings.options = {
  urAccepted = -1;  # Disable usage reporting
  localAnnounceEnabled = true;   # LAN discovery
  globalAnnounceEnabled = true;  # Internet discovery
  relaysEnabled = true;          # Use relays if direct connection fails
  natEnabled = true;             # NAT traversal
  startBrowser = false;          # Don't auto-open browser
  maxFolderConcurrency = 0;      # 0 = unlimited
};
```

#### Troubleshooting Syncthing

**Devices Not Discovering Each Other:**

1. **Manually add device address** in `private/syncthing-devices.nix`:

   ```nix
   devices = {
     "my-device" = {
       id = "ABCDEFG-...";
       addresses = [ "tcp://192.168.1.100:22000" ];
     };
   };
   ```

2. **Check firewall allows Syncthing:**

   ```bash
   # Sync port
   ss -tlnp | grep 22000
   
   # Web UI port
   ss -tlnp | grep 8384
   
   # Discovery port
   ss -ulnp | grep 21027
   ```

3. **Verify service is running:**

   ```bash
   systemctl status syncthing
   journalctl -u syncthing -f
   ```

4. **Enable discovery in Syncthing web UI:**
   - Settings → Connections
   - Ensure "Local Discovery" is enabled
   - Ensure "Global Discovery" is enabled
   - Ensure "Enable Relaying" is checked

**Files Not Syncing:**

- Check folder is "Up to Date" in web UI
- Verify folder paths exist and are writable
- Check disk space: `df -h`
- Review ignore patterns
- Check for file conflicts (files ending in `.sync-conflict-*`)
- Review logs: `journalctl -u syncthing -n 100`

**Slow Sync:**

- Check network bandwidth
- Consider using "Send Only" or "Receive Only" folders
- Adjust `fsWatcherEnabled` (can be CPU intensive)
- Reduce `rescanIntervalS` for less frequent scans

**Permission Errors:**

```bash
# Ensure correct ownership
sudo chown -R ppb1701:users /home/ppb1701/Documents

# Check permissions
ls -la /home/ppb1701/Documents
```

#### Syncthing on Different Platforms

**Windows:**
- Install: Download from https://syncthing.net/ or `winget install Syncthing.Syncthing`
- Web UI: `http://localhost:8384`
- Default folder: `%USERPROFILE%\Sync`

**macOS:**
- Install: `brew install syncthing` then `brew services start syncthing`
- Web UI: `http://localhost:8384`
- Default folder: `~/Sync`

**Android:**
- Install from Google Play or F-Droid
- Grant storage permissions
- Works great for camera backup

**Linux (other distros):**
```bash
# Debian/Ubuntu
sudo apt install syncthing
systemctl --user enable syncthing
systemctl --user start syncthing

# Fedora
sudo dnf install syncthing
systemctl --user enable syncthing
systemctl --user start syncthing
```

#### Security Best Practices

1. **Use strong GUI password** in syncthing-secrets.nix
2. **Enable HTTPS** for web UI in production
3. **Don't expose web UI to internet** (LAN only by default)
4. **Review sharing** - only share folders with trusted devices
5. **Use .stignore** files to exclude sensitive data
6. **Enable versioning** for important data

#### Example .stignore File

Create `.stignore` in any synced folder:

```
// Syncthing ignore patterns
// https://docs.syncthing.net/users/ignoring.html

// System files
.DS_Store
Thumbs.db
desktop.ini

// Temporary files
*.tmp
*.temp
~$*

// Build artifacts
node_modules/
target/
*.o
*.pyc

// Large files
*.iso
*.dmg
*.mkv

// Specific paths
(?d)cache/
(?d)logs/
```

## Monitoring Services

### Netdata

Real-time system monitoring with beautiful web interface.

**Create `modules/netdata.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "*";
        "history" = "3600";
        "error log" = "syslog";
        "debug log" = "none";
      };
      web = {
        "web files owner" = "root";
        "web files group" = "root";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 19999 ];
}
```

**Import in `configuration.nix`:**

```nix
imports = [
  ./modules/adguard-home.nix
  ./modules/netdata.nix
];
```

**Access:** http://192.168.1.154:19999

**Features:**

- Real-time CPU, RAM, disk, network graphs
- Process monitoring
- Service health checks
- Alert notifications
- Mobile-friendly interface

### Grafana + Prometheus

Advanced monitoring with custom dashboards.

**Create `modules/monitoring.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9090;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3001;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 3001 9090 ];
}
```

**Access:**

- **Grafana:** http://192.168.1.154:3001 (admin/admin)
- **Prometheus:** http://192.168.1.154:9090

**Setup:**

1. Login to Grafana
2. Add Prometheus data source (http://localhost:9090)
3. Import dashboard (ID: 1860 for Node Exporter)

### Uptime Kuma

Service uptime monitoring with status page.

**Create `modules/uptime-kuma.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3002";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3002 ];
}
```

**Access:** http://192.168.1.154:3002

**Features:**

- Monitor HTTP(s), TCP, ping, DNS
- Status page for sharing
- Notifications (email, Slack, Discord, etc.)
- Certificate monitoring
- Beautiful UI

## Remote Access

### Tailscale (Already Included!)

Zero-config VPN mesh network is already configured in your system!

**Configured in `modules/services.nix`:**

```nix
# ═══════════════════════════════════════════════════════════════════════════
# TAILSCALE - SECURE REMOTE ACCESS
# ═══════════════════════════════════════════════════════════════════════════
services.tailscale = {
  enable = true;
  useRoutingFeatures = "client";
};

networking.firewall = {
  checkReversePath = "loose";
  trustedInterfaces = [ "tailscale0" ];
};
```

**Setup (first time only):**

```bash
# After first boot or rebuild
sudo tailscale up

# Follow authentication link in your browser
# Your server is now accessible via Tailscale!

# Get your Tailscale hostname
tailscale status
```

**Access services via Tailscale:**

- AdGuard Home: http://[tailscale-hostname]:3000 or http://adguard.home
- Syncthing: http://[tailscale-hostname]:8384 or http://syncthing.home
- SSH: `ssh ppb1701@[tailscale-hostname]`

**Features:**

- Access from anywhere securely
- No port forwarding needed
- End-to-end encrypted connections
- Works behind NAT/firewall
- Free for personal use (up to 100 devices)
- Mobile apps available (iOS, Android)

**Managing Tailscale:**

```bash
# Check connection status
tailscale status

# See your IP addresses
tailscale ip

# Logout
sudo tailscale logout

# Reconnect
sudo tailscale up
```

### WireGuard

Self-hosted VPN server.

**Create `modules/wireguard.nix`:**

```nix
{ config, pkgs, ... }:

{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = 51820;

      privateKeyFile = "/etc/nixos/secrets/wireguard-private";

      peers = [
        {
          # Laptop
          publicKey = "LAPTOP_PUBLIC_KEY_HERE";
          allowedIPs = [ "10.100.0.2/32" ];
        }
        {
          # Phone
          publicKey = "PHONE_PUBLIC_KEY_HERE";
          allowedIPs = [ "10.100.0.3/32" ];
        }
      ];
    };
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.nat = {
    enable = true;
    externalInterface = "eno1";
    internalInterfaces = [ "wg0" ];
  };
}
```

**Generate keys:**

```bash
# Server
wg genkey | tee privatekey | wg pubkey > publickey

# Clients (on each device)
wg genkey | tee privatekey | wg pubkey > publickey
```

**Client configuration:**

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.100.0.2/24
DNS = 10.100.0.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = YOUR_PUBLIC_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## File Storage

### Nextcloud

Your own cloud storage platform (alternative to Syncthing for web-based access).

**Note:** This is an alternative/complement to Syncthing. Syncthing is better for peer-to-peer sync; Nextcloud is better for web access and sharing.

**Create `modules/nextcloud.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.home.lan";
    https = false;  # Use true with reverse proxy

    config = {
      adminpassFile = "/etc/nixos/secrets/nextcloud-admin-pass";
      dbtype = "sqlite";
    };

    settings = {
      overwriteprotocol = "http";
      default_phone_region = "US";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
```

**Create admin password file:**

```bash
echo "your-secure-password" | sudo tee /etc/nixos/secrets/nextcloud-admin-pass
sudo chmod 600 /etc/nixos/secrets/nextcloud-admin-pass
```

**Access:** http://192.168.1.154

**Features:**

- File sync and share
- Calendar and contacts
- Photo management
- Document editing (with OnlyOffice)
- Mobile apps
- Desktop clients

### Samba (Network Share)

Windows-compatible file sharing.

**Create `modules/samba.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = NixOS Server
      netbios name = nixos
      security = user
      hosts allow = 192.168.1. localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
    '';

    shares = {
      public = {
        path = "/srv/samba/public";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      private = {
        path = "/srv/samba/private";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "youruser";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 139 445 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];
}
```

**Create directories:**

```bash
sudo mkdir -p /srv/samba/public /srv/samba/private
sudo chown -R youruser:users /srv/samba
```

**Set Samba password:**

```bash
sudo smbpasswd -a youruser
```

**Access:**

- **Windows:** `\\192.168.1.154\public`
- **Mac:** `smb://192.168.1.154/public`
- **Linux:** `smb://192.168.1.154/public`

## Media Services

### Jellyfin

Your own Netflix.

**Create `modules/jellyfin.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  users.users.jellyfin.extraGroups = [ "video" "render" ];
}
```

**Access:** http://192.168.1.154:8096

**Setup:**

1. Create admin account
2. Add media libraries
3. Install clients on devices

**Features:**

- Stream movies and TV shows
- Music library
- Live TV and DVR
- Mobile apps
- Chromecast support
- Hardware transcoding

### Navidrome

Your own Spotify (music only).

**Create `modules/navidrome.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.navidrome = {
    enable = true;
    settings = {
      Port = 4533;
      MusicFolder = "/srv/music";
      Address = "0.0.0.0";
    };
  };

  networking.firewall.allowedTCPPorts = [ 4533 ];
}
```

**Access:** http://192.168.1.154:4533

**Features:**

- Subsonic-compatible
- Mobile apps (DSub, Ultrasonic, etc.)
- Web player
- Playlists and favorites
- Multi-user support

## Home Automation

### Home Assistant

Complete home automation platform.

**Create `modules/home-assistant.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "met"
      "radio_browser"
    ];
    config = {
      default_config = {};
      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];
}
```

**Access:** http://192.168.1.154:8123

**Features:**

- Control smart home devices
- Automations
- Voice assistants
- Energy monitoring
- Security cameras
- Mobile app

## Development Services

### Gitea

Your own GitHub.

**Create `modules/gitea.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.gitea = {
    enable = true;
    settings = {
      server = {
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3003;
        DOMAIN = "git.home.lan";
        ROOT_URL = "http://192.168.1.154:3003/";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 3003 ];
}
```

**Access:** http://192.168.1.154:3003

**Features:**

- Git repository hosting
- Issue tracking
- Pull requests
- Wikis
- CI/CD integration
- Lightweight

## Reverse Proxy

### Nginx (Already Included!)

Nginx is already configured to provide clean local URLs for your services!

**Configured in `modules/services.nix`:**

```nix
# ═══════════════════════════════════════════════════════════════════════════
# NGINX - REVERSE PROXY FOR CLEAN LOCAL URLS
# ═══════════════════════════════════════════════════════════════════════════
services.nginx = {
  enable = true;

  recommendedProxySettings = true;
  recommendedTlsSettings = true;

  virtualHosts = {
    "adguard.home" = {
      default = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };

    "syncthing.home" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8384";
        proxyWebsockets = true;
      };
    };
  };
};
```

**Setup DNS for Clean URLs:**

Option 1: Add to your router's DNS/hosts:
```
192.168.1.154  adguard.home
192.168.1.154  syncthing.home
```

Option 2: Add to `/etc/hosts` on client devices:
```bash
# On Windows: C:\Windows\System32\drivers\etc\hosts
# On Linux/Mac: /etc/hosts
192.168.1.154  adguard.home
192.168.1.154  syncthing.home
```

**Access services:**

- AdGuard Home: http://adguard.home (instead of http://192.168.1.154:3000)
- Syncthing: http://syncthing.home (instead of http://192.168.1.154:8384)

**Adding More Virtual Hosts:**

Edit `modules/services.nix` (use `es` alias) and add to the `virtualHosts` section:

```nix
"yourservice.home" = {
  locations."/" = {
    proxyPass = "http://127.0.0.1:PORT";
    proxyWebsockets = true;  # Enable if service uses websockets
  };
};
```

Then add the DNS entry and `rebuild`

## Security Services

### Fail2ban

Automatic IP banning for failed login attempts.

**Create `modules/fail2ban.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "192.168.1.0/24"
    ];

    jails = {
      sshd = {
        enabled = true;
        filter = "sshd";
        action = "iptables[name=SSH, port=22, protocol=tcp]";
      };
    };
  };
}
```

**Check banned IPs:**

```bash
sudo fail2ban-client status sshd
```

### Vaultwarden

Self-hosted password manager (Bitwarden compatible).

**Create `modules/vaultwarden.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;  # Disable after creating account
    };
  };

  networking.firewall.allowedTCPPorts = [ 8222 ];
}
```

**Access:** http://192.168.1.154:8222

**Setup:**

1. Create account (first user is admin)
2. Set `SIGNUPS_ALLOWED = false` and rebuild
3. Install Bitwarden clients on devices
4. Point to your server URL

## Tips for Adding Services

### Test in VM First

```bash
# Add service to configuration
# Build VM
nixos-rebuild build-vm

# Test
./result/bin/run-nixos-vm

# If good, apply to real system
nixos-rebuild switch
```

### Check Resource Usage

```bash
# Before adding service
free -h
df -h

# After adding service
systemctl status your-service
htop
```

### Keep Services Modular

One service per file in `modules/`:

```
modules/
├── adguard-home.nix
├── netdata.nix
├── jellyfin.nix
└── tailscale.nix
```

### Document Your Setup

Add comments explaining why you added each service:

```nix
# Added Netdata for real-time system monitoring
# Helps identify performance issues quickly
services.netdata.enable = true;
```

## Service Combinations

### Basic Server

- AdGuard Home
- SSH

### Monitoring Server

- AdGuard Home
- Netdata
- Uptime Kuma

### Media Server

- AdGuard Home
- Jellyfin
- Navidrome
- Tailscale (remote access)

### Home Automation Hub

- AdGuard Home
- Home Assistant
- Netdata
- Tailscale

### Development Server

- AdGuard Home
- Gitea
- Netdata
- Tailscale

## Getting Help

- **NixOS Options:** https://search.nixos.org/options
- **Service-specific docs:** Check each service's official documentation
- **Mastodon:** [@ppb1701@ppb.social](https://ppb.social/@ppb1701)

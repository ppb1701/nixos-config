# Additional Services Guide

This guide covers optional services you can add to your NixOS AdGuard Home server.

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

### Tailscale

Zero-config VPN mesh network.

**Create `modules/tailscale.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.tailscale.enable = true;

  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
```

**Setup:**

```bash
# After rebuild
sudo tailscale up

# Follow authentication link
# Your server is now accessible via Tailscale!
```

**Access services:**

- AdGuard Home: http://tailscale-hostname:3000
- SSH: `ssh youruser@tailscale-hostname`

**Features:**

- Access from anywhere
- No port forwarding needed
- Encrypted connections
- Works behind NAT
- Free for personal use

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

## File Sync & Storage

### Syncthing

Already covered in main README. See `private/syncthing-devices.nix.example`.

### Nextcloud

Your own cloud storage platform.

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

### Nginx

Serve multiple services on port 80/443 with friendly URLs.

**Create `modules/nginx.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;

    virtualHosts = {
      "adguard.home.lan" = {
        locations."/" = {
          proxyPass = "http://localhost:3000";
          proxyWebsockets = true;
        };
      };

      "netdata.home.lan" = {
        locations."/" = {
          proxyPass = "http://localhost:19999";
          proxyWebsockets = true;
        };
      };

      "jellyfin.home.lan" = {
        locations."/" = {
          proxyPass = "http://localhost:8096";
          proxyWebsockets = true;
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

**Add to router DNS or `/etc/hosts`:**

```
192.168.1.154  adguard.home.lan
192.168.1.154  netdata.home.lan
192.168.1.154  jellyfin.home.lan
```

**Access:**

- http://adguard.home.lan
- http://netdata.home.lan
- http://jellyfin.home.lan

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
- **This repo:** https://github.com/ppb1701/nixos-adguard-home/issues

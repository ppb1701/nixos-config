# Additional Services Guide

This guide covers services in your NixOS configuration and how to add more.

## Currently Included Services

Your configuration already includes these services (configured in `modules/services.nix`):

- **AdGuard Home** - DNS filtering and ad blocking (port 53, web UI port 3000)
- **Syncthing** - File synchronization (ports 22000, 21027, 8384)
- **NoteDiscovery** - Web-based knowledge base for markdown notes (port 5000)
- **Tailscale** - VPN for secure remote access
- **Nginx** - Reverse proxy for clean local URLs (ports 80, 443)
- **Prometheus + Grafana + Alertmanager + Loki** - Complete monitoring and alerting stack
- **ntfy** - Self-hosted push notifications (port 2586)

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

  prometheus_auth = {
    username = "ppb1701";  # Should match gui.user
    password = "your-strong-password-here";  # Should match gui.password
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

## Knowledge Management

### NoteDiscovery (Port 5000)

**Purpose:** Web-based knowledge base for searching and managing markdown notes

NoteDiscovery provides a searchable web interface for your markdown notes, perfect for personal wikis, documentation, and knowledge bases. It integrates seamlessly with Syncthing for note synchronization across devices.

**Features:**
- Full-text search across all markdown files
- Clean web interface with dark/light themes
- Password authentication
- Works with any markdown notes (Obsidian, Joplin, plain text, etc.)
- Automatic file watching for real-time updates
- Integrates with Syncthing for cross-device sync

**Already Included:** NoteDiscovery is pre-configured in `modules/services.nix` but requires private configuration.

#### Setup Guide

**1. Create Configuration Files**

```bash
# Edit the notes path configuration
sudo micro /etc/nixos/private/notediscovery-config.nix
```

Add:
```nix
{
  notesPath = "/home/ppb1701/Sync/Notes";  # Change to your actual notes folder
}
```

```bash
# Edit the app configuration
sudo micro /etc/nixos/private/notediscovery-config.yaml
```

Add:
```yaml
security:
  enabled: true
  username: "admin"
  password_hash: "WILL_GENERATE_IN_NEXT_STEP"

app:
  title: "My Knowledge Base"
  notes_path: "/home/ppb1701/Sync/Notes"  # Must match the path above
  host: "127.0.0.1"
  port: 5000
  debug: false

ui:
  theme: "dark"
  items_per_page: 50
  enable_search: true
```

**2. First Rebuild (Will Fail - Expected!)**

```bash
sudo nixos-rebuild switch
```

This will fail because NoteDiscovery isn't installed yet, but it will create the `/var/lib/notediscovery` directory.

**3. Install NoteDiscovery**

```bash
# Switch to notediscovery user context
sudo -u notediscovery bash

# Navigate to working directory
cd /var/lib/notediscovery

# Clone the repository
git clone https://github.com/ppb1701/NoteDiscovery.git .

# Create virtual environment
python3 -m venv venv

# Install dependencies
./venv/bin/pip install -r requirements.txt

# Generate password hash
./venv/bin/python3 generate_password.py

# Follow prompts to create your password
# Copy the generated hash

# Exit notediscovery user context
exit
```

**4. Update Configuration with Password Hash**

```bash
sudo micro /etc/nixos/private/notediscovery-config.yaml
```

Replace `WILL_GENERATE_IN_NEXT_STEP` with your generated password hash.

**5. Rebuild System**

```bash
sudo nixos-rebuild switch
```

**6. Configure DNS Rewrite (Optional but Recommended)**

Open AdGuard Home → Filters → DNS rewrites:
```
notes.home → YOUR_SERVER_IP
```

**7. Access NoteDiscovery**

- **Via Nginx (recommended):** http://notes.home
- **Direct access:** http://YOUR_SERVER_IP:5000
- **Username:** admin (or whatever you set)
- **Password:** (what you generated in step 3)

#### Integration with Syncthing

NoteDiscovery works great with Syncthing for note synchronization:

1. **Set up a Syncthing folder for notes:**
   ```nix
   # In /etc/nixos/private/syncthing-secrets.nix
   folders = {
     "Notes" = {
       path = "/home/ppb1701/Sync/Notes";
       devices = [ "laptop" "phone" "tablet" ];
     };
   };
   ```

2. **Point NoteDiscovery to the same folder:**
   ```nix
   # In /etc/nixos/private/notediscovery-config.nix
   {
     notesPath = "/home/ppb1701/Sync/Notes";
   }
   ```

3. **Rebuild:** `sudo nixos-rebuild switch`

Now your notes sync across devices via Syncthing and are searchable via NoteDiscovery!

#### Service Management

```bash
# Check status
systemctl status notediscovery

# View logs
journalctl -u notediscovery -f

# Restart service
sudo systemctl restart notediscovery
```

#### Firewall Configuration

Port 5000 is already opened in `modules/networking.nix`:

```nix
networking.firewall.allowedTCPPorts = [
  5000    # Note Discovery (direct access)
];
```

Access via Nginx (port 80) is also configured for clean URLs.

#### Troubleshooting

**Service fails to start:**
- Check logs: `journalctl -u notediscovery -f`
- Verify notes path exists: `ls -la /home/ppb1701/Sync/Notes`
- Ensure notediscovery user has read access to notes folder
- Check virtual environment exists: `ls -la /var/lib/notediscovery/venv`

**Can't access web UI:**
- Verify service is running: `systemctl status notediscovery`
- Check port binding: `ss -tlnp | grep 5000`
- Test direct access: `curl http://localhost:5000`
- Verify nginx configuration: `systemctl status nginx`

**Notes not appearing:**
- Refresh the page (NoteDiscovery watches for file changes)
- Check file permissions on notes folder
- Verify notes path in config matches actual location

#### Updating NoteDiscovery

```bash
sudo -u notediscovery bash
cd /var/lib/notediscovery
git pull
./venv/bin/pip install -r requirements.txt --upgrade
exit
sudo systemctl restart notediscovery
```

## Monitoring and Alerting Stack

### Overview

The system includes a complete monitoring and alerting stack built on industry-standard tools. This provides real-time metrics, visualization, log aggregation, and instant notifications.

**Stack Components:**

- **Prometheus:** Metrics collection and time-series database
  - Node exporter for system metrics
  - Nginx exporter for web server metrics
  - Blackbox exporter for HTTP health checks
  - Syncthing metrics with authentication
- **Grafana:** Beautiful dashboards and visualization
- **Alertmanager:** Alert routing and notification delivery
- **Loki:** Log aggregation and storage
- **Promtail:** Log collection and shipping
- **ntfy:** Self-hosted push notifications

### Architecture

```
┌─────────────┐
│   Services  │  (AdGuard, Nginx, System, etc.)
└──────┬──────┘
       │
       ├──> Exporters ──> Prometheus ──> Alertmanager ──> ntfy/Email
       │                      │
       │                      └──────> Grafana (Dashboards)
       │
       └──> Promtail ─────> Loki ─────> Grafana (Logs)
```

### Prometheus (Port 9090)

**Purpose:** Time-series metrics database and alerting engine

**Configuration (in modules/services.nix):**

```nix
services.prometheus = {
  enable = true;
  port = 9090;
  retentionTime = "30d";

  exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9100;
    };

    nginx = {
      enable = true;
      port = 9113;
      scrapeUri = "http://127.0.0.1:8080/nginx_status";
    };

    blackbox = {
      enable = true;
      port = 9115;
      configFile = pkgs.writeText "blackbox.yml" ''
        modules:
          http_2xx:
            prober: http
            timeout: 5s
            http:
              valid_status_codes: [200]
              method: GET
              follow_redirects: true
              preferred_ip_protocol: "ip4"
      '';
    };
  };

  scrapeConfigs = [
    # ... node, nginx, prometheus jobs ...
    {
      job_name = "syncthing";
      metrics_path = "/metrics";
      static_configs = [{
        targets = [ "127.0.0.1:8384" ];
      }];
      basic_auth = (import /etc/nixos/private/syncthing-secrets.nix).prometheus_auth;
    }
    {
      job_name = "blackbox";
      metrics_path = "/probe";
      params = { module = [ "http_2xx" ]; };
      static_configs = [{
        targets = [
          "http://127.0.0.1:5000"   # NoteDiscovery
          "http://127.0.0.1:8384"   # Syncthing GUI
          "http://127.0.0.1:3000"   # AdGuard Home
        ];
      }];
      # Relabel configs for blackbox exporter
    }
  ];
};
```

**Access:**
- Via Nginx: http://prometheus.home
- Direct: http://192.168.1.154:9090

**Features:**
- Collects metrics every 30 seconds
- 30-day retention period
- Multiple exporters for comprehensive monitoring:
  - **Node exporter** (port 9100): System metrics (CPU, RAM, disk, network)
  - **Nginx exporter** (port 9113): Web server metrics
  - **Blackbox exporter** (port 9115): HTTP health checks
- Syncthing metrics monitoring with authentication
- Systemd service monitoring
- Built-in alerting engine

**Metrics Collected:**
- **System:** CPU usage, memory, disk space, network I/O, load average
- **Services:** Systemd unit status, service uptime
- **Nginx:** Request rates, error rates, connections
- **Syncthing:** Sync status, connected devices, folder statistics
- **Health Checks:** HTTP availability for NoteDiscovery, Syncthing GUI, AdGuard Home
- **Prometheus itself:** Query performance, storage stats

**Syncthing Metrics Setup:**

To enable Syncthing metrics monitoring, ensure your `/etc/nixos/private/syncthing-secrets.nix` includes prometheus_auth credentials:

```nix
{
  gui = {
    user = "ppb1701";
    password = "your-password";
  };

  prometheus_auth = {
    username = "ppb1701";  # Should match gui.user
    password = "your-password";  # Should match gui.password
  };

  devices = { ... };
  folders = { ... };
}
```

### Grafana (Port 3001)

**Purpose:** Metrics visualization and dashboarding

**Configuration:**

```nix
services.grafana = {
  enable = true;
  settings = {
    server = {
      http_addr = "0.0.0.0";
      http_port = 3001;
      domain = "grafana.home";
    };

    security = {
      admin_user = "admin";
      admin_password = (import /etc/nixos/private/secrets.nix).grafanaPassword;
    };
  };
};
```

**Access:**
- Via Nginx: http://grafana.home
- Direct: http://192.168.1.154:3001
- Username: `admin`
- Password: From `/etc/nixos/private/secrets.nix`

**Data Sources (Auto-configured):**
- Prometheus (default) - for metrics
- Loki - for logs

**Setup:**

1. Create password file:
   ```bash
   sudo micro /etc/nixos/private/secrets.nix
   ```

2. Add content:
   ```nix
   {
     grafanaPassword = "your-secure-password-here";
   }
   ```

3. Rebuild:
   ```bash
   rebuild
   ```

4. Access Grafana and import dashboards:
   - Node Exporter Full (ID: 1860) - Comprehensive system metrics
   - Nginx (ID: 12708) - Nginx performance
   - Prometheus Stats (ID: 3662) - Prometheus monitoring

### Alertmanager (Port 9093)

**Purpose:** Alert routing, grouping, and notification delivery

**Configuration:**

```nix
services.prometheus.alertmanager = {
  enable = true;
  port = 9093;

  environmentFile = "/etc/nixos/private/alertmanager.env";

  configuration = {
    global = {
      smtp_smarthost = "smtp.fastmail.com:587";
      smtp_from = "$SMTP_USERNAME";
      smtp_auth_username = "$SMTP_USERNAME";
      smtp_auth_password = "$SMTP_PASSWORD";
      smtp_require_tls = true;
    };

    route = {
      receiver = "all-alerts";
      group_by = [ "alertname" "severity" ];
      group_wait = "30s";
      group_interval = "5m";
      repeat_interval = "4h";
    };

    receivers = [
      {
        name = "all-alerts";
        webhook_configs = [
          {
            url = "http://localhost:2586/nixos";
            send_resolved = true;
          }
        ];
        email_configs = [
          {
            to = "$EMAIL_TO";
            headers = {
              Subject = "NixOS Server Alert";
            };
          }
        ];
      }
    ];
  };
};
```

**Access:**
- Via Nginx: http://alertmanager.home
- Direct: http://192.168.1.154:9093

**Setup:**

1. Create environment file:
   ```bash
   sudo micro /etc/nixos/private/alertmanager.env
   ```

2. Add SMTP credentials:
   ```bash
   SMTP_USERNAME=your-email@fastmail.com
   SMTP_PASSWORD=your-app-password
   EMAIL_TO=alerts@your-domain.com
   ```

3. Rebuild:
   ```bash
   rebuild
   ```

**Alert Routing:**
- Groups alerts by name and severity
- Waits 30 seconds before sending first notification (to batch similar alerts)
- Re-sends unresolved alerts every 4 hours
- Sends to both ntfy (instant push) and email

**Notification Channels:**
1. **Webhook to ntfy** - Instant push notifications to mobile/desktop
2. **Email** - Traditional email alerts via Fastmail SMTP

### Alert Rules

Six alert rules are configured to monitor system health:

**1. ServiceDown (Critical)**
- **Triggers:** Service unavailable for 2+ minutes
- **Expression:** `up == 0`
- **Severity:** Critical

**2. DiskSpaceWarning (Warning)**
- **Triggers:** Root filesystem <20% free for 5+ minutes
- **Expression:** `(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 20`
- **Severity:** Warning

**3. DiskSpaceCritical (Critical)**
- **Triggers:** Root filesystem <10% free for 2+ minutes
- **Expression:** `(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10`
- **Severity:** Critical

**4. HighCPUUsage (Warning)**
- **Triggers:** CPU usage >80% for 10+ minutes
- **Expression:** `100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`
- **Severity:** Warning

**5. HighMemoryUsage (Warning)**
- **Triggers:** Memory usage >90% for 5+ minutes
- **Expression:** `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90`
- **Severity:** Warning

**6. NginxHighErrorRate (Warning)**
- **Triggers:** Nginx 5xx errors >0.05/sec for 5+ minutes
- **Expression:** `rate(nginx_http_requests_total{status=~"5.."}[5m]) > 0.05`
- **Severity:** Warning

### Loki (Port 3100)

**Purpose:** Log aggregation and storage

**Configuration:**

```nix
services.loki = {
  enable = true;
  configuration = {
    server.http_listen_port = 3100;
    auth_enabled = false;

    schema_config = {
      configs = [{
        from = "2022-06-06";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];
    };

    limits_config = {
      reject_old_samples = true;
      reject_old_samples_max_age = "168h";
    };
  };
};
```

**Features:**
- Stores logs for 7 days (168 hours)
- Filesystem-based storage
- Indexed for fast querying
- Integrates with Grafana for log visualization

**Storage Paths:**
- Index: `/var/lib/loki/tsdb-index`
- Cache: `/var/lib/loki/tsdb-cache`
- Chunks: `/var/lib/loki/chunks`

**Access:**
- Logs are queried through Grafana (not direct web UI)
- Use Grafana Explore → Loki data source

### Promtail (Port 3031)

**Purpose:** Log collection and shipping to Loki

**Configuration:**

```nix
services.promtail = {
  enable = true;
  configuration = {
    server = {
      http_listen_port = 3031;
    };

    scrape_configs = [
      {
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "nixos";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }
    ];
  };
};
```

**Features:**
- Collects systemd journal logs (last 12 hours)
- Labels logs with systemd unit information
- Forwards to Loki in real-time
- Preserves log metadata (timestamps, units, hosts)

**Log Sources:**
- All systemd services (AdGuard, Syncthing, Nginx, etc.)
- System logs
- Kernel messages

### ntfy (Port 2586)

**Purpose:** Self-hosted push notification service

**Configuration:**

```nix
services.ntfy-sh = {
  enable = true;
  settings = {
    base-url = "http://ntfy.home";
    listen-http = "0.0.0.0:2586";
    cache-file = "/var/lib/ntfy-sh/cache.db";
    cache-duration = "24h";
    keepalive-interval = "45s";
    auth-default-access = "read-write";
    behind-proxy = true;
  };
};
```

**Access:**
- Via Nginx: http://ntfy.home
- Direct: http://192.168.1.154:2586

**Features:**
- Instant push notifications to mobile/desktop
- 24-hour message cache (catch up when connecting via Tailscale)
- Webhook endpoint for Alertmanager
- No authentication required on local network
- Mobile apps available (iOS, Android)
- Web push notifications

**Setup:**

1. **Install ntfy mobile app:**
   - iOS: Search "ntfy" in App Store
   - Android: Google Play or F-Droid

2. **Subscribe to server alerts:**
   - Open app
   - Add subscription
   - Topic URL: `http://YOUR_SERVER_IP:2586/nixos`
   - Or via Tailscale: `http://YOUR_TAILSCALE_HOSTNAME:2586/nixos`

3. **Test notification:**
   ```bash
   curl -d "Test alert from NixOS server" http://localhost:2586/nixos
   ```

**Alert Topic:**
- Topic name: `nixos`
- Alertmanager sends to: `http://localhost:2586/nixos`
- Subscribe in app to receive all server alerts

### Quick Start Guide

**1. Set up private configuration files:**

```bash
# Create secrets file for Grafana password
sudo micro /etc/nixos/private/secrets.nix

# Add:
{
  grafanaPassword = "your-secure-password";
}

# Create alertmanager environment file
sudo micro /etc/nixos/private/alertmanager.env

# Add:
SMTP_USERNAME=your-email@fastmail.com
SMTP_PASSWORD=your-app-password
EMAIL_TO=alerts@your-domain.com
```

**2. Rebuild system:**

```bash
rebuild
```

**3. Configure DNS rewrites in AdGuard Home:**

Since AdGuard Home is your DNS server, use DNS Rewrites for clean local URLs:

1. Open AdGuard Home: http://adguard.home (or http://192.168.1.154:3000)
2. Go to **Filters** → **DNS rewrites**
3. Add the following rewrites:

```
prometheus.home    → 192.168.1.154
grafana.home       → 192.168.1.154
alertmanager.home  → 192.168.1.154
ntfy.home          → 192.168.1.154
```

Click "Add" for each entry.

**Alternative:** Add to `/etc/hosts` on client devices if not using AdGuard Home as DNS:

```
192.168.1.154  prometheus.home
192.168.1.154  grafana.home
192.168.1.154  alertmanager.home
192.168.1.154  ntfy.home
```

**4. Access dashboards:**

- **Grafana:** http://grafana.home (admin / your-password)
- **Prometheus:** http://prometheus.home
- **Alertmanager:** http://alertmanager.home
- **ntfy:** http://ntfy.home

**5. Set up mobile notifications:**

- Install ntfy app on phone
- Subscribe to: `http://YOUR_SERVER_IP:2586/nixos`
- Test: `curl -d "Test" http://localhost:2586/nixos`

### Monitoring Workflow

**Daily Monitoring:**
1. Check Grafana dashboards for system health
2. Review Prometheus alerts in Alertmanager
3. Check logs in Grafana Explore (Loki)

**When Alerts Fire:**
1. Receive instant push notification via ntfy
2. Receive email backup notification
3. Check Alertmanager for alert details
4. View relevant metrics in Grafana
5. Check logs in Grafana Explore
6. Resolve issue
7. Alert automatically clears when resolved

**Useful Queries:**

Prometheus:
```promql
# CPU usage per core
100 - (avg by (cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

Loki (in Grafana Explore):
```logql
# AdGuard Home logs
{unit="adguardhome.service"}

# Nginx errors
{unit="nginx.service"} |= "error"

# All critical logs
{job="systemd-journal"} |= "critical"
```

### Shell Aliases for Monitoring

Added to `home/ppb1701.nix`:

```bash
escrt    # Edit /etc/nixos/private/secrets.nix (Grafana password)
ea       # Edit /etc/nixos/private/alertmanager.env (SMTP settings)
```

### Firewall Configuration

Monitoring ports opened in `modules/networking.nix`:

```nix
networking.firewall.allowedTCPPorts = [
  3001  # Grafana
  2586  # ntfy
  9090  # Prometheus
];
```

**Note:** Other monitoring components (Alertmanager, Loki, Promtail, exporters) are localhost-only and not exposed externally.

### Troubleshooting

**Grafana login fails:**

```bash
# Check Grafana service
systemctl status grafana

# View logs
journalctl -u grafana -f

# Reset password in secrets.nix
sudo micro /etc/nixos/private/secrets.nix
rebuild
```

**Alerts not sending:**

```bash
# Check Alertmanager
systemctl status prometheus-alertmanager

# View logs
journalctl -u prometheus-alertmanager -f

# Verify environment file
sudo cat /etc/nixos/private/alertmanager.env

# Test email manually
curl -XPOST http://localhost:9093/api/v1/alerts -d '[{"labels":{"alertname":"test"}}]'
```

**ntfy notifications not working:**

```bash
# Check ntfy service
systemctl status ntfy-sh

# View logs
journalctl -u ntfy-sh -f

# Test locally
curl -d "Test message" http://localhost:2586/nixos

# Check firewall
ss -tlnp | grep 2586
```

**Prometheus not collecting metrics:**

```bash
# Check Prometheus
systemctl status prometheus

# View targets
curl http://localhost:9090/api/v1/targets | jq

# Check exporters
systemctl status prometheus-node-exporter
systemctl status prometheus-nginx-exporter
systemctl status prometheus-blackbox-exporter

# Test blackbox exporter
curl http://localhost:9115/probe?target=http://localhost:3000&module=http_2xx
```

**Logs not appearing in Loki:**

```bash
# Check Loki
systemctl status loki

# Check Promtail
systemctl status promtail

# View Promtail logs
journalctl -u promtail -f
```

### Alternative: Netdata

If you prefer a simpler, all-in-one monitoring solution:

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

### Nextcloud (Port 8280) - Already Included!

**Purpose:** Private cloud storage and collaboration platform

Nextcloud is already configured in `modules/services.nix` and provides a complete self-hosted cloud platform with file sync, sharing, calendar, contacts, and collaborative editing capabilities.

**Already Included:** Nextcloud is fully configured with PostgreSQL database, external drive support, and integrated monitoring.

**Configuration Details:**
- **Package:** Nextcloud 31 (latest version)
- **Port:** 8280 (configured to avoid conflict with AdGuard Home on port 3000)
- **Database:** PostgreSQL with automatic local creation
- **Data Storage:** /mnt/nextcloud-data (external drive mount required)
- **Access:** HTTP only (https = false) - designed for local/Tailscale access
- **Security:** Brute-force and rate limiting disabled for convenience on trusted networks
- **Integration:** Fully integrated with Prometheus monitoring, Nginx proxy, and Tailscale VPN

**Features:**
- File sync and sharing with desktop/mobile clients
- External drive support for large storage capacity
- Calendar and contacts synchronization
- Collaborative document editing
- Photo management and galleries
- Two-factor authentication support
- Comprehensive monitoring and alerting
- Auto-update for apps

**⚠️ Security Notice:**

This Nextcloud configuration is **intentionally designed for local and Tailscale-only access**:
- Uses HTTP without encryption
- Brute-force protection disabled
- Rate limiting disabled
- **DO NOT expose to the public internet without proper hardening!**

**Safe for:**
- Local network access behind firewall
- Tailscale VPN access (encrypted tunnel)
- Trusted home/office networks

**Complete Setup Guide:**

See `docs/NEXTCLOUD-SETUP.md` for comprehensive documentation including:
- External drive setup and formatting
- Initial configuration and admin password
- Monitoring integration
- DNS configuration for clean URLs
- iOS and desktop app setup
- Detailed troubleshooting guide
- Security considerations
- Common gotchas and lessons learned

**Quick Setup:**

1. **Format and mount external drive** (one-time setup):
   ```bash
   # Find your drive
   lsblk

   # Format (DESTRUCTIVE! Replace /dev/sdX1 with your device)
   sudo mkfs.ext4 -L nextcloud-data /dev/sdX1

   # Get UUID
   sudo blkid /dev/sdX1
   ```

2. **Add mount point to hardware-configuration.nix**:
   ```nix
   fileSystems."/mnt/nextcloud-data" = {
     device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
     fsType = "ext4";
     options = [ "nofail" ];
   };
   ```

3. **Create admin password file**:
   ```bash
   # Generate strong password
   openssl rand -base64 32 | sudo tee /etc/nixos/private/nextcloud-admin-pass

   # Set permissions (644, not 600! Exporter needs access)
   sudo chmod 644 /etc/nixos/private/nextcloud-admin-pass
   ```

4. **Apply configuration**:
   ```bash
   sudo nixos-rebuild switch
   ```

5. **Configure DNS rewrite in AdGuard Home**:
   - Open AdGuard Home → Filters → DNS rewrites
   - Add: `nextcloud.home → YOUR_SERVER_IP`

6. **Access Nextcloud**:
   - Via DNS: http://nextcloud.home:8280
   - Direct: http://YOUR_SERVER_IP:8280
   - Username: `root`
   - Password: Contents of `/etc/nixos/private/nextcloud-admin-pass`

**Monitoring Integration:**

Nextcloud monitoring is pre-configured in `modules/monitoring.nix`:

- **Nextcloud Exporter** (port 9205): Collects Nextcloud-specific metrics
  - Active users
  - File storage usage
  - Database statistics
  - App status

- **HTTP Health Check**: Blackbox exporter monitors Nextcloud availability

- **Alert Rules**:
  - **NextcloudDown**: Triggers if Nextcloud is unreachable for 15 minutes
  - **NextcloudDiskSpaceLow**: Triggers if less than 10% free space on data drive

**Desktop and Mobile Clients:**

- **Desktop clients:** Available for Windows, macOS, and Linux at https://nextcloud.com/install/#install-clients
- **Mobile apps:** Available for iOS and Android
- **Configuration:** Point clients to `http://nextcloud.home:8280` (or use Tailscale hostname)

**iOS App Setup:**

1. Install "Nextcloud - Files & Photos" from App Store
2. Configure connection:
   - Via Tailscale: `http://nextcloud.vpn:8280` (recommended)
   - Via Local Network: `http://nextcloud.home:8280`
3. Trust the HTTP certificate warning (expected for local HTTP)
4. Login with root credentials

**Service Management:**

```bash
# Check Nextcloud service status
systemctl status phpfpm-nextcloud

# View logs
journalctl -u phpfpm-nextcloud -f

# Check Nextcloud-specific logs
sudo tail -f /mnt/nextcloud-data/data/nextcloud.log

# Restart Nextcloud
sudo systemctl restart phpfpm-nextcloud

# Check PostgreSQL database
systemctl status postgresql

# Check Nextcloud exporter (monitoring)
systemctl status prometheus-nextcloud-exporter
curl http://localhost:9205/metrics
```

**Accessing via Tailscale:**

Nextcloud is configured to work seamlessly with Tailscale:
- Trusted domains include `nextcloud.vpn`
- Trusted proxies include entire Tailscale IP range (100.64.0.0/10)
- Access from anywhere: `http://YOUR-TAILSCALE-HOSTNAME:8280`

**Common Issues:**

**Port 8280 not accessible:**
```bash
# Verify port is listening
sudo ss -tlnp | grep 8280

# Check Nginx configuration
sudo nginx -t

# Restart Nginx if needed
sudo systemctl restart nginx
```

**PostgreSQL connection errors:**
```bash
# Check PostgreSQL status
systemctl status postgresql

# View PostgreSQL logs
journalctl -u postgresql -n 50
```

**Prometheus exporter permission denied:**
```bash
# Password file needs 644 permissions (not 600!)
sudo chmod 644 /etc/nixos/private/nextcloud-admin-pass
sudo systemctl restart prometheus-nextcloud-exporter
```

**External drive not mounted:**
```bash
# Verify mount
df -h /mnt/nextcloud-data

# Mount manually if needed
sudo mount -a

# Check hardware-configuration.nix has correct UUID
```

**Nextcloud vs. Syncthing:**

Both are included in your configuration - they serve different purposes:

**Use Nextcloud when you want:**
- Web-based file access and management
- Calendar and contacts synchronization
- Collaborative document editing
- Photo galleries and sharing
- Mobile/desktop app with selective sync
- Centralized storage on server

**Use Syncthing when you want:**
- Peer-to-peer file synchronization
- Automatic bidirectional sync
- No central server dependency
- LAN-optimized transfers
- Simpler conflict resolution
- Lower resource usage

**Both can be used together!** Many users sync files between devices with Syncthing and use Nextcloud for web access and sharing.

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

**Recommended: Use AdGuard Home DNS Rewrites**

Since AdGuard Home is your DNS server, configure DNS rewrites for automatic resolution across all network devices:

1. Open AdGuard Home: http://192.168.1.154:3000
2. Go to **Filters** → **DNS rewrites**
3. Add DNS rewrites for all services:

**Core Services:**
```
adguard.home       → 192.168.1.154
syncthing.home     → 192.168.1.154
```

**Monitoring Services** (if enabled):
```
grafana.home       → 192.168.1.154
prometheus.home    → 192.168.1.154
alertmanager.home  → 192.168.1.154
ntfy.home          → 192.168.1.154
```

Click "Add" for each entry.

**Benefits:**
- Works for all devices on your network automatically
- No need to configure each device individually
- Centralized DNS management
- Changes apply network-wide instantly

**Alternative: Manual /etc/hosts entries**

If you're not using AdGuard Home as your network DNS server, add to `/etc/hosts` on each client device:

```bash
# On Windows: C:\Windows\System32\drivers\etc\hosts
# On Linux/Mac: /etc/hosts
192.168.1.154  adguard.home syncthing.home grafana.home prometheus.home alertmanager.home ntfy.home
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

Self-hosted password manager (Bitwarden compatible) with Tailscale Funnel for secure remote access.

**Status:** ✅ Implemented in `modules/services.nix` (lines 72-94)

**Features:**
- Bitwarden-compatible API (works with official Bitwarden clients)
- Secure HTTPS access via Tailscale Funnel
- Admin panel with token authentication
- 2FA support
- Automatic backups to `/var/local/vaultwarden/backup`
- No firewall ports opened (local access only via Tailscale)

**Configuration:**

Vaultwarden is already configured in `modules/services.nix`:

```nix
services.vaultwarden = {
  enable = true;
  backupDir = "/var/local/vaultwarden/backup";

  config = {
    ROCKET_ADDRESS = "127.0.0.1";  # Only listen locally
    ROCKET_PORT = 8222;

    # Uses your Tailscale hostname from secrets
    DOMAIN = "https://${secrets.tailscaleHostname}";

    # Disable signups after creating accounts
    SIGNUPS_ALLOWED = false;
    INVITATIONS_ALLOWED = false;
  };

  # Admin token loaded from environment file
  environmentFile = "/etc/nixos/private/vaultwarden.env";
};
```

**Setup:**

1. **Generate admin token:**
   ```bash
   nix-shell -p openssl --run "openssl rand -base64 48"
   ```

2. **Create `/etc/nixos/private/vaultwarden.env`:**
   ```bash
   ADMIN_TOKEN='your_generated_token_here'
   ```

3. **Add Tailscale hostname to `/etc/nixos/private/secrets.nix`:**
   ```nix
   {
     grafanaPassword = "your-password";
     tailscaleIP = "100.x.y.z";
     tailscaleHostname = "nixos.tailXXXXXX.ts.net";  # Your Tailscale hostname
   }
   ```

   Find your hostname: `tailscale status` or https://login.tailscale.com/admin/machines

4. **Rebuild:**
   ```bash
   sudo nixos-rebuild switch
   ```

5. **Enable Tailscale Funnel:**

   a. Add Funnel capability to Tailscale ACL (https://login.tailscale.com/admin/settings):
   ```json
   "nodeAttrs": [
     {
       "target": ["autogroup:member"],
       "attr": ["funnel"]
     }
   ]
   ```

   b. Start Funnel:
   ```bash
   sudo tailscale funnel --bg --https=443 http://127.0.0.1:8222
   ```

6. **Create account and configure:**
   - Access: https://nixos.tailXXXXXX.ts.net
   - Create your account (first account is admin)
   - Enable 2FA in Account Settings
   - Go to admin panel: https://nixos.tailXXXXXX.ts.net/admin
   - Login with admin token
   - Disable "Allow new signups"

**Access:**
- **Web Vault:** https://nixos.tailXXXXXX.ts.net
- **Admin Panel:** https://nixos.tailXXXXXX.ts.net/admin
- **Mobile/Desktop:** Download official Bitwarden apps from https://bitwarden.com/download/
  - Set server URL to your Tailscale hostname
  - Login with your credentials

**Security:**
- Only accessible via Tailscale (no firewall ports opened)
- HTTPS with automatic certificates via Tailscale Funnel
- Admin panel protected by token
- Supports 2FA (TOTP, U2F, Duo)
- Signups disabled after initial account creation

**Backups:**
- Automatic daily backups to `/var/local/vaultwarden/backup`
- Manual backup location: `/var/lib/bitwarden_rs/`

**Monitoring:**
- HTTP health checks configured in `modules/monitoring.nix`
- Alerts if service is down

**Troubleshooting:**

Check service status:
```bash
systemctl status vaultwarden
journalctl -u vaultwarden -f
```

Check Tailscale Funnel status:
```bash
tailscale funnel status
```

Verify Tailscale hostname is set correctly:
```bash
grep tailscaleHostname /etc/nixos/private/secrets.nix
```

**Clients:**
- Browser extensions: Chrome, Firefox, Safari, Edge
- Desktop apps: Windows, macOS, Linux
- Mobile apps: iOS, Android
- CLI: `bw` command-line tool

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

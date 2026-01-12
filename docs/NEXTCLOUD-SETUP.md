# Nextcloud Setup Guide for NixOS

## Overview

This guide covers the complete setup of Nextcloud on NixOS 25.05, including:
- External drive configuration
- Nextcloud service setup
- Nginx reverse proxy configuration
- Monitoring integration
- iOS app connectivity
- Security considerations

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [External Drive Setup](#external-drive-setup)
3. [Nextcloud Configuration](#nextcloud-configuration)
4. [Monitoring Setup](#monitoring-setup)
5. [DNS Configuration](#dns-configuration)
6. [iOS App Setup](#ios-app-setup)
7. [Security Warnings](#security-warnings)
8. [Troubleshooting](#troubleshooting)
9. [Gotchas and Lessons Learned](#gotchas-and-lessons-learned)

---

## Prerequisites

- NixOS 25.05 installed and running
- AdGuard Home configured (for DNS rewrites)
- Tailscale configured (for remote access)
- Nginx enabled
- Prometheus/Grafana monitoring stack (optional but recommended)

---

## External Drive Setup

### 1. Format the Drive (One-Time, Imperative)

**⚠️ WARNING: This will DESTROY all data on the drive!**

```bash
# Find your drive
lsblk

# Format the drive (adjust /dev/sdX1 to your actual device!)
sudo mkfs.ext4 -L nextcloud-data /dev/sdX1

# Get the UUID (you'll need this for the next step)
sudo blkid /dev/sdX1
```

### 2. Add Mount Point (Declarative)

Edit `/etc/nixos/hardware-configuration.nix` and add:

```nix
fileSystems."/mnt/nextcloud-data" = {
  device = "/dev/disk/by-uuid/YOUR-UUID-HERE";  # Replace with your actual UUID
  fsType = "ext4";
  options = [ "nofail" ];  # System will boot even if drive is missing
};
```

### 3. Apply and Verify

```bash
sudo nixos-rebuild switch
sudo mount -a
df -h /mnt/nextcloud-data  # Verify it's mounted
```

---

## Nextcloud Configuration

### 1. Create Admin Password File

```bash
# Generate a strong random password
openssl rand -base64 32 | sudo tee /etc/nixos/private/nextcloud-admin-pass

# Secure the file
sudo chmod 644 /etc/nixos/private/nextcloud-admin-pass  # Readable by services
```

**Note:** The file needs 644 permissions (not 600) so the Nextcloud exporter can read it.

### 2. Configure Nextcloud Service

Nextcloud is already configured in `/etc/nixos/modules/services.nix`:

```nix
# ═══════════════════════════════════════════════════════════════════════════
# NEXTCLOUD - PRIVATE CLOUD
# ═══════════════════════════════════════════════════════════════════════════
services.nextcloud = {
  enable = true;
  package = pkgs.nextcloud31;
  hostName = "nextcloud.home";

  database.createLocally = true;
  config = {
    dbtype = "pgsql";
    adminpassFile = "/etc/nixos/private/nextcloud-admin-pass";
  };

  datadir = "/mnt/nextcloud-data";
  https = false;

  settings = {
    "auth.bruteforce.protection.enabled" = false;  # ⚠️ INSECURE - see security section
    "ratelimit.protection.enabled" = false;        # ⚠️ INSECURE - see security section
    "overwriteprotocol" = "http";
    trusted_domains = [
      "nextcloud.home"
      "localhost"
      "nextcloud.vpn"
    ];
    trusted_proxies = [
      "100.64.0.0/10"  # Entire Tailscale IP range
    ];
    "log_type" = "file";
    "logfile" = "/mnt/nextcloud-data/data/nextcloud.log";
    "loglevel" = 2;  # 0=Debug, 1=Info, 2=Warning, 3=Error, 4=Fatal
  };

  autoUpdateApps.enable = true;
  autoUpdateApps.startAt = "05:00:00";
};

# Configure Nextcloud to use port 8280 to avoid conflict with AdGuard Home
services.nginx.virtualHosts."nextcloud.home".listen = [
  { addr = "0.0.0.0"; port = 8280; }
  { addr = "[::]"; port = 8280; }
];
```

### 3. Apply Configuration

```bash
sudo nixos-rebuild switch
```

### 4. Initial Access

- **Local URL:** http://nextcloud.home:8280
- **Direct IP:** http://YOUR-SERVER-IP:8280
- **Username:** `root`
- **Password:** Contents of `/etc/nixos/private/nextcloud-admin-pass`

---

## Monitoring Setup

### 1. Enable Nextcloud Prometheus Exporter

Already configured in `/etc/nixos/modules/monitoring.nix`:

```nix
services.prometheus.exporters.nextcloud = {
  enable = true;
  url = "http://nextcloud.home:8280";
  username = "root";
  passwordFile = "/etc/nixos/private/nextcloud-admin-pass";
  port = 9205;
};
```

### 2. Add Scrape Configs

In the `services.prometheus.scrapeConfigs` section of `/etc/nixos/modules/monitoring.nix`:

```nix
# Nextcloud metrics exporter
{
  job_name = "nextcloud";
  static_configs = [{
    targets = [ "localhost:9205" ];
  }];
}

# Nextcloud HTTP health check
{
  job_name = "nextcloud-http";
  metrics_path = "/probe";
  params.module = [ "http_2xx" ];
  static_configs = [{
    targets = [ "http://nextcloud.home:8280" ];
  }];
  relabel_configs = [
    {
      source_labels = [ "__address__" ];
      target_label = "__param_target";
    }
    {
      source_labels = [ "__param_target" ];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement = "localhost:9115";
    }
  ];
}
```

### 3. Add Alert Rules

In the `services.prometheus.rules` section:

```nix
- name: nextcloud
  rules:

    - alert: NextcloudDown
      expr: probe_success{job="nextcloud-http"} == 0
      for: 15m
      labels:
        severity: critical
      annotations:
        summary: "Nextcloud is unreachable"
        description: "Nextcloud HTTP check has failed for 15 minutes"

    - alert: NextcloudDiskSpaceLow
      expr: (nextcloud_system_disk_free_bytes / nextcloud_system_disk_total_bytes) < 0.1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Nextcloud disk space low"
        description: "Less than 10% free space on Nextcloud data drive"
```

### 4. Apply and Verify

```bash
sudo nixos-rebuild switch

# Check exporter is running
curl http://localhost:9205/metrics

# Check Prometheus targets
# Visit http://prometheus.home and check Status > Targets
```

---

## DNS Configuration

### 1. Add DNS Rewrite in AdGuard Home

1. Open AdGuard Home: http://adguard.home
2. Go to **Filters** → **DNS rewrites**
3. Add rewrite:
   - **Domain:** `nextcloud.home`
   - **Answer:** `YOUR-SERVER-IP`
4. Save

### 2. Add Tailscale DNS Rewrite (Optional)

If you want `nextcloud.vpn` to work:

1. In AdGuard Home, add another rewrite:
   - **Domain:** `nextcloud.vpn`
   - **Answer:** `YOUR-SERVER-IP`
2. Save

### 3. Verify DNS

```bash
# From any device on your network
nslookup nextcloud.home
nslookup nextcloud.vpn  # If configured
```

---

## iOS App Setup

### 1. Install Nextcloud App

Download from the App Store: **Nextcloud - Files & Photos**

### 2. Configure Connection

**Via Tailscale (Recommended):**
- **Server URL:** `http://nextcloud.vpn:8280`
- **Username:** `root`
- **Password:** (from `/etc/nixos/private/nextcloud-admin-pass`)

**Via Local Network:**
- **Server URL:** `http://nextcloud.home:8280`
- **Username:** `root`
- **Password:** (from `/etc/nixos/private/nextcloud-admin-pass`)

### 3. Trust Certificate Warning

The iOS app will show a warning about HTTP. This is expected since we're not using HTTPS. Tap **Trust** to proceed.

**Note:** The app may still show `https://` in the URL bar even though you entered `http://`. This is a cosmetic issue and doesn't affect functionality.

---

## Security Warnings

### ⚠️ CRITICAL: This Configuration is INSECURE by Design

This Nextcloud setup is intentionally configured for local/Tailscale-only access and has the following security protections **DISABLED**:

```nix
"auth.bruteforce.protection.enabled" = false;
"ratelimit.protection.enabled" = false;
```

Additionally:
- Uses HTTP without encryption
- No SSL/TLS certificates
- No rate limiting on login attempts
- No brute-force protection

### ✅ Safe Use Cases

This configuration is **ONLY SAFE** for:
- Local network access (behind your router's firewall)
- Tailscale VPN access (encrypted tunnel)
- Trusted home/office networks

### 🚨 DO NOT Expose to the Internet

If you plan to expose Nextcloud to the public internet, you **MUST**:

1. **Enable HTTPS with proper SSL certificates:**
   ```nix
   https = true;
   # Add SSL certificate configuration
   ```

2. **Re-enable security protections:**
   ```nix
   "auth.bruteforce.protection.enabled" = true;
   "ratelimit.protection.enabled" = true;
   ```

3. **Review Nextcloud security hardening:**
   - [Nextcloud Security Hardening Guide](https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html)
   - Enable 2FA for all users
   - Configure proper firewall rules
   - Set up fail2ban or similar intrusion prevention
   - Use a reverse proxy with SSL termination (Caddy, Traefik, or Nginx with Let's Encrypt)

**Exposing this default configuration to the internet WILL result in your server being compromised.**

---

## Troubleshooting

### Nextcloud Won't Start

**Check PostgreSQL:**
```bash
sudo systemctl status postgresql
sudo journalctl -u postgresql -n 50
```

**Check PHP-FPM:**
```bash
sudo systemctl status phpfpm-nextcloud
sudo journalctl -u phpfpm-nextcloud -n 50
```

**Check Nginx:**
```bash
sudo systemctl status nginx
sudo journalctl -u nginx -n 50
```

### Can't Access Nextcloud

**Verify port 8280 is listening:**
```bash
sudo ss -tlnp | grep 8280
```

**Check Nginx configuration:**
```bash
sudo nginx -t
```

**Verify DNS rewrite:**
```bash
nslookup nextcloud.home
```

### iOS App Can't Connect

**Common issues:**
- **Wrong port:** Make sure you include `:8280` in the URL
- **DNS not working:** Try using the direct IP address instead
- **Firewall blocking:** Check if your firewall allows port 8280
- **Tailscale not connected:** Verify Tailscale is active on your iOS device

**Test from command line:**
```bash
curl -I http://nextcloud.home:8280
curl -I http://nextcloud.vpn:8280
```

### Prometheus Exporter Fails

**Check password file permissions:**
```bash
ls -la /etc/nixos/private/nextcloud-admin-pass
# Should be: -rw-r--r-- (644)
```

**Fix permissions if needed:**
```bash
sudo chmod 644 /etc/nixos/private/nextcloud-admin-pass
```

**Verify exporter is running:**
```bash
sudo systemctl status prometheus-nextcloud-exporter
curl http://localhost:9205/metrics
```

### False Alerts: "NextcloudDown"

If you're getting frequent false alerts about Nextcloud being down:

1. **Check the alert threshold** - default is 15 minutes
2. **Review Nextcloud logs:**
   ```bash
   sudo tail -f /mnt/nextcloud-data/data/nextcloud.log
   ```
3. **Check for background jobs causing brief unavailability:**
   ```bash
   sudo journalctl -u phpfpm-nextcloud -f
   ```
4. **Increase alert threshold if needed** (in `monitoring.nix`):
   ```nix
   for: 30m  # Increase from 15m to 30m
   ```

---

## Gotchas and Lessons Learned

### 1. Port Conflict with AdGuard Home

**Problem:** Nextcloud's Nginx module defaults to port 80, which conflicts with AdGuard Home.

**Solution:** Explicitly configure Nextcloud to use port 8280:
```nix
services.nginx.virtualHosts."nextcloud.home".listen = [
  { addr = "0.0.0.0"; port = 8280; }
  { addr = "[::]"; port = 8280; }
];
```

**Lesson:** Always check which ports your services are using. Use `sudo ss -tlnp` to see what's listening.

### 2. Password File Permissions

**Problem:** Nextcloud Prometheus exporter fails with permission denied error.

**Solution:** Password file needs 644 permissions (not 600):
```bash
sudo chmod 644 /etc/nixos/private/nextcloud-admin-pass
```

**Lesson:** System services often run as different users and need read access to shared files.

### 3. iOS App Prefers HTTPS

**Problem:** iOS app shows HTTPS in the URL bar even when configured for HTTP.

**Solution:** This is cosmetic only. The app still connects via HTTP on port 8280. Just ignore the display.

**Lesson:** Mobile apps often have opinionated defaults. Test actual connectivity, not just UI display.

### 4. Tailscale Trusted Proxies

**Problem:** Nextcloud doesn't trust connections from Tailscale IP range.

**Solution:** Add Tailscale CGNAT range to `trusted_proxies`:
```nix
trusted_proxies = [
  "100.64.0.0/10"  # Entire Tailscale IP range
];
```

**Lesson:** Always configure trusted proxy ranges when using VPNs or reverse proxies.

### 5. File-Based Logging vs. Systemd Journal

**Problem:** Nextcloud logs only go to systemd journal by default, making debugging harder.

**Solution:** Enable file-based logging:
```nix
settings = {
  "log_type" = "file";
  "logfile" = "/mnt/nextcloud-data/data/nextcloud.log";
  "loglevel" = 2;
};
```

**Lesson:** File-based logs are easier to grep, tail, and share. Enable them for complex services.

### 6. External Drive Must Use `nofail` Option

**Problem:** System won't boot if external drive is disconnected.

**Solution:** Add `nofail` to mount options:
```nix
options = [ "nofail" ];
```

**Lesson:** Always use `nofail` for non-critical external drives to prevent boot failures.

### 7. Alert Threshold Too Aggressive

**Problem:** Getting false "NextcloudDown" alerts from brief network hiccups or background jobs.

**Solution:** Increase alert threshold from 5 minutes to 15 minutes:
```nix
for: 15m
```

**Lesson:** Start with conservative alert thresholds and tune based on actual service behavior.

### 8. Nextcloud Needs Reboot After First Install

**Problem:** Nextcloud doesn't fully initialize on first `nixos-rebuild switch`.

**Solution:** Reboot after first Nextcloud installation:
```bash
sudo nixos-rebuild switch
sudo reboot
```

**Lesson:** Some services need a full system restart to initialize properly, especially database-backed applications.

### 9. DNS Rewrites Required for Clean URLs

**Problem:** Can't access Nextcloud via `nextcloud.home` without DNS configuration.

**Solution:** Add DNS rewrites in AdGuard Home for all service hostnames.

**Lesson:** Local DNS is critical for a clean home server experience. Set it up early.

### 10. Security Settings Are Dangerous

**Problem:** Default config has brute-force protection disabled for convenience.

**Solution:** Document clearly and warn users not to expose to internet.

**Lesson:** Always prioritize security warnings in documentation. Make dangers explicit and obvious.

---

## Additional Resources

- [Nextcloud NixOS Options](https://search.nixos.org/options?channel=25.05&show=services.nextcloud)
- [Nextcloud Admin Manual](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Nextcloud Security Hardening](https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html)
- [NixOS Manual - Services](https://nixos.org/manual/nixos/stable/#ch-configuration)

---

## Summary

This guide provides a complete, declarative Nextcloud setup for NixOS 25.05 with:

- ✅ External drive configuration
- ✅ PostgreSQL database
- ✅ Nginx reverse proxy on port 8280
- ✅ Prometheus monitoring and alerting
- ✅ iOS app connectivity
- ✅ Tailscale integration
- ✅ Comprehensive troubleshooting

**Remember:** This configuration is designed for local/Tailscale access only. Do not expose it to the public internet without proper security hardening.

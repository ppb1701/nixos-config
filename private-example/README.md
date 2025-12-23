# Private Configuration Examples

⚠️ **WARNING: THESE ARE EXAMPLE FILES ONLY**

The files in this directory show the **structure** of what needs to be in `/etc/nixos/private/`.

**THESE EXAMPLE FILES DO NOT WORK AND MUST NOT BE USED AS-IS.**

You must create your own `/etc/nixos/private/` directory with real credentials.

---

## Setup Instructions

1. Copy the structure:
   sudo mkdir -p /etc/nixos/private
   sudo cp private-example/* /etc/nixos/private/

2. Fill in real values in each file (see below)

3. Set proper permissions:
   sudo chmod 600 /etc/nixos/private/*
   sudo chown root:root /etc/nixos/private/*

---

## File Descriptions

### secrets.nix
Contains passwords for services that need them in the Nix configuration.

Required values:
- grafanaPassword: Admin password for Grafana web interface

### ssh-keys.nix
Contains your SSH public keys for remote access.

Required values:
- authorizedKeys: List of SSH public keys (generate with ssh-keygen -t ed25519)

### syncthing-secrets.nix
Contains Syncthing configuration including devices, folders, and authentication.

Required values:
- gui.user: Username for Syncthing web interface
- gui.password: Password for Syncthing web interface
- prometheus_auth.username: Username for Prometheus to scrape Syncthing metrics
- prometheus_auth.password: Password for Prometheus authentication
- devices: Your Syncthing devices (get IDs from each device's web UI)
- folders: Folders to sync across devices

Note: The prometheus_auth credentials should match the Syncthing GUI credentials

### alertmanager.env
Contains SMTP credentials for email alerts (optional).

Required values:
- SMTP_USERNAME: Your full email address
- SMTP_PASSWORD: App-specific password from your email provider
- EMAIL_TO: Where you want to receive alerts

Note: Alertmanager will fail to start until this is configured with real credentials. All other services work independently.

### notediscovery-config.yaml (optional)
Configuration for NoteDiscovery web-based knowledge base.

Required values:
- password_hash: Generate with generate_password.py script
- notes_path: Path to your Syncthing-synced notes folder

Note: Only needed if you're using NoteDiscovery service.

---

## Security Notes

- Never commit the real /etc/nixos/private/ directory to git
- The .gitignore file already excludes it
- These example files are safe to commit (they contain no real credentials)
- Always use strong, unique passwords
- Use app-specific passwords for email (never your main account password)

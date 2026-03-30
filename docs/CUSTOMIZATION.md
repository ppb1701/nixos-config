# Customization Guide

This guide shows you how to customize your NixOS AdGuard Home server to fit your specific needs.

## Quick Configuration Editing

The system includes convenient shell aliases for quick editing. Type `help` for a full list:

```bash
# Edit service configurations
es      # Edit modules/services.nix (AdGuard, Syncthing, Tailscale, Nginx)
en      # Edit modules/networking.nix (network, firewall, DNS)
esy     # Edit modules/system.nix (packages, users, desktop)
eh      # Edit home/ppb1701.nix (shell, aliases, prompt)
ec      # Edit main configuration.nix

# Quick rebuild
rebuild # Rebuild and switch (auto-reloads shell)
```

## Adding Filter Lists

### Finding Filter Lists

Good sources for filter lists:

- **AdGuard Filter List Registry:** https://github.com/AdguardTeam/HostlistsRegistry
- **FilterLists:** https://filterlists.com/
- **StevenBlack hosts:** https://github.com/StevenBlack/hosts

### Adding a New Filter List

AdGuard Home filter lists are configured in the web UI, not in configuration files:

1. Access AdGuard Home web UI: http://adguard.home (or http://192.168.1.154:3000)
2. Go to Settings → DNS settings → DNS blocklists
3. Click "Add blocklist"
4. Enter URL and name
5. Click "Add"

The configuration in `modules/services.nix` only sets basic AdGuard Home settings. Filter lists are managed through the web UI and stored in AdGuard's data directory

### Creating Your Own Filter List

Create a text file with one domain per line:

```
# My custom blocks
ads.example.com
tracker.example.com
telemetry.example.com
```

Host it somewhere accessible (Codeberg Gist, your own server, etc.) and add the URL to your configuration.

### Disabling Filter Lists

Set `enabled = false`:

```nix
{
  enabled = false;  # Temporarily disable
  url = "https://example.com/list.txt";
  name = "Disabled List";
  id = 5;
}
```

## Custom Filtering Rules

### Adding User Rules

Custom filtering rules are added through the AdGuard Home web UI:

1. Access http://adguard.home (or http://192.168.1.154:3000)
2. Go to Settings → DNS settings → DNS blocklists
3. Scroll to "Custom filtering rules"
4. Add your rules

**Rule examples:**
```
# Block specific domain
||ads.example.com^

# Allow specific domain (whitelist)
@@||allowed.example.com^

# Block subdomain
||*.tracking.example.com^

# Block with wildcard
||*-ads.example.com^

# CSS rule (hide element)
example.com##.advertisement
```

### Rule Syntax

**Block domain:**
```
||domain.com^
```

**Allow domain (exception):**
```
@@||domain.com^
```

**Block subdomain:**
```
||*.subdomain.com^
```

**Block URL pattern:**
```
||domain.com/path/*
```

**CSS selector (cosmetic filtering):**
```
domain.com##.class-name
domain.com###id-name
```

### Common Use Cases

**Allow streaming services:**

```nix
user_rules = [
  "@@||netflix.com^"
  "@@||*.netflix.com^"
  "@@||nflxvideo.net^"
  "@@||*.nflxvideo.net^"
];
```

**Block social media trackers:**

```nix
user_rules = [
  "||facebook.com/tr/*"
  "||connect.facebook.net^"
  "||*.facebook.com/plugins/*"
];
```

**Block telemetry:**

```nix
user_rules = [
  "||telemetry.microsoft.com^"
  "||vortex.data.microsoft.com^"
  "||*.telemetry.mozilla.org^"
];
```

## Network Configuration

### Changing Static IP

Edit `modules/networking.nix`:

```nix
interfaces.eno1 = {
  ipv4.addresses = [{
    address = "192.168.1.200";  # Your new IP
    prefixLength = 24;
  }];
};
```

**Remember to update:**
- Router DHCP reservations
- Client DNS settings
- Firewall rules if needed

### Using Different Interface

**Find your interface name:**

```bash
ip link show
```

**Update configuration:**

```nix
interfaces.enp2s0 = {  # Your interface name
  ipv4.addresses = [{
    address = "192.168.1.154";
    prefixLength = 24;
  }];
};
```

### Multiple Network Interfaces

```nix
interfaces = {
  eno1 = {
    ipv4.addresses = [{
      address = "192.168.1.154";
      prefixLength = 24;
    }];
  };
  eno2 = {
    ipv4.addresses = [{
      address = "10.0.0.154";
      prefixLength = 24;
    }];
  };
};
```

### Adding IPv6

```nix
interfaces.eno1 = {
  ipv4.addresses = [{
    address = "192.168.1.154";
    prefixLength = 24;
  }];
  ipv6.addresses = [{
    address = "2001:db8::154";
    prefixLength = 64;
  }];
};
```

## Firewall Customization

### Opening Additional Ports

Edit `modules/networking.nix` or create `modules/firewall.nix`:

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 
    22    # SSH
    3000  # AdGuard Home
    8080  # Custom service
  ];
  allowedUDPPorts = [ 
    53    # DNS
    5353  # mDNS
  ];
};
```

### Port Forwarding

```nix
networking.nat = {
  enable = true;
  internalInterfaces = [ "eno1" ];
  externalInterface = "eno2";
  forwardPorts = [
    {
      destination = "192.168.1.100:80";
      proto = "tcp";
      sourcePort = 8080;
    }
  ];
};
```

### Custom Firewall Rules

```nix
networking.firewall.extraCommands = ''
  # Allow from specific subnet
  iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT

  # Block specific IP
  iptables -A INPUT -s 192.168.1.50 -j DROP

  # Rate limit SSH
  iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
  iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
'';
```

## User Configuration

### Adding More Users

Edit `configuration.nix`:

```nix
users.users = {
  youruser = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPassword = "...";
  };

  anotheruser = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" ];
    hashedPassword = "...";
  };
};
```

### Changing User Shell

```nix
users.users.youruser = {
  isNormalUser = true;
  shell = pkgs.zsh;  # or pkgs.fish, pkgs.bash
  extraGroups = [ "wheel" ];
};
```

### Adding SSH Keys

```nix
users.users.youruser = {
  isNormalUser = true;
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... user@host"
    "ssh-rsa AAAAB3... user@another-host"
  ];
};
```

## System Packages

### Adding System-Wide Packages

Edit `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  vim
  git
  htop
  tmux
  curl
  wget
  # Add your packages here
  neofetch
  ncdu
  iotop
];
```

### Adding User Packages (Home Manager)

Edit `home/youruser.nix`:

```nix
home.packages = with pkgs; [
  # Development tools
  vscode
  docker

  # Utilities
  ripgrep
  fd
  bat

  # Your packages
];
```

## AdGuard Home Customization

AdGuard Home configuration is split between NixOS configuration and the web UI:

### Basic Settings (in modules/services.nix)

Edit with: `es` or `sudo micro /etc/nixos/modules/services.nix`

```nix
services.adguardhome = {
  enable = true;
  mutableSettings = true;  # Allow web UI changes
  host = "0.0.0.0";        # Listen on all interfaces
  port = 3000;             # Web UI port

  settings = {
    dns = {
      bind_hosts = [ "0.0.0.0" ];
      port = 53;

      # Upstream DNS servers (Control D + Quad9)
      upstream_dns = [
        "76.76.2.2"         # Control D
        "76.76.10.2"        # Control D
        "9.9.9.9"           # Quad9
        "149.112.112.112"   # Quad9
      ];

      bootstrap_dns = [
        "9.9.9.9"
        "149.112.112.112"
      ];

      enable_dnssec = true;
    };
  };
};
```

**After changes:** Run `rebuild` to apply

### Changing Ports

**Web UI port:**
- Edit `port = 3000;` in `modules/services.nix`
- Update Nginx reverse proxy in same file
- Update firewall in `modules/networking.nix`
- Rebuild: `rebuild`

**DNS port:**
- Edit `port = 53;` in the `dns` section
- Update firewall UDP port
- Note: Non-standard DNS ports require client configuration

### Advanced Settings (in Web UI)

Most AdGuard Home settings are best configured through the web UI:

- Filter lists and custom rules
- DNS cache settings
- Query logging preferences
- Client settings
- DHCP server (if needed)
- Parental controls

Access: http://adguard.home or http://192.168.1.154:3000

## Adding Services

Services are now consolidated in `modules/services.nix`. To add a new service, edit this file and add your service configuration.

### Syncthing Configuration

Syncthing is configured in `modules/services.nix` with private settings in `private/syncthing-secrets.nix`.

#### Initial Setup

1. **Create private configuration file:**

   ```bash
   sudo micro /etc/nixos/private/syncthing-secrets.nix
   ```

2. **Add your settings** to `syncthing-secrets.nix`:

   ```nix
   {
     gui = {
       user = "ppb1701";
       password = "your-secure-password-here";
     };

     devices = {
       # Your devices here...
     };

     folders = {
       # Your folders here...
     };
   }
   ```

3. **Get device IDs** from each device you want to sync:
   - Install Syncthing on the device
   - Open web UI: `http://localhost:8384`
   - Go to Actions → Show ID
   - Copy the device ID (format: `ABCDEFG-HIJKLMN-...`)

4. **Configure devices and folders** in `private/syncthing-secrets.nix`:

   ```nix
   {
     services.syncthing.settings = {
       devices = {
         "windows-desktop" = {
           id = "ABCDEFG-HIJKLMN-OPQRSTU-VWXYZAB-CDEFGHI-JKLMNOP-QRSTUVW-XYZABCD";
         };
         "macbook" = {
           id = "BCDEFGH-IJKLMNO-PQRSTUV-WXYZABC-DEFGHIJ-KLMNOPQ-RSTUVWX-YZABCDE";
         };
       };

       folders = {
         "Documents" = {
           path = "/home/ppb1701/Documents";
           devices = [ "windows-desktop" "macbook" ];
           versioning = {
             type = "simple";
             params.keep = "5";
           };
         };
         "Photos" = {
           path = "/home/ppb1701/Pictures";
           devices = [ "macbook" ];
           ignorePerms = false;
         };
       };
     };
   }
   ```

5. **Rebuild the system:**

   ```bash
   sudo nixos-rebuild switch
   ```

6. **Access Syncthing web UI:**
   - URL: `http://192.168.1.154:8384`
   - Username: `ppb1701`
   - Password: (from syncthing-secrets.nix)

#### Adding More Devices

Edit `private/syncthing-secrets.nix` and add to the `devices` section:

```nix
devices = {
  "existing-device" = {
    id = "ABCDEFG-HIJKLMN-...";
  };
  "new-device" = {
    id = "NEWDEVIC-EIDHERE-...";
  };
};
```

Then add the device to folders you want to share:

```nix
folders = {
  "Documents" = {
    path = "/home/ppb1701/Documents";
    devices = [ "existing-device" "new-device" ];
  };
};
```

**After changes:** Run `rebuild` to apply

#### Syncthing Settings

**Folder options:**

```nix
folders = {
  "My Folder" = {
    path = "/home/ppb1701/MyFolder";
    devices = [ "device1" "device2" ];
    
    # File versioning
    versioning = {
      type = "simple";  # or "trashcan", "staggered", "external"
      params.keep = "10";
    };
    
    # Ignore patterns
    ignorePerms = false;  # Preserve permissions
    
    # Rescan interval
    rescanIntervalS = 3600;  # Check every hour
    
    # Watch for changes
    fsWatcherEnabled = true;
    
    # File pull order
    order = "random";  # or "alphabetic", "smallestFirst", "largestFirst"
  };
};
```

**GUI options:**

```nix
settings.gui = {
  user = "ppb1701";
  password = "...";  # Set in syncthing-secrets.nix
  theme = "dark";  # or "light", "black"
  debugging = false;
  insecureSkipHostcheck = false;
};
```

**Global options:**

```nix
settings.options = {
  urAccepted = -1;  # Disable usage reporting
  localAnnounceEnabled = true;
  globalAnnounceEnabled = true;
  relaysEnabled = true;
  natEnabled = true;
  startBrowser = false;
};
```

#### Troubleshooting Syncthing

**Devices not discovering each other:**

1. Manually add device addresses in `private/syncthing-secrets.nix`:

   ```nix
   devices = {
     "my-device" = {
       id = "ABCDEFG-...";
       addresses = [ "tcp://192.168.1.100:22000" ];
     };
   };
   ```

2. Check firewall allows Syncthing ports:

   ```bash
   ss -tlnp | grep 22000  # Sync port (use sts alias)
   ss -tlnp | grep 8384   # Web UI port
   ```

3. Verify Syncthing is running:

   ```bash
   sts   # Status alias
   stl   # Logs alias
   # Or manually:
   systemctl status syncthing
   journalctl -u syncthing -f
   ```

**Files not syncing:**

- Check folder status in web UI: http://syncthing.home
- Verify folder paths exist and are writable
- Check disk space: `diskspace` alias
- Review ignore patterns

### Adding a New Service

Services are consolidated in `modules/services.nix`. To add a new service:

1. **Edit services module:**
   ```bash
   es  # Quick edit alias
   # Or: sudo micro /etc/nixos/modules/services.nix
   ```

2. **Add service configuration:**
   ```nix
   # ═══════════════════════════════════════════════════════════════════════════
   # YOUR NEW SERVICE
   # ═══════════════════════════════════════════════════════════════════════════
   services.your-service = {
     enable = true;
     port = 8080;
     # Service-specific options
   };
   ```

3. **Update firewall (if needed):**
   ```bash
   en  # Edit networking.nix
   ```

   Add to `allowedTCPPorts` or `allowedUDPPorts`:
   ```nix
   networking.firewall.allowedTCPPorts = [
     # ... existing ports ...
     8080  # Your new service
   ];
   ```

4. **Rebuild:**
   ```bash
   rebuild  # Applies changes and reloads shell
   ```

**For complex services**, you can still create a separate module file and import it in `configuration.nix`

### Example: Adding Netdata to modules/services.nix

**Edit:** `es` or `sudo micro /etc/nixos/modules/services.nix`

**Add to the file:**

```nix
# ═══════════════════════════════════════════════════════════════════════════
# NETDATA - SYSTEM MONITORING
# ═══════════════════════════════════════════════════════════════════════════
services.netdata = {
  enable = true;
  config = {
    global = {
      "default port" = "19999";
      "bind to" = "*";
    };
  };
};
```

**Update firewall:** `en` or `sudo micro /etc/nixos/modules/networking.nix`

Add `19999` to `allowedTCPPorts`, then `rebuild`

### Tailscale (Already Included!)

Tailscale is already configured in `modules/services.nix`:

```nix
# ═══════════════════════════════════════════════════════════════════════════
# TAILSCALE - SECURE REMOTE ACCESS
# ═══════════════════════════════════════════════════════════════════════════
services.tailscale = {
  enable = true;
  useRoutingFeatures = "client";
};
```

To activate: `sudo tailscale up` (after rebuild)

## Boot Configuration

### Changing Bootloader

**For GRUB:**

```nix
boot.loader.grub = {
  enable = true;
  device = "/dev/sda";
  # Or for UEFI:
  # efiSupport = true;
  # device = "nodev";
};
```

**For systemd-boot:**

```nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

### Kernel Parameters

```nix
boot.kernelParams = [
  "quiet"
  "splash"
  "nomodeset"  # If having graphics issues
];
```

### Kernel Modules

```nix
boot.kernelModules = [ "kvm-intel" "vfio-pci" ];
boot.blacklistedKernelModules = [ "nouveau" ];
```

## Backup Configuration

### Automated Backups with Restic

**Create `modules/backup.nix`:**

```nix
{ config, pkgs, ... }:

{
  services.restic.backups = {
    daily = {
      paths = [
        "/var/lib/AdGuardHome"
        "/home"
      ];
      repository = "/mnt/backup";
      passwordFile = "/etc/nixos/secrets/restic-password";
      timerConfig = {
        OnCalendar = "daily";
      };
    };
  };
}
```

## Tips and Best Practices

### Keep Modules Small and Focused

**Good:**

```
modules/
├── adguard-home.nix    # Just AdGuard Home
├── networking.nix      # Just network config
├── syncthing.nix       # Just Syncthing
└── monitoring.nix      # Just monitoring
```

**Bad:**

```
modules/
└── everything.nix      # Everything in one file
```

### Use Comments

```nix
# AdGuard Home configuration
services.adguardhome = {
  enable = true;

  # Web interface settings
  settings.http = {
    address = "0.0.0.0:3000";
  };

  # DNS settings
  settings.dns = {
    # Listen on all interfaces
    bind_hosts = [ "0.0.0.0" ];
    port = 53;
  };
};
```

### Test Changes in VM First

```bash
# Build VM
nixos-rebuild build-vm

# Test in VM
./result/bin/run-nixos-vm

# If good, apply to real system
nixos-rebuild switch
```

### Keep Configuration in Git

```bash
# After making changes
git add modules/
git commit -m "Add custom filter list"
git push
```

### Document Your Changes

Add comments explaining why you made changes:

```nix
# Increased cache size because we have 16GB RAM
# and want faster DNS responses
dns.cache_size = 10000000;
```

## Getting Help

- **NixOS Options Search:** https://search.nixos.org/options
- **NixOS Manual:** https://nixos.org/manual/nixos/stable/
- **Home Manager Options:** https://nix-community.github.io/home-manager/options.html

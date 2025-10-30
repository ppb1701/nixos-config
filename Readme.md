# NixOS AdGuard Home Server

A fully declarative, reproducible AdGuard Home DNS server built with NixOS. This configuration is designed to be:

- **Declarative:** Everything defined in code
- **Reproducible:** Rebuild identical systems anytime
- **Disaster-proof:** Complete recovery in 20 minutes
- **Privacy-focused:** Ad-blocking DNS with local control

## Blog Series

This repository is the companion code for my blog series:

**Building a Declarative AdGuard Home Server with NixOS**  
https://blog.ppb1701.com/nixos-adguard-series

**Discussion:** [@ppb1701@ppb.social](https://ppb.social/@ppb1701)

## Features

### Core Services

- **AdGuard Home:** Network-wide ad blocking and DNS filtering
- **Declarative Configuration:** All settings in version control
- **Custom Filter Lists:** 12+ curated filter lists
- **Client Identification:** Reverse DNS lookup for device names

### Optional Services

- **Syncthing:** Cross-platform file synchronization (optional)
- **Monitoring:** System monitoring with Netdata (optional)
- **Remote Access:** Tailscale VPN integration (optional)

### Infrastructure

- **Custom ISO:** Bootable installation image with configuration baked in
- **Automated Install:** Zero-touch deployment script
- **GitHub Integration:** Configuration managed via Git
- **Modular Design:** Easy to add/remove services

## Quick Start

### Option 1: Custom ISO (Recommended)

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

### Option 2: Manual Installation

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
users.users.youruser = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  hashedPassword = "...";
};
```

- Change `youruser` to your username
- `hashedPassword` will be set during installation

#### Hardware Configuration

**Important:** Replace `hardware-configuration.nix` with output from:

```bash
nixos-generate-config --show-hardware-config
```

### Optional Services

#### Syncthing (File Sync)

**Setup:**

1. Copy the example template:
   ```bash
   cp private/syncthing-devices.nix.example private/syncthing-devices.nix
   ```

2. Get device IDs from each device:
   - Install Syncthing
   - Open web UI: http://localhost:8384
   - Actions → Show ID
   - Copy the device ID

3. Edit `private/syncthing-devices.nix`:
   ```nix
   services.syncthing.settings = {
     devices = {
       "my-laptop" = {
         id = "ABCDEFG-1234567-...";
       };
     };
     folders = {
       "Documents" = {
         path = "/home/youruser/Documents";
         devices = [ "my-laptop" ];
       };
     };
   };
   ```
   - Paste your device ID where it says `ABCDEFG-1234567-...`
   - Change `youruser` to your username
   - Add more devices and folders as needed

4. Rebuild:
   ```bash
   sudo nixos-rebuild switch
   ```

> **Note:** The `private/` directory is gitignored to protect your device information.

#### Other Services

See `docs/` directory for guides on:

- Adding monitoring (Netdata, Grafana)
- Setting up remote access (Tailscale, WireGuard)
- Configuring additional services

## Repository Structure

```
nixos-config/
├── configuration.nix              # Main system configuration
├── hardware-configuration.nix     # Hardware-specific settings (example)
├── modules/
│   ├── adguard-home.nix          # AdGuard Home service config
│   ├── networking.nix            # Network configuration
│   └── syncthing.nix             # Syncthing config (optional)
├── home/
│   └── youruser.nix              # Home Manager configuration
├── private/
│   └── syncthing-devices.nix.example  # Template for Syncthing devices
├── iso-config.nix                # Custom ISO configuration
├── build-iso.sh                  # ISO build script
├── install-nixos.sh              # Automated installation script
├── docs/
│   ├── troubleshooting.md        # Common issues and solutions
│   ├── customization.md          # How to customize
│   └── services.md               # Adding additional services
└── README.md                     # This file
```

## Building a Custom ISO

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
├── syncthing-devices.nix          # Your actual devices (gitignored)
└── syncthing-devices.nix.example  # Template (committed)
```

### Building Public ISOs

If you fork this repo and want to share ISOs publicly:

1. Ensure `private/syncthing-devices.nix` is not present
2. Build ISO from clean checkout
3. The resulting ISO will not contain device IDs

See `docs/building-public-isos.md` for details.

## Customization

### Adding Filter Lists

Edit `modules/adguard-home.nix`:

```nix
filters = [
  {
    enabled = true;
    url = "https://example.com/your-list.txt";
    name = "Your Custom List";
    id = 13;
  }
];
```

- Increment the `id` from the last filter in the list

### Adding Services

1. Create a new module in `modules/`:

   ```nix
   # modules/your-service.nix
   { config, pkgs, ... }:
   
   {
     services.your-service = {
       enable = true;
     };
   }
   ```

2. Import in `configuration.nix`:

   ```nix
   imports = [
     ./modules/adguard-home.nix
     ./modules/your-service.nix
   ];
   ```

### Modifying Network Settings

See `modules/networking.nix` for:

- Static IP configuration
- Interface selection
- DNS settings
- Firewall rules

## Troubleshooting

### Common Issues

**AdGuard Home web UI not accessible:**

- Check firewall: `sudo iptables -L`
- Verify service: `systemctl status adguardhome`
- Check binding: `ss -tlnp | grep 3000`

**Syncthing not syncing:**

- Check web UI: http://192.168.1.154:8384
- Verify device IDs are correct
- Check firewall ports (22000, 21027)

**ISO build fails:**

- Ensure sufficient disk space (20GB+)
- Check Nix store: `nix-store --verify --check-contents`
- Try clean build: `rm -rf result && ./build-iso.sh`

See [docs/troubleshooting.md](docs/troubleshooting.md) for more solutions.

### Reporting Issues

Want to discuss? Have a suggestion?

- **Mastodon:** [@ppb1701@ppb.social](https://ppb.social/@ppb1701)
- **Blog Comments:** https://blog.ppb1701.com

## License

MIT License - See [LICENSE](LICENSE) file for details

## Acknowledgments

- NixOS community
- AdGuard Home project
- Everyone who contributed ideas and feedback

---

**Built with ❤️ and NixOS**

NixOS AdGuard Home Server
A fully declarative, reproducible AdGuard Home DNS server configuration for NixOS. This repository contains everything needed to deploy a complete ad-blocking DNS server with custom filter lists and network-wide protection.

🎯 Project Overview
This configuration provides:

AdGuard Home DNS server with declarative filter list management
Custom filtering rules for streaming services and specific domains
Modular configuration for easy maintenance and customization
Custom ISO builder for rapid deployment
Automated installation script with swap file support
Version-controlled setup for reproducibility and disaster recovery
📁 Repository Structure



Plaintext
nixos-adguard-home/
├── configuration.nix           # Main system configuration
├── hardware-configuration.nix  # Hardware-specific settings (generated per-machine)
├── modules/
│   ├── adguard-home.nix       # AdGuard Home service configuration
│   └── networking.nix         # Network settings (DHCP/static IP)
├── home/
│   └── ppb1701.nix            # Home Manager user configuration
├── iso-config.nix             # Custom ISO builder configuration
├── install-nixos.sh           # Automated installation script
├── build-iso.sh               # ISO build script
└── README.md                  # This file
📄 File Descriptions
Core Configuration Files
configuration.nix
Purpose: Main NixOS system configuration file

What it does:

Imports all modules (AdGuard Home, networking, home-manager)
Defines system-wide settings (hostname, timezone, locale)
Configures boot loader and kernel
Enables essential services (SSH, firewall)
Sets up user accounts
hardware-configuration.nix
Purpose: Hardware-specific configuration (auto-generated)

What it does:

Defines boot device and filesystem mounts
Configures swap devices
Sets hardware-specific kernel modules
Generated automatically by nixos-generate-config
Important: This file is machine-specific and will be different on each physical machine. It's generated during installation and should not be manually edited unless you know what you're doing.

Module Files
modules/adguard-home.nix
Purpose: Complete AdGuard Home DNS server configuration

What it does:

Enables and configures AdGuard Home service
Defines declarative filter lists (12-18 lists)
Sets up custom filtering rules for streaming services
Configures DNS upstream servers (Cloudflare, Quad9)
Enables client identification via local PTR lookups
Opens required firewall ports (53, 3000)
Key features:

Declarative Filter Lists:
All filter lists are defined in code, no manual web UI configuration needed. Simply add entries to the filters array and rebuild.

Benefits:

No manual web UI configuration needed
Filter lists are version-controlled
Easy to add/remove/update lists
Reproducible across deployments
Can be shared with others
Custom Filtering Rules:
Pre-configured rules for streaming services and custom blocking/allowing of specific domains.

Rule Syntax:

@@||domain.com^ = Allow (whitelist)
||domain.com^ = Block (blacklist)
|http://example.com = Block specific URL
/regex/ = Block using regex pattern
Recommended Filter Lists:

AdGuard DNS filter - Core ad blocking
Peter Lowe's List - Conservative, low false positives
OISD Small - Balanced blocking
HaGeZi's Pro Blocklist - Aggressive blocking
Malicious URL Blocklist - Security protection
The Big List of Hacked Malware Web Sites - Malware protection
Adding More Filters:
Simply add new entries to the filters array with incremented IDs.

DNS Configuration:

Upstream DNS: Cloudflare DoH, Quad9 DoH
Bootstrap DNS: Quad9 (for DoH resolution)
Client Identification: Enabled via router PTR lookups
Query Logging: 90 days retention
Statistics: 24-hour intervals
modules/networking.nix
Purpose: Network configuration with easy DHCP/static IP toggle

What it does:

Configures network interface
Toggles between DHCP (VM testing) and static IP (production)
Sets default gateway and DNS servers
Enables NetworkManager
Key feature - Easy toggling:
The file contains both DHCP and static IP configurations. DHCP is active by default. To switch to static IP, simply uncomment the static IP section, update the interface name, and rebuild.

To switch to static IP:

Uncomment the static IP section
Update interface name (find with ip addr show)
Update IP address if needed
Run sudo nixos-rebuild switch
home/ppb1701.nix
Purpose: User-specific configuration via Home Manager

What it does:

Configures user environment and dotfiles
Sets up shell (bash/zsh)
Installs user-specific packages
Manages user services
ISO Builder Files
iso-config.nix
Purpose: Defines how to build a custom NixOS installation ISO

What it does:

Imports the base NixOS installation CD configuration
Copies your entire repository into the ISO at /etc/nixos-config/
Adds useful tools to the live environment (git, vim, htop, parted)
Enables SSH in the live environment (password: nixos)
Displays a helpful welcome message on boot
Result: A bootable ISO containing your complete configuration, ready for installation.

build-iso.sh
Purpose: Builds the custom ISO from your configuration

What it does:

Cleans previous build artifacts
Uses nixos-generators to build the ISO
Reports build status and ISO size
Optionally copies ISO to shared folder for easy host access
Usage:
Run ./build-iso.sh and wait 10-20 minutes. Result will be in ./result/iso/nixos-*.iso

Requirements:

NixOS system (or VM)
Internet connection
15-20 GB free disk space
4+ GB RAM recommended
Build time: 10-20 minutes depending on system resources

install-nixos.sh
Purpose: Automated installation script (runs inside the live ISO)

What it does:

Partitions disk - Creates GPT partition table with boot and root partitions
Formats partitions - ext4 for root, FAT32 for boot
Mounts filesystems - Prepares /mnt for installation
Creates swap file - 4GB swap file (configurable)
Copies configuration - Your config from /etc/nixos-config/ to /mnt/etc/nixos/
Generates hardware config - Detects hardware and creates hardware-configuration.nix
Detects network interface - Automatically updates interface name in networking.nix
Installs NixOS - Runs nixos-install with your configuration
Safety features:

Requires typing YES to confirm (prevents accidental wipes)
Clear warning about data destruction
Progress indicators for each step
Error handling (exits on any failure)
Customization:
Edit TARGET_DISK and SWAP_SIZE variables at the top of the script to change target disk or swap size.

Usage:
Boot from custom ISO, login as nixos (password: nixos), run sudo /etc/nixos-config/install-nixos.sh, type YES to confirm, wait 20 minutes, remove USB and reboot.

🚀 Quick Start Guide
Building the ISO (One-Time Setup)
In your NixOS VM or machine:

Clone this repository
Run ./build-iso.sh
Copy ISO to host machine (if building in VM): scp -P 2222 result/iso/nixos-*.iso user@host:~/Downloads/
Flash to USB: sudo dd if=nixos-*.iso of=/dev/sdX bs=4M status=progress && sync
Deploying to Physical Machine
Boot from USB
Login as nixos (password: nixos)
Run installation script: sudo /etc/nixos-config/install-nixos.sh
Type YES to confirm
Wait approximately 20 minutes for installation
Remove USB drive
Reboot
SSH into new system (it will have a DHCP IP initially): ssh ppb1701@<dhcp-ip-address>
Set static IP for AdGuard Home: sudo vim /etc/nixos/modules/networking.nix (uncomment static IP section, update interface name if needed)
Apply changes: sudo nixos-rebuild switch
Configure your router to use 192.168.1.154 as DNS server
Accessing AdGuard Home
Web Interface:

URL: http://192.168.1.154:3000
Initial setup: Create admin account
All filter lists and rules are already configured
DNS Service:

DNS Port: 53
Configure clients to use 192.168.1.154 as DNS server
Or configure router DHCP to distribute this DNS server
🔧 Post-Installation
Updating Filter Lists
Edit modules/adguard-home.nix and add new filter entries to the filters array with incremented IDs. Apply changes with sudo nixos-rebuild switch.

Adding Custom Rules
Edit modules/adguard-home.nix and add rules to the user_rules array. Use @@||domain.com^ to allow domains or ||domain.com^ to block them. Apply changes with sudo nixos-rebuild switch.

Changing Network Settings
Edit modules/networking.nix to change static IP address or interface name. Apply changes with sudo nixos-rebuild switch.

Committing Changes
Always commit your changes to Git:

git add modules/adguard-home.nix
git commit -m "Added new filter list for streaming services"
git push
Benefits:

Version history of all changes
Easy rollback if something breaks
Reproducible configuration
Can deploy to other machines
🛠️ Troubleshooting
Streaming Apps Not Working
Symptom: Netflix, Disney+, Hulu, etc. won't play videos

Solution:

Check AdGuard Home query log (Web UI → Query Log)
Filter by the device having issues
Look for blocked (red) queries
Add blocked domains to user_rules in modules/adguard-home.nix
Rebuild: sudo nixos-rebuild switch
Client Names Not Showing
Symptom: AdGuard Home shows IP addresses instead of device names

Solution:

Verify local_ptr_upstreams points to your router (192.168.1.1)
Ensure router has DHCP enabled and assigns hostnames
Check that resolve_clients = true in config
Rebuild: sudo nixos-rebuild switch
DNS Not Resolving
Symptom: Clients can't resolve domain names

Solution:

Check AdGuard Home is running: sudo systemctl status adguardhome
Check firewall allows port 53: sudo iptables -L -n | grep 53
Test DNS locally: dig @127.0.0.1 google.com
Check upstream DNS servers are reachable: dig @9.9.9.9 google.com
Installation Script Fails
Symptom: install-nixos.sh exits with error

Common causes:

Wrong disk device: Edit script, change TARGET_DISK to correct device
Disk in use: Unmount any mounted partitions first
Insufficient space: Ensure target disk has 20+ GB
Network issues: Check internet connectivity
Debug:

Check available disks: lsblk
Check disk space: df -h
Check network: ping 8.8.8.8
View detailed error: journalctl -xe
ISO Build Fails
Symptom: build-iso.sh exits with error

Common causes:

Insufficient disk space: Need 15-20 GB free
Low memory: Need 4+ GB RAM
Network issues: Can't download packages
Syntax error in config: Check nix files for errors
Debug:

Check disk space: df -h /nix
Check syntax: nix-instantiate --parse configuration.nix
Build with verbose output: nix-shell -p nixos-generators --run "nixos-generate -f iso -c ./iso-config.nix --show-trace"
📊 AdGuard Home Configuration Highlights
Filter Lists (Declarative)
Current configuration includes 6 filter lists (expand to 12-18 as needed):

AdGuard DNS filter - Core ad blocking, regularly updated
Peter Lowe's List - Conservative, minimal false positives
OISD Small - Balanced blocking, good for general use
The Big List of Hacked Malware Web Sites - Security protection
Malicious URL Blocklist - Additional malware protection
HaGeZi's Pro Blocklist - Aggressive ad/tracker blocking
Why declarative filter lists matter:

No manual clicking - Add filters by editing config file
Version controlled - Track changes in Git
Reproducible - Same filters on every deployment
Easy to share - Others can use your exact setup
Disaster recovery - Rebuild with all filters intact
Custom Rules (Declarative)
Pre-configured streaming service allowlists:

Netflix (nflxvideo.net, nflximg.net, etc.)
Disney+ (bamgrid.com, disney-plus.net, etc.)
Hulu (hulustream.com, hulu.hb.omtrdc.net, etc.)
HBO Max / Max (hbomax.com, max.com, etc.)
Amazon Prime Video (primevideo.com, atv-ps.amazon.com, etc.)
Why custom rules matter:

Prevent streaming breakage - Pre-configured fixes
Document discoveries - Comment why each rule exists
Share knowledge - Others benefit from your troubleshooting
Quick deployment - No trial and error on new installs
DNS Configuration
Upstream DNS Servers:

Primary: Cloudflare DNS over HTTPS (DoH)
Secondary: Quad9 DNS over HTTPS (DoH)
Fallback: Quad9 standard DNS
Benefits:

Privacy - DoH encrypts DNS queries
Security - Quad9 blocks malicious domains
Reliability - Multiple upstream servers
Performance - Fast, global CDN-backed DNS
Client Identification:

Uses router PTR lookups to resolve client names
Shows "John's iPhone" instead of "192.168.1.50"
Requires router cooperation (most modern routers support this)
🎓 Learning Resources
NixOS Documentation
NixOS Manual: https://nixos.org/manual/nixos/stable/
Nix Package Search: https://search.nixos.org/
NixOS Wiki: https://nixos.wiki/
AdGuard Home
Official Documentation: https://github.com/AdguardTeam/AdGuardHome/wiki
Filter List Registry: https://github.com/AdguardTeam/HostlistsRegistry
Filtering Syntax: https://github.com/AdguardTeam/AdGuardHome/wiki/Hosts-Blocklists
Community
NixOS Discourse: https://discourse.nixos.org/
r/NixOS: https://www.reddit.com/r/NixOS/
AdGuard Home Subreddit: https://www.reddit.com/r/Adguard/
📝 License
This configuration is provided as-is for personal and educational use.

🙏 Acknowledgments
NixOS community for the amazing declarative OS
AdGuard Team for AdGuard Home
Filter list maintainers for their ongoing work
Everyone who contributes to open-source ad blocking
📧 Support
For issues or questions:

Open an issue on GitHub
Check NixOS Discourse for similar problems
Review AdGuard Home documentation
Happy ad-free browsing! 🚀
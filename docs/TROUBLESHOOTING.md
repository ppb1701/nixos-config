# Troubleshooting Guide

This guide covers common issues you might encounter when setting up or running your NixOS AdGuard Home server.

## AdGuard Home Issues

### Web UI Not Accessible

**Symptoms:**
- Cannot access http://192.168.1.154:3000
- Connection refused or timeout

**Solutions:**

1. Check if AdGuard Home is running:
   ```bash
   systemctl status adguardhome
   ```

2. Check if the service is listening on the correct port:
   ```bash
   ss -tlnp | grep 3000
   ```

3. Verify firewall rules:
   ```bash
   sudo iptables -L -n | grep 3000
   ```

4. Check AdGuard Home logs:
   ```bash
   journalctl -u adguardhome -f
   ```

5. Verify configuration:
   ```bash
   cat /var/lib/AdGuardHome/AdGuardHome.yaml
   ```

### DNS Not Working

**Symptoms:**
- Clients can't resolve domain names
- DNS queries timing out

**Solutions:**

1. Check if AdGuard Home is listening on port 53:
   ```bash
   ss -ulnp | grep :53
   ```

2. Verify DNS is working locally:
   ```bash
   dig @127.0.0.1 google.com
   ```

3. Check firewall allows DNS:
   ```bash
   sudo iptables -L -n | grep 53
   ```

4. Verify clients are using correct DNS server:
   ```bash
   # On Linux client
   cat /etc/resolv.conf
   
   # On Windows client
   ipconfig /all
   ```

5. Check AdGuard Home query log in web UI

### Filter Lists Not Updating

**Symptoms:**
- Filter lists show old update times
- Ads not being blocked

**Solutions:**

1. Manually trigger update in web UI:
   - Go to Settings → DNS settings → DNS blocklists
   - Click "Update now"

2. Check internet connectivity:
   ```bash
   ping 1.1.1.1
   curl -I https://adguardteam.github.io
   ```

3. Check AdGuard Home logs for errors:
   ```bash
   journalctl -u adguardhome | grep -i error
   ```

4. Verify filter list URLs are accessible:
   ```bash
   curl -I https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
   ```

### Client Names Not Showing

**Symptoms:**
- Query log shows IP addresses instead of hostnames
- "Unknown device" in statistics

**Solutions:**

1. Verify reverse DNS is enabled in configuration:
   ```nix
   # In modules/adguard-home.nix
   dns = {
     resolve_clients = true;
     use_private_ptr_resolvers = true;
     local_ptr_upstreams = [ "192.168.1.1" ];
   };
   ```

2. Check if router supports reverse DNS:
   ```bash
   dig -x 192.168.1.100 @192.168.1.1
   ```

3. Add static DHCP reservations on router with hostnames

4. Manually add clients in AdGuard Home:
   - Go to Settings → Client settings
   - Click "Add client"

## Syncthing Issues

### Devices Not Connecting

**Symptoms:**
- Devices show as "Disconnected"
- No syncing happening

**Solutions:**

1. Verify device IDs are correct:
   - Check web UI on each device
   - Go to Actions → Show ID
   - Compare with configuration

2. Check firewall rules:
   ```bash
   sudo iptables -L -n | grep 22000
   ```

3. Verify Syncthing is running:
   ```bash
   systemctl status syncthing@youruser
   ```

4. Check Syncthing logs:
   ```bash
   journalctl -u syncthing@youruser -f
   ```

5. Test connectivity between devices:
   ```bash
   # From device A
   telnet device-b-ip 22000
   ```

### Files Not Syncing

**Symptoms:**
- Devices connected but files not updating
- "Out of Sync" status

**Solutions:**

1. Check folder status in web UI:
   - Look for errors or conflicts
   - Check "Out of Sync Items"

2. Verify folder paths exist:
   ```bash
   ls -la /home/youruser/Documents
   ```

3. Check file permissions:
   ```bash
   ls -la /home/youruser/Documents/
   # Files should be owned by your user
   ```

4. Look for .stignore conflicts:
   ```bash
   cat /home/youruser/Documents/.stignore
   ```

5. Check for sync conflicts:
   ```bash
   find /home/youruser/Documents -name "*.sync-conflict-*"
   ```

6. Restart Syncthing:
   ```bash
   systemctl restart syncthing@youruser
   ```

### High CPU/Memory Usage

**Symptoms:**
- Syncthing using excessive resources
- System slowdown during sync

**Solutions:**

1. Check what's being synced:
   - Open web UI
   - Look at "Recent Changes"

2. Reduce scan interval:
   ```nix
   # In private/syncthing-devices.nix
   folders = {
     "Documents" = {
       path = "/home/youruser/Documents";
       devices = [ "laptop" ];
       rescanIntervalS = 3600;  # Scan every hour instead of default
     };
   };
   ```

3. Add ignore patterns for large files:
   ```nix
   ignores = [
     "*.iso"
     "*.vmdk"
     "node_modules"
     ".git/objects"
   ];
   ```

4. Enable file versioning to reduce conflicts:
   ```nix
   versioning = {
     type = "simple";
     params.keep = "5";
   };
   ```

## Network Issues

### Static IP Not Working

**Symptoms:**
- Server not accessible at configured IP
- Network unreachable

**Solutions:**

1. Verify interface name:
   ```bash
   ip link show
   ```

2. Check current IP configuration:
   ```bash
   ip addr show
   ```

3. Verify configuration matches your network:
   ```nix
   # In modules/networking.nix
   interfaces.eno1 = {  # Must match your interface name
     ipv4.addresses = [{
       address = "192.168.1.154";  # Must be in your subnet
       prefixLength = 24;
     }];
   };
   defaultGateway = "192.168.1.1";  # Must be your router IP
   ```

4. Test gateway connectivity:
   ```bash
   ping 192.168.1.1
   ```

5. Rebuild and reboot:
   ```bash
   sudo nixos-rebuild switch
   sudo reboot
   ```

### SSH Not Working

**Symptoms:**
- Cannot SSH into server
- Connection refused

**Solutions:**

1. Verify SSH is enabled:
   ```bash
   systemctl status sshd
   ```

2. Check SSH is listening:
   ```bash
   ss -tlnp | grep :22
   ```

3. Verify firewall allows SSH:
   ```bash
   sudo iptables -L -n | grep 22
   ```

4. Check SSH configuration:
   ```bash
   cat /etc/ssh/sshd_config
   ```

5. Try from localhost first:
   ```bash
   ssh localhost
   ```

## ISO Build Issues

### Build Fails with "Out of Space"

**Symptoms:**
- Build stops with disk space error
- /nix/store full

**Solutions:**

1. Check available space:
   ```bash
   df -h /nix/store
   ```

2. Clean up old generations:
   ```bash
   nix-collect-garbage -d
   ```

3. Remove old build artifacts:
   ```bash
   rm -rf result result-*
   ```

4. Ensure at least 20GB free space

### ISO Build Succeeds but No result Symlink

**Symptoms:**
- Build completes successfully
- No result symlink created
- Can't find ISO file

**Solutions:**

1. Search for ISO in /nix/store:
   ```bash
   find /nix/store -name "*.iso" -mtime -1
   ```

2. Check build output for path:
   ```bash
   ./build-iso.sh 2>&1 | grep -i "iso"
   ```

3. Manually create symlink:
   ```bash
   ln -s /nix/store/xxxxx-nixos.iso ./nixos-config.iso
   ```

### ISO Won't Boot

**Symptoms:**
- USB boots but shows errors
- Installation environment doesn't start

**Solutions:**

1. Verify ISO integrity:
   ```bash
   sha256sum nixos-config.iso
   ```

2. Re-flash USB drive:
   ```bash
   sudo dd if=nixos-config.iso of=/dev/sdX bs=4M status=progress
   sync
   ```

3. Try different USB port or drive

4. Check BIOS/UEFI settings:
   - Disable Secure Boot
   - Enable legacy boot if needed

## Installation Issues

### Install Script Fails

**Symptoms:**
- install-nixos.sh exits with error
- Installation incomplete

**Solutions:**

1. Check disk device:
   ```bash
   lsblk
   # Verify /dev/sda is correct device
   ```

2. Manually partition if needed:
   ```bash
   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart primary 512MB 100%
   parted /dev/sda -- mkpart ESP fat32 1MB 512MB
   parted /dev/sda -- set 2 esp on
   ```

3. Check available space:
   ```bash
   df -h
   ```

4. Review install script output for specific error

### System Won't Boot After Install

**Symptoms:**
- Installation completes
- System won't boot from disk

**Solutions:**

1. Verify bootloader installed:
   ```bash
   # Boot from USB again
   mount /dev/sda1 /mnt
   ls /mnt/boot
   ```

2. Check BIOS boot order

3. Reinstall bootloader:
   ```bash
   nixos-install --root /mnt
   ```

4. Verify hardware-configuration.nix is correct

## Performance Issues

### High Memory Usage

**Symptoms:**
- System using excessive RAM
- OOM (Out of Memory) errors

**Solutions:**

1. Check memory usage:
   ```bash
   free -h
   htop
   ```

2. Identify memory hogs:
   ```bash
   ps aux --sort=-%mem | head
   ```

3. Increase swap file size:
   ```bash
   # Edit install-nixos.sh before installation
   # Change: dd if=/dev/zero of=/mnt/swapfile bs=1M count=8192
   ```

4. Reduce services if needed

### Low Disk Space

**Symptoms:**
- Disk space warnings
- `nix-store` operations fail with "no space left on device"
- System updates fail due to insufficient space
- `/nix/store` consuming many gigabytes

**Solutions:**

1. **Run the cleanup script (recommended):**
   ```bash
   sudo /etc/nixos/cleanup-nixos.sh
   ```
   
   This automated script will:
   - Show disk usage before and after
   - Remove generations older than 7 days
   - Run full garbage collection
   - Optimize store with hard-linking
   - Clean temporary files

2. **Check what's using space:**
   ```bash
   # Check overall disk usage
   df -h /
   
   # Check Nix store size
   du -sh /nix/store
   
   # Find largest store paths
   du -sh /nix/store/* | sort -hr | head -20
   ```

3. **Manually remove old generations:**
   ```bash
   # List all generations
   sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
   
   # Delete specific generations
   sudo nix-env --delete-generations 10 11 12 --profile /nix/var/nix/profiles/system
   
   # Delete all but current and previous
   sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
   
   # Delete generations older than 30 days
   sudo nix-collect-garbage --delete-older-than 30d
   ```

4. **Run garbage collection:**
   ```bash
   # Full garbage collection
   sudo nix-collect-garbage -d
   
   # This removes ALL unreachable store paths
   # Make sure you don't need to rollback first!
   ```

5. **Optimize Nix store:**
   ```bash
   sudo nix-store --optimise
   ```
   
   This hard-links identical files together, typically saving 10-30% of store size.

6. **Clean old result symlinks:**
   ```bash
   find /etc/nixos -name "result*" -type l -delete
   find ~ -name "result*" -type l -delete
   ```

**Expected Results:**
- Removing old generations: 5-20GB freed
- Garbage collection: 2-10GB freed (depends on orphaned packages)
- Store optimization: 10-30% reduction through deduplication
- Combined: Can recover 20-50GB on a system with many old generations

**Prevention:**
- Run `cleanup-nixos.sh` monthly
- Don't keep more than 5-10 generations
- Clean up after experimenting with new packages
- Remove unused packages from configuration

### Slow DNS Responses

**Symptoms:**
- Websites load slowly
- DNS queries take seconds

**Solutions:**

1. Test DNS response time:
   ```bash
   time dig @127.0.0.1 google.com
   ```

2. Try different upstream DNS:
   ```nix
   # In modules/adguard-home.nix
   dns.upstream_dns = [
     "1.1.1.1"  # Cloudflare
     "8.8.8.8"  # Google
   ];
   ```

3. Reduce filter lists if too many

4. Check network latency:
   ```bash
   ping 1.1.1.1
   ```

## Syncthing Issues

### Devices Not Discovering Each Other

**Symptoms:**
- Devices show as "Disconnected"
- Can't see other devices on network
- Sync not starting

**Solutions:**

1. **Most Common Fix:** Manually add device address in `private/syncthing-devices.nix`:

   ```nix
   devices = {
     "my-device" = {
       id = "ABCDEFG-HIJKLMN-...";
       addresses = [ "tcp://192.168.1.100:22000" ];  # Add this line
     };
   };
   ```

   Then rebuild: `sudo nixos-rebuild switch`

2. **Check devices are announced:**
   - On each device, open Syncthing web UI
   - Go to Actions → Show ID
   - Verify device IDs match in configuration

3. **Enable discovery options** in Syncthing web UI:
   - Settings → Connections
   - Enable "Local Discovery"
   - Enable "Global Discovery"
   - Enable "Enable Relaying"

4. **Check firewall allows Syncthing ports:**

   ```bash
   ss -tlnp | grep 22000  # Sync port
   ss -ulnp | grep 21027  # Discovery port
   ss -tlnp | grep 8384   # Web UI port
   ```

5. **Verify service is running:**

   ```bash
   systemctl status syncthing
   journalctl -u syncthing -f
   ```

6. **Check for VPN interference:**
   - VPNs can block local network discovery
   - Temporarily disable VPN to test
   - Security software may also interfere

### Syncthing GUI Not Accessible

**Symptoms:**
- Can't access http://192.168.1.154:8384
- Connection refused

**Solutions:**

1. Verify Syncthing is running:
   ```bash
   systemctl status syncthing
   ```

2. Check if port 8384 is listening:
   ```bash
   ss -tlnp | grep 8384
   ```

3. Verify GUI password is set in `private/syncthing-secrets.nix`

4. Check Syncthing logs:
   ```bash
   journalctl -u syncthing -n 50
   ```

### Files Not Syncing

**Symptoms:**
- Folders stuck "Syncing" or show errors
- Files not appearing on other devices

**Solutions:**

1. Check folder status in web UI
2. Verify folder paths exist and have correct permissions:

   ```bash
   ls -la /home/ppb1701/Documents
   sudo chown -R ppb1701:users /home/ppb1701/Documents
   ```

3. Check disk space:
   ```bash
   df -h
   ```

4. Look for conflicts (files ending in `.sync-conflict-*`)

5. Review `.stignore` patterns if using

6. Check logs for specific errors:
   ```bash
   journalctl -u syncthing | grep -i error
   ```

## Home Manager Issues

### home-manager/nixos Not Found

**Symptoms:**
```
error: file 'home-manager/nixos' was not found in the Nix search path
```

**Solutions:**

1. Add Home Manager channel:

   ```bash
   sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
   sudo nix-channel --update
   ```

2. Logout and login again (or reboot) to update `NIX_PATH`

3. If still not working, comment out Home Manager in `configuration.nix` temporarily:

   ```nix
   imports = [
     ./modules/adguard-home.nix
     # <home-manager/nixos>  # Comment out temporarily
   ];
   
   # home-manager.users.ppb1701 = import ./home/ppb1701.nix;  # Comment out
   ```

4. Rebuild: `sudo nixos-rebuild switch`

5. Add Home Manager back later after channel is properly set up

### Channel Version Mismatch

**Symptoms:**
- Errors about incompatible versions
- Home Manager complains about NixOS version

**Solutions:**

1. Check NixOS version:
   ```bash
   nixos-version
   ```

2. Use matching Home Manager channel:
   ```bash
   # For NixOS 24.05
   sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
   
   # For NixOS unstable
   sudo nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
   
   sudo nix-channel --update
   ```

## Build Issues

### RustDesk Build Error

**Symptoms:**
```
thread 'main' panicked at cargo-auditable/src/cargo_auditable.rs:40:39:
called `Option::unwrap()` on a `None` value
error: builder for '/nix/store/...-rustdesk-1.3.8.drv' failed with exit code 101
```

**Explanation:**

RustDesk has a known build error in NixOS 25.05 related to the `cargo-auditable` tool. This is an upstream issue being tracked in the NixOS package repository.

**Solutions:**

1. **Remove RustDesk from configuration** (recommended):

   Comment out rustdesk module in `configuration.nix`:
   ```nix
   imports = [
     ./modules/adguard-home.nix
     ./modules/networking.nix
     # ./modules/rustdesk.nix  # Disabled due to build error
   ];
   ```

   Remove rustdesk from packages if installed directly

2. **Use alternative remote access:**
   - SSH (already configured): `ssh ppb1701@192.168.1.154`
   - Tailscale VPN (see SERVICES.md)
   - Traditional VNC server

3. **Wait for upstream fix:**
   - Monitor NixOS issue tracker
   - Update channels when fixed: `sudo nix-channel --update`

### ISO Build Fails

**Symptoms:**
- `./build-iso.sh` fails
- Insufficient disk space errors
- Nix store errors

**Solutions:**

1. Check available disk space (need 20GB+):
   ```bash
   df -h
   ```

2. Clean up old generations:
   ```bash
   sudo nix-collect-garbage -d
   sudo nix-store --optimise
   ```

3. Verify Nix store integrity:
   ```bash
   nix-store --verify --check-contents
   ```

4. Try clean build:
   ```bash
   rm -rf result
   ./build-iso.sh
   ```

## Network Configuration Issues

### Static IP Not Working in VM

**Symptoms:**
- VM can't reach network after setting static IP
- Network unreachable errors

**Explanation:**

VMs often use NAT networking (10.0.2.x) or different subnets than your physical network (192.168.1.x).

**Solutions:**

1. **For VM testing:** Comment out static IP configuration in `modules/networking.nix`:

   ```nix
   # Static IP configuration (DISABLED FOR VM TESTING)
   # networking.interfaces.enp0s3 = {
   #   ipv4.addresses = [{
   #     address = "192.168.1.154";
   #     prefixLength = 24;
   #   }];
   # };
   # 
   # networking.defaultGateway = "192.168.1.1";
   ```

2. **Let VM use DHCP:** The VM will get an IP automatically from VirtualBox/VMware NAT

3. **For production:** Uncomment static IP section and set correct interface name

4. **Find VM's interface name:**
   ```bash
   ip addr show
   # Look for interface with IP (usually enp0s3, ens18, etc.)
   ```

### Wrong Interface Name

**Symptoms:**
- Network configuration fails
- Interface not found errors

**Solutions:**

1. Find correct interface name:
   ```bash
   ip link show
   # or
   ip addr show
   ```

2. Update `modules/networking.nix` with correct name:
   ```nix
   interfaces.YOUR_INTERFACE_NAME = {  # Change this
     ipv4.addresses = [{
       address = "192.168.1.154";
       prefixLength = 24;
     }];
   };
   ```

   Common interface names:
   - `enp0s3`, `enp1s0` (predictable names)
   - `ens18`, `ens33` (common in VMs)
   - `eth0`, `eth1` (legacy names)
   - `eno1`, `eno2` (onboard ethernet)

## Getting More Help

If you're still having issues:

- **NixOS manual:** https://nixos.org/manual/nixos/stable/
- **AdGuard Home docs:** https://github.com/AdguardTeam/AdGuardHome/wiki
- **Syncthing docs:** https://docs.syncthing.net/
- **Ask on Mastodon:** @ppb1701@ppb.social

### When Asking for Help

Please include:

- **NixOS version:** Run `nixos-version`
- **Error messages** from logs
- **Relevant configuration** snippets
- **Steps to reproduce** the issue
- **Keep in mind I'm no expert ;) but I'll try to help**

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

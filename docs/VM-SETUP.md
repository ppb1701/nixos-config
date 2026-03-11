# VM Setup: iso-builder

The iso-builder VM runs the `vm` branch of
[nixos-config](https://github.com/ppb1701/nixos-config) and produces custom
NixOS ISOs stored on the 6TB SSD, available via the `isos` Samba share.

---

## Prerequisites

nixos2 rebuilt with `modules/vm.nix` imported. Verify with:

```bash
systemctl status libvirtd
systemctl status virtiofsd-iso-builder
```

Both should be active.

---

## Step 1 — Create the VM disk

```bash
sudo qemu-img create -f qcow2 /mnt/nextcloud-data/vms/iso-builder.qcow2 40G
```

40G is comfortable for the Nix store across a few builds. The store grows as
packages are cached; run `sudo nix-collect-garbage -d` inside the VM
periodically if space gets tight.

---

## Step 2 — Install the VM

```bash
sudo virt-install \
  --name iso-builder \
  --memory 4096 \
  --vcpus 4 \
  --disk path=/mnt/nextcloud-data/vms/iso-builder.qcow2,format=qcow2 \
  --cdrom /path/to/nixos-config.iso \
  --os-variant nixos-unstable \
  --network network=default \
  --graphics spice \
  --video vga \
  --boot uefi \
  --memorybacking source.type=memfd,access.mode=shared \
  --filesystem source.dir=/mnt/nextcloud-data/isos,target.dir=host-isos,driver.type=virtiofs \
  --noautoconsole
```

Then connect via virt-manager (on the nixos2 LXQT desktop) to complete the
NixOS install interactively. Boot from the ISO, run `install-nixos.sh`, reboot.

**Note on `--memorybacking`:** virtiofs requires shared memory. This line is
mandatory or the virtiofs mount will fail on boot.

**Note on `--cdrom` path:** use the last ISO you built, or download the
official NixOS minimal ISO and boot to a shell, then clone and install
manually.

---

## Step 3 — Add virtiofs to the XML (if not picked up automatically)

After installation, verify the VM XML has the virtiofs filesystem entry:

```bash
sudo virsh edit iso-builder
```

Look for this block. If it's missing, add it inside `<devices>`:

```xml
<filesystem type="mount" accessmode="passthrough">
  <driver type="virtiofs"/>
  <source dir="/mnt/nextcloud-data/isos"/>
  <target dir="host-isos"/>
</filesystem>
```

And ensure `<memoryBacking>` is present at the top level:

```xml
<memoryBacking>
  <source type="memfd"/>
  <access mode="shared"/>
</memoryBacking>
```

---

## Step 4 — Inside the VM: set channel + mount virtiofs

SSH into the VM:
```bash
vmssh
```

Set the channel to unstable (must match nixos2 to avoid drift):
```bash
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
sudo nix-channel --update
```

Add the virtiofs mount to the vm branch `modules/system.nix` — see the
section below. Then rebuild:
```bash
sudo nixos-rebuild switch
```

Verify the mount:
```bash
ls /mnt/host-isos
```

---

## Step 5 — Samba password on nixos2 host

The `isos` share requires a Samba password for `ppb1701`:

```bash
sudo smbpasswd -a ppb1701
```

Then from Windows: `\\nixos2\isos` or `\\192.168.50.218\isos`
DNS rewrite in AdGuard: `isos.home → 192.168.50.218` (optional clean URL)

---

## Step 6 — Enable autostart

```bash
sudo virsh autostart iso-builder
```

The VM will start automatically when nixos2 boots (controlled by
`virtualisation.libvirtd.onBoot = "start"` in vm.nix).

---

## System.nix addition for the VM guest (vm branch)

Add this to `modules/system.nix` in the `vm` branch of nixos-config:

```nix
# ═══════════════════════════════════════════════════════════════════════════
# VIRTIOFS MOUNT - ISO OUTPUT SHARED WITH HOST
# ═══════════════════════════════════════════════════════════════════════════
# Mounts the host's /mnt/nextcloud-data/isos/ as /mnt/host-isos here.
# build-iso.sh copies finished ISOs here; they appear on nixos2's
# Samba share (\\nixos2\isos) without any manual transfer.
fileSystems."/mnt/host-isos" = {
  device  = "host-isos";   # must match --filesystem target.dir= in virt-install
  fsType  = "virtiofs";
  options = [ "defaults" ];
};

systemd.tmpfiles.rules = [
  "d /mnt/host-isos 0775 ppb1701 users - -"
];
```

Also add `virtiofs` to `boot.initrd.availableKernelModules` if it isn't
already there:

```nix
boot.initrd.availableKernelModules = [ ... "virtiofs" ];
```

Or more precisely, add to `boot.kernelModules`:
```nix
boot.kernelModules = [ "virtiofs" ];
```

---

## build-iso.sh addition (vm branch)

At the end of `build-iso.sh`, after the existing ISO path check, add:

```bash
# Copy to host-shared isos directory if mounted
if mountpoint -q /mnt/host-isos; then
  DEST="/mnt/host-isos/nixos-config-$(date +%Y%m%d-%H%M).iso"
  echo "Copying ISO to host share..."
  cp "$ISO_PATH" "$DEST"
  echo "Available at: \\\\nixos2\\isos\\$(basename $DEST)"
else
  echo "Note: /mnt/host-isos not mounted — copy manually if needed"
fi
```

---

## Day-to-day usage

```bash
vmstart    # start the VM
vmssh      # SSH in (auto-resolves IP)
# inside VM:
cd /etc/nixos && sudo git pull && bash build-iso.sh
# ISO appears at \\nixos2\isos automatically
vmstop     # graceful shutdown when done
```

---

## VM management reference

| Command | What it does |
|---------|-------------|
| `vmls` | List all VMs and state |
| `vmstart` | Start iso-builder |
| `vmstop` | Graceful shutdown |
| `vmkill` | Hard stop (if shutdown hangs) |
| `vminfo` | Domain info, allocated resources |
| `vmssh` | SSH in (resolves DHCP address automatically) |

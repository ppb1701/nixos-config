{ config, pkgs, lib, ... }:

{
  # ═══════════════════════════════════════════════════════════════════════════════
  # LIBVIRT / QEMU - VM HOST FOR ISO BUILDS
  # Currently disabled — nixos2 is not running VMs.
  # To enable: set enable = true, rebuild, then follow docs/VM-SETUP.md
  # ═══════════════════════════════════════════════════════════════════════════════

  virtualisation.libvirtd = {
    enable = false;
    qemu = {
      package      = pkgs.qemu_kvm;
      runAsRoot    = false;
      swtpm.enable = true;     
      verbatimConfig = ''
        namespaces = []
      '';
    };
    onBoot     = "start";
    onShutdown = "shutdown";
  };

  # programs.virt-manager.enable = true;
  # users.users.ppb1701.extraGroups = lib.mkAfter [ "libvirtd" "kvm" ];

  # ── virtiofsd, tmpfiles, pool-setup, libvirt-network-setup ──────────────
  # All commented out while libvirtd is disabled.
  # Uncomment when enabling VM support.

  # systemd.services.virtiofsd-iso-builder = { ... };
  # systemd.services.libvirt-pool-setup = { ... };
  # systemd.services.libvirt-network-setup = { ... };

  # systemd.tmpfiles.rules = [
  #   "d /mnt/nextcloud-data/vms  0755 ppb1701 libvirtd - -"
  #   "d /mnt/nextcloud-data/isos 0775 ppb1701 libvirtd - -"
  #   "d /run/libvirt/qemu        0755 root root - -"
  # ];
}

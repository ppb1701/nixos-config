{ config, pkgs, ... }:

{
  # ═══════════════════════════════════════════════════════════════════════════
  # SAMBA - TIME MACHINE BACKUP FOR MACOS
  # ═══════════════════════════════════════════════════════════════════════════
  # Provides a Time Machine target at /mnt/nextcloud-data/timemachine.
  # Primary instance runs on nixos2. Disabled here — enable for failover.
  #
  # To enable:
  #   1. Set enable = true on samba and samba-wsdd below
  #   2. Add Samba firewall ports to modules/networking.nix:
  #        allowedTCPPorts: 139, 445
  #        allowedUDPPorts: 137, 138, 5353
  #   3. Set Samba password for tmuser:  sudo smbpasswd -a tmuser
  #   4. Rebuild: sudo nixos-rebuild switch
  # ═══════════════════════════════════════════════════════════════════════════

  services.samba = {
    enable = false;
    securityType = "user";
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "nixos";
        "server role" = "standalone server";

        # Apple extensions for Time Machine compatibility
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
      timemachine = {
        "path" = "/mnt/nextcloud-data/timemachine";
        "browseable" = "yes";
        "writable" = "yes";
        "valid users" = "tmuser";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "1500G";
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # TIME MACHINE USER
  # ═══════════════════════════════════════════════════════════════════════════
  # Dedicated system user for Samba auth. Added to syncthing group to match
  # the existing group ownership pattern on this server.

  users.users.tmuser = {
    isSystemUser = true;
    group = "tmuser";
    extraGroups = [ "syncthing" ];
    description = "Time Machine Samba user";
  };

  users.groups.tmuser = {};

  # ═══════════════════════════════════════════════════════════════════════════
  # DIRECTORY
  # ═══════════════════════════════════════════════════════════════════════════
  # 2775 = setgid + rwxrwsr-x
  # New files inherit syncthing group, consistent with other shared dirs.

  systemd.tmpfiles.rules = [
    "d /mnt/nextcloud-data/timemachine 2775 tmuser syncthing - -"
  ];
}

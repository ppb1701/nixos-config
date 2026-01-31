{ config, pkgs, lib, ... }:

let
  secrets = import ../private/secrets.nix;
in
{
  # Restic backup jobs
  services.restic.backups = {

    # Vaultwarden backup (hourly)
    vaultwarden = {
      repository = "/var/local/backups/restic";
      passwordFile = "/etc/nixos/private/restic-password";

      paths = [
        "/var/local/vaultwarden"
      ];

      # Stop Vaultwarden before backup (SQLite safety)
      backupPrepareCommand = ''
        ${pkgs.systemd}/bin/systemctl stop vaultwarden.service
      '';

      # Restart after backup
      backupCleanupCommand = ''
        ${pkgs.systemd}/bin/systemctl start vaultwarden.service
      '';

      # Hourly backups
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };

      # Retention policy
      pruneOpts = [
        "--keep-last 24"      # Last 24 hours
        "--keep-daily 7"      # Last 7 days
        "--keep-weekly 4"     # Last 4 weeks
        "--keep-monthly 12"   # Last 12 months
      ];
    };

    # Nextcloud database backup (daily)
    nextcloud-db = {
      repository = "/var/local/backups/restic";
      passwordFile = "/etc/nixos/private/restic-password";

      paths = [
        "/var/backup/nextcloud-db"
      ];

      # Create database dump before backup
      backupPrepareCommand = ''
        mkdir -p /var/backup/nextcloud-db
        ${pkgs.sudo}/bin/sudo -u nextcloud ${pkgs.postgresql}/bin/pg_dump nextcloud > /var/backup/nextcloud-db/nextcloud.sql
      '';

      # Daily at 2 AM
      timerConfig = {
        OnCalendar = "02:15";
        Persistent = true;
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
    };

     # Linkwarden database and data backup (daily)
     linkwarden = {
       repository = "/var/local/backups/restic";
       passwordFile = "/etc/nixos/private/restic-password";
 
       paths = [
         "/var/backup/linkwarden-db"
         "/var/lib/linkwarden/data"  # Archived pages, screenshots, uploads
       ];
 
       # Create database dump before backup
       backupPrepareCommand = ''
         mkdir -p /var/backup/linkwarden-db
         ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump linkwarden > /var/backup/linkwarden-db/linkwarden.sql
       '';
 
       # Daily at 2:30 AM (offset from Nextcloud)
       timerConfig = {
         OnCalendar = "02:40";
         Persistent = true;
       };
 
       pruneOpts = [
         "--keep-daily 7"
         "--keep-weekly 4"
         "--keep-monthly 12"
       ];
     };

      #gitea = {
      #initialize = true;
      #repository = "/var/local/backups/restic";

      # What to back up
      #paths = [
      #  "/var/lib/gitea/data"           # Repos and database
      #  "/var/lib/gitea/custom/conf"    # Configuration
      #];

      # What to exclude
      #exclude = [
      #  "/var/lib/gitea/data/sessions"
      #  "/var/lib/gitea/data/tmp"
      #];

      #passwordFile = "/etc/nixos/private/restic-password";

      # Run daily at 2 AM
      #timerConfig = {
      #  OnCalendar = "02:00";
      #  Persistent = true;
      #};

      # Keep 7 daily, 4 weekly, 6 monthly snapshots
      #pruneOpts = [
      #  "--keep-daily 7"
      #  "--keep-weekly 4"
      #  "--keep-monthly 6"
      #];

      # ═══════════════════════════════════════════════════════════════════
      # STOP GITEA BEFORE BACKUP (ensures data consistency)
      # ═══════════════════════════════════════════════════════════════════
      #backupPrepareCommand = ''
      #  ${pkgs.systemd}/bin/systemctl stop gitea
      #'';

      # ═══════════════════════════════════════════════════════════════════
      # RESTART GITEA AFTER BACKUP
      # ═══════════════════════════════════════════════════════════════════
      #backupCleanupCommand = ''
      #  ${pkgs.systemd}/bin/systemctl start gitea
      #'';
    #};

    # Private configs backup (daily)
    private-configs = {
      repository = "/var/local/backups/restic";
      passwordFile = "/etc/nixos/private/restic-password";

      paths = [
        "/etc/nixos/private"
      ];

      # Daily at 3 AM
      timerConfig = {
        OnCalendar = "03:15";
        Persistent = true;
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
    };
  };

  systemd.services = {
      restic-backups-vaultwarden.postStart = ''
        chmod -R a+rX /var/local/backups/restic/
      '';
  
      restic-backups-nextcloud-db.postStart = ''
        chmod -R a+rX /var/local/backups/restic/
      '';
  
      restic-backups-private-configs.postStart = ''
        chmod -R a+rX /var/local/backups/restic/
      '';
      restic-backups-linkwarden.postStart = ''
        chmod -R a+rX /var/local/backups/restic/
      '';
      #restic-backups-gitea.postStart = ''
      #  chmod -R a+rX /var/local/backups/restic/
      #'';
    };

  # Create backup directories
  systemd.tmpfiles.rules = [
    "d /var/local/backups 0755 root root -"
    "d /var/local/backups/restic 0700 root root -"
    "d /var/backup 0755 root root -"
    "d /var/backup/nextcloud-db 0755 nextcloud nextcloud -"
    "d /var/backup/linkwarden-db 0755 postgres postgres -"
  ];
}

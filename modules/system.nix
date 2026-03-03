{ config, pkgs, ... }:

{
   # ═══════════════════════════════════════════════════════════════════════════
  # TIMEZONE & LOCALE
  # ═══════════════════════════════════════════════════════════════════════════
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # DESKTOP ENVIRONMENT - LXQT
  # ═══════════════════════════════════════════════════════════════════════════
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.lxqt.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "ppb1701";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # AUDIO - PIPEWIRE
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # USERS
  # ═══════════════════════════════════════════════════════════════════════════
  users.users.ppb1701 = {
    isNormalUser = true;
    description = "ppb1701";
    extraGroups = [ "networkmanager" "wheel" "docker" "gitea" "syncthing" "notediscovery"];
    openssh.authorizedKeys.keys = import /etc/nixos/private/ssh-keys.nix;
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  nixpkgs.config.allowUnfree = true;
  
  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES
  # ═══════════════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    micro
    starship
    gitui
    dig
    jq
    lsof
    nix-output-monitor
    nh
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # ZSH & STARSHIP
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.starship = {
    enable = true;
  };


  # ═══════════════════════════════════════════════════════════════════════════
  # NIX SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  virtualisation.podman.enable = true;

  virtualisation.oci-containers.backend = "podman";
  # ═══════════════════════════════════════════════════════════════════════════
  # SSH SERVER - RESILIENT CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
 # SSH Configuration - PRODUCTION HARDENED
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;        # ← Disable password auth
      PermitRootLogin = "no";                # ← Disable root login entirely
      PubkeyAuthentication = true;           # ← Enable SSH key auth
      ChallengeResponseAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;                 # ← Disable X11 forwarding
      AllowUsers = [ "ppb1701" ];            # ← Only allow specific user
    };
    ports = [ 2212 ];  # Consider changing to non-standard port (e.g., 2222)
  };
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
  };
  
	# Create the mount point
  systemd.tmpfiles.rules = [
    # Obsidian/Blog - shared between ppb1701, notediscovery, and syncthing
    "d /var/lib/obsidian 0755 ppb1701 users - -"
    "d /var/lib/obsidian/ppb 0775 ppb1701 syncthing - -"
    "d /var/lib/obsidian/ppb/Blog 2775 ppb1701 syncthing - -"

    # Restic backups - make readable by syncthing
    "d /var/local/backups 0755 root root - -"
    "d /var/local/backups/restic 0755 root syncthing - -"

    # Nextcloud data - read-only for syncthing monitoring
    "d /mnt/nextcloud-data 0755 nextcloud nextcloud - -"
    "d /mnt/nextcloud-data/data 0755 nextcloud nextcloud - -"

    # Other existing rules
    "d /var/local/vaultwarden 0755 vaultwarden vaultwarden -"
    "d /var/local/vaultwarden/backup 0755 vaultwarden vaultwarden -"
    "d /var/local/backups2 0755 ppb1701 syncthing -"
    "d /var/local/clientbackups 0755 ppb1701 syncthing -"
    "d /var/cache/linkwarden 0755 linkwarden linkwarden -"
    "d /var/cache/linkwarden/cache 0755 linkwarden linkwarden -"
  ];
  
    # 1. Gitea Main Folder
      # "2775" = Set GID (2) + Group Read Write/Execute (775)
      # Ensures new files inherit the 'gitea' group and are group-writable.
   #   "d /var/lib/gitea 2775 gitea gitea - -"
    
      # 2. Syncthing Folder Marker
      # Creates the hidden folder marker automatically on boot
      # so Syncthing doesn't complain "folder marker missing" after a reboot.
    #  "d /var/lib/gitea/.stfolder 2775 gitea gitea - -"
    
      # 3. SSH Folder Fix
      # The .ssh folder is strict by default (700).
      # We enforce 2770 so the group can traverse and read keys for backup.
     # "d /var/lib/gitea/.ssh 2770 gitea gitea - -"
    
      # 4. Authorized Keys Fix
      # Ensure the key file itself is readable by the group (640).
      #"Z /var/lib/gitea/.ssh/authorized_keys 0640 gitea gitea - -"
  #];

  # Configure services to use compatible permissions
    systemd.services = {
      # NoteDiscovery must create files with syncthing group
      notediscovery.serviceConfig = {
        SupplementaryGroups = [ "syncthing" ];
        UMask = "0002";  # Creates files as 664/775
      };
  
      # Syncthing needs UMask for proper file creation
      syncthing.serviceConfig = {
        UMask = "0002";
        ReadWritePaths = [ 
          "/var/lib/obsidian"
          "/var/local/backups"
          "/var/local/backups2"
          "/var/local/clientbackups"
          "/mnt/nextcloud-data"
        ];
      };
  
      # Make restic backups readable by syncthing group
      restic-backups-vaultwarden.postStart = ''
        ${pkgs.coreutils}/bin/chmod -R g+rX /var/local/backups/restic/
        ${pkgs.coreutils}/bin/chgrp -R syncthing /var/local/backups/restic/
      '';
  
      restic-backups-nextcloud-db.postStart = ''
        ${pkgs.coreutils}/bin/chmod -R g+rX /var/local/backups/restic/
        ${pkgs.coreutils}/bin/chgrp -R syncthing /var/local/backups/restic/
      '';
  
      restic-backups-linkwarden.postStart = ''
        ${pkgs.coreutils}/bin/chmod -R g+rX /var/local/backups/restic/
        ${pkgs.coreutils}/bin/chgrp -R syncthing /var/local/backups/restic/
      '';
  
      restic-backups-private-configs.postStart = ''
        ${pkgs.coreutils}/bin/chmod -R g+rX /var/local/backups/restic/
        ${pkgs.coreutils}/bin/chgrp -R syncthing /var/local/backups/restic/
      '';
    };

  # Mount the drive
  fileSystems."/mnt/nextcloud-data" = {
    device = "/dev/disk/by-uuid/15d81dda-90c6-4993-9770-92841665e7b5";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];  # nofail prevents boot issues if drive is missing
  };

  # Make SSH auto-restart if it crashes and wait for network
  systemd.services.sshd = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

}

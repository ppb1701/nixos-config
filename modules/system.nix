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
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = import /etc/nixos/private/ssh-keys.nix;
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

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

  # ═══════════════════════════════════════════════════════════════════════════
  # SSH SERVER - BULLETPROOF CONFIGURATION
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
    "d /mnt/nextcloud-data/data 0750 nextcloud nextcloud -"
    "d /var/local/vaultwarden 0755 vaultwarden vaultwarden -"
    "d /var/local/vaultwarden/backup 0755 vaultwarden vaultwarden -"
  ];

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

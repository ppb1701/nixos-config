{ config, pkgs, ... }:

# ═══════════════════════════════════════════════════════════════════════════
# ⚠️  SECURITY WARNING - READ BEFORE USE ⚠️
# ═══════════════════════════════════════════════════════════════════════════
#
# This configuration installs with an EMPTY PASSWORD for initial convenience.
# This allows you to:
#   1. Keep passwords out of your public GitHub repository
#   2. Set your own password after installation
#   3. Modify configurations without being locked out
#
# IMMEDIATELY after installation, you MUST:
#   1. SSH into the system: ssh ppb1701@YOUR_IP (press Enter for password)
#   2. Set a strong password: passwd
#   3. Edit this file: sudo micro /etc/nixos/configuration.nix
#      - Change: security.sudo.wheelNeedsPassword = true;
#      - Change: services.openssh.settings.PermitEmptyPasswords = false;
#   4. Rebuild: sudo nixos-rebuild switch
#
# DO NOT expose this system to the internet before securing it.
# The maintainers assume NO responsibility for security breaches resulting
# from failure to secure this system after installation.
#
# ═══════════════════════════════════════════════════════════════════════════

{
  imports = [
    ./hardware-configuration.nix
    ./modules/adguard-home.nix
    ./modules/networking.nix
    ./modules/syncthing.nix
  ] ++ (if builtins.pathExists ./private/syncthing-devices.nix
        then [ ./private/syncthing-devices.nix ]
        else [])
    ++ (if builtins.pathExists ./private/secrets.nix
        then [ ./private/secrets.nix ]
        else []);

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOTLOADER - UEFI/systemd-boot
  # ═══════════════════════════════════════════════════════════════════════════
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  networking.hostName = "nixos";
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
  # DESKTOP ENVIRONMENT (Minimal - for occasional local access)
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

  # Auto-login for local console access
  services.displayManager.autoLogin = {
    enable = true;
    user = "ppb1701";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # AUDIO
  # ═══════════════════════════════════════════════════════════════════════════
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SERVICES
  # ═══════════════════════════════════════════════════════════════════════════
  services.printing.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # SSH - Primary remote access method
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      # ⚠️ TEMPORARY: Allows login with empty password for initial setup
      # Change to false after setting your password!
      PermitEmptyPasswords = true;
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # USER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════

  # ⚠️ CRITICAL: Allows users to set/change passwords with 'passwd' command
  users.mutableUsers = true;

  users.users.ppb1701 = {
    isNormalUser = true;
    description = "Patrick Boyd";
    extraGroups = [ "networkmanager" "wheel" ];
    # NO password set here - user sets it after installation
    # If you want to pre-configure a password, create private/secrets.nix
  };

  # ⚠️ TEMPORARY: Allows sudo without password for initial setup
  # Change to true after setting your password!
  security.sudo.wheelNeedsPassword = false;

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES
  # ═══════════════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    # CLI tools
    vim
    wget
    git
    htop
    btop
    neofetch
    gitui
    micro

    # Desktop packages (for occasional local access)
    vivaldi
    lxde.lxtask
    lxqt.screengrab
    lxqt.pavucontrol-qt
    lxqt.qterminal
    lxqt.pcmanfm-qt
    lxmenu-data
    menu-cache
    lxqt.lximage-qt
    lxqt.lxqt-archiver
    lxqt.lxqt-sudo
    libsForQt5.breeze-icons
    networkmanagerapplet
    feh
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize store
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM VERSION
  # ═══════════════════════════════════════════════════════════════════════════
  system.stateVersion = "25.05";
}

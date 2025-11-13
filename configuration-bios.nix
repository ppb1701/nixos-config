{ config, pkgs, lib, ... }:

# ═══════════════════════════════════════════════════════════════════════════
# ⚠️⚠️⚠️  CRITICAL SECURITY WARNING - READ THIS FIRST  ⚠️⚠️⚠️
# ═══════════════════════════════════════════════════════════════════════════
#
# This configuration uses a TEMPORARY, PUBLICLY-KNOWN PASSWORD for convenience.
#
# 🔓 DEFAULT PASSWORD: "nixos"
#
# This password is:
#   - Documented in public repositories
#   - Known to anyone who reads this config
#   - COMPLETELY INSECURE for any real-world use
#
# ⚠️  DO NOT EXPOSE THIS SYSTEM TO THE INTERNET BEFORE SECURING IT  ⚠️
#
# IMMEDIATELY AFTER INSTALLATION (before doing anything else):
#
#   1. SSH into the system:
#      ssh ppb1701@YOUR_IP
#      Password: nixos
#
#   2. Change your password RIGHT NOW:
#      passwd
#      (Choose a strong, unique password)
#
#   3. Secure the configuration:
#      sudo micro /etc/nixos/configuration.nix
#      
#      Remove this line:
#        initialPassword = "nixos";
#      
#      Change these settings:
#        security.sudo.wheelNeedsPassword = true;
#        services.openssh.settings.PasswordAuthentication = false;
#
#   4. Apply the changes:
#      sudo nixos-rebuild switch
#
# Why this approach?
#   - Keeps passwords out of your public GitHub repository
#   - Allows you to set your own secure password after installation
#   - Prevents being locked out of a freshly installed system
#
# The maintainers assume NO responsibility for security breaches resulting
# from failure to change this password immediately after installation.
#
# ═══════════════════════════════════════════════════════════════════════════

let
  # Explicitly add modules directory to Nix store
  modulesDir = builtins.path {
    path = /etc/nixos/modules;
    name = "nixos-modules";
  };

  # Explicitly add private directory to Nix store
  privateDir = builtins.path {
    path = /etc/nixos/private;
    name = "nixos-private";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    "${modulesDir}/adguard-home.nix"
    "${modulesDir}/networking.nix"
    "${modulesDir}/syncthing.nix"
    <home-manager/nixos>  # ← HOME MANAGER INTEGRATION
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # HOME MANAGER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  home-manager.users.ppb1701 = import ./home.nix;
  home-manager.backupFileExtension = "backup";

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOTLOADER - GRUB (BIOS/Legacy Mode)
  # ═══════════════════════════════════════════════════════════════════════════
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";  # Install GRUB to MBR
  };

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
  # DESKTOP ENVIRONMENT - LXQt (Minimal, for occasional local access)
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
  # AUDIO - PipeWire
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

  # ═══════════════════════════════════════════════════════════════════════════
  # ZSH CONFIGURATION (System-level)
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # NOTE: Starship is now managed by Home Manager in home.nix
  # The system-level starship.enable has been removed

  # ═══════════════════════════════════════════════════════════════════════════
  # USER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  users.users.ppb1701 = {
    isNormalUser = true;
    description = "ppb1701";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;

    # ⚠️ TEMPORARY PASSWORD - CHANGE IMMEDIATELY AFTER INSTALLATION ⚠️
    # Default password: "nixos"
    # This is INSECURE and must be changed on first login!
    initialPassword = "nixos";

    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here if you have them
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SECURITY
  # ═══════════════════════════════════════════════════════════════════════════
  # ⚠️ TEMPORARY: Allows sudo without password for initial setup
  # Change to true after setting your password!
  security.sudo.wheelNeedsPassword = false;

  # ═══════════════════════════════════════════════════════════════════════════
  # SSH
  # ═══════════════════════════════════════════════════════════════════════════
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      # ⚠️ TEMPORARY: Password authentication enabled for initial setup
      # Change to false after adding SSH keys!
      PasswordAuthentication = true;
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # PACKAGES
  # ═══════════════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    # CLI tools
    vim
    wget
    curl
    git
    htop
    btop
    neofetch
    micro
    gitui

    # Desktop packages (for occasional local access)
    vivaldi
    vivaldi-ffmpeg-codecs
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

    # Fonts for Starship/powerline themes
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  # ENABLE IF WANT TO PROPAGATE CHANGES ACROSS MULTIPLE SYSTEMS AUTOMATICALLY
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = false;  # Set to true if you want automatic reboots
  #   dates = "04:00";  # Run at 4 AM daily
  #   flake = "github:ppb1701/nixos-config";  # Use your GitHub repo
  # };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM VERSION
  # ═══════════════════════════════════════════════════════════════════════════
  system.stateVersion = "25.05";
}

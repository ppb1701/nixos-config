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
  # DESKTOP ENVIRONMENT - LXQt (Minimal
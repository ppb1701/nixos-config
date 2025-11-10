{ config, pkgs, ... }:

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

  # SSH - Configured for password authentication
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PermitEmptyPasswords = false;
    };
  };

# ═══════════════════════════════════════════════════════════════════════════
  # ZSH & STARSHIP CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      # Git branch with icon
      git_branch = {
        symbol = "🌱 ";
        format = "[$symbol$branch]($style) ";
      };

      # Git status (shows dirty files, etc.)
      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
      };

      # Show command execution time
      cmd_duration = {
        min_time = 500;
        format = "took [$duration]($style) ";
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    interactiveShellInit = ''
      eval "$(starship init zsh)"
    '';
    shellAliases = {
      ll = "ls -lah";
      update = "sudo nixos-rebuild switch";
      edit-config = "sudo micro /etc/nixos/configuration.nix";
    };
  };

  
  # ═══════════════════════════════════════════════════════════════════════════
  # USER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════

  # Allows users to change passwords with 'passwd' command
  users.mutableUsers = true;

  users.users.ppb1701 = {
    isNormalUser = true;
    description = "Patrick Boyd";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;

    # ⚠️ TEMPORARY PASSWORD - CHANGE IMMEDIATELY AFTER INSTALLATION ⚠️
    # Default password: "nixos"
    # This is INSECURE and must be changed on first login!
    initialPassword = "nixos";
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

    # Fonts for powerline themes
    # NEW (correct):
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    
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
# NIX BUILD SETTINGS - Use disk instead of RAM for builds
# ═══════════════════════════════════════════════════════════════════════════

# Force builds to use /nix/tmp instead of RAM-based /tmp
systemd.services.nix-daemon.environment = {
  TMPDIR = "/nix/tmp";
};

# Create the directory
systemd.tmpfiles.rules = [
  "d /nix/tmp 0755 root root -"
];


  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM VERSION
  # ═══════════════════════════════════════════════════════════════════════════
  system.stateVersion = "25.05";
}

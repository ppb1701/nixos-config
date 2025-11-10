{ config, pkgs, lib, ... }:

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
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOTLOADER - systemd-boot (UEFI Mode)
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
  users.users.ppb1701 = {
    isNormalUser = true;
    description = "ppb1701";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    # NOTE: Password already set via passwd command - no initialPassword needed
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here if you have them
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SECURITY
  # ═══════════════════════════════════════════════════════════════════════════
  security.sudo.wheelNeedsPassword = true;  # Require password for sudo

  # ═══════════════════════════════════════════════════════════════════════════
  # SSH
  # ═══════════════════════════════════════════════════════════════════════════
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;  # SSH keys only (more secure)
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

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;  # Set to true if you want automatic reboots
    dates = "04:00";  # Run at 4 AM daily
    flake = "github:ppb1701/nixos-config";  # Use your GitHub repo
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM VERSION
  # ═══════════════════════════════════════════════════════════════════════════
  system.stateVersion = "25.05";
}

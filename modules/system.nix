{ config, pkgs, ... }:

let
  # Make private directory available in Nix store
  privateDir = builtins.path {
    path = /etc/nixos/private;
    name = "nixos-private";
  };
in
{
  imports = [
    "${privateDir}/ssh-keys.nix"  # Import SSH authorized keys
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOTLOADER - systemd-boot (UEFI Mode)
  # ═══════════════════════════════════════════════════════════════════════════
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # LOCALE & TIME
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
  # ZSH CONFIGURATION (System-level)
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # USER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  users.users.ppb1701 = {
    isNormalUser = true;
    description = "ppb1701";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;

    # SSH keys imported from private/ssh-keys.nix
    # Password already set via passwd command
    # For future reference, use hashedPassword for security:
    # Generate with: mkpasswd -m sha-512
    # hashedPassword = "your-hashed-password-here";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SECURITY
  # ═══════════════════════════════════════════════════════════════════════════
  security.sudo.wheelNeedsPassword = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES
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
    dig
    jq

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

  # Auto-upgrade (currently disabled)
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = false;
  #   dates = "04:00";
  #   flake = "github:ppb1701/nixos-config";
  # };
}

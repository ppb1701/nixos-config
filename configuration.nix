{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/adguard-home.nix
    ./modules/networking.nix
    ./modules/syncthing.nix

    # Import private device config if it exists
    # This file is gitignored
  ] ++ (if builtins.pathExists ./private/syncthing-devices.nix
        then [ ./private/syncthing-devices.nix ]
        else []);


  # Bootloader
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  # Hostname
  networking.hostName = "nixos";

  # Timezone
  time.timeZone = "America/New_York";

  # Locale
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

  # X11 and Desktop Environment (minimal for occasional local access)
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

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing
  services.printing.enable = true;

  # Keyring
  services.gnome.gnome-keyring.enable = true;

  # SSH (primary remote access method)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";  # Security: disable root login
      PasswordAuthentication = true;  # Can disable after setting up SSH keys
    };
  };

  # User definition
  users.users.ppb1701 = {
    isNormalUser = true;
    description = "Patrick Boyd";
    extraGroups = [ "networkmanager" "wheel" ];  # wheel = sudo access
    # Optional: Add SSH public key for passwordless login
    # openssh.authorizedKeys.keys = [
    #   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-key-here"
    # ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    btop
    neofetch
    gitui

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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # NixOS version
  system.stateVersion = "25.05";
}

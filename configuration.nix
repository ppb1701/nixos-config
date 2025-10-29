{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/adguard-home.nix
    ./modules/networking.nix
    ./modules/rustdesk.nix
    <home-manager/nixos>
  ];

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

  # X11 and Desktop Environment (for RustDesk headless)
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager.lxqt.enable = true;

    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Auto-login for headless operation
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

  # SSH
  services.openssh.enable = true;

  # User definition
  users.users.ppb1701 = {
    isNormalUser = true;
    description = "Patrick Boyd";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # System packages (minimal - most moved to Home Manager)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
  ];

  # Home Manager integration
  home-manager.users.ppb1701 = import ./home/ppb1701.nix;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # NixOS version
  system.stateVersion = "25.05";
}

{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./configuration.nix  # Your modular configuration entry point
  ];

  # ISO image settings
  isoImage = {
    makeEfiBootable = false;
    makeUsbBootable = true;
    isoName = "nixos-adguard-bios.iso";
  };

  # Override boot settings for BIOS/Legacy systems
  boot.loader.systemd-boot.enable = false;  # Disable systemd-boot for BIOS
  boot.loader.grub = {
    enable = true;
    device = "nodev";  # For ISO
    efiSupport = false;
  };

  # Disable services that shouldn't run on the live ISO
  services.adguardhome.enable = false;
  services.syncthing.enable = false;

  # Keep SSH enabled for remote installation
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";  # Allow root login on ISO

  # Simplified networking for ISO (use DHCP instead of static)
  networking.useDHCP = true;
  networking.networkmanager.enable = false;  # Disable NetworkManager on ISO
  networking.wireless.enable = false;

  # Don't set a static IP on the ISO
  networking.interfaces = {};

  # Allow passwordless root on ISO for installation
  users.users.root.initialPassword = "";

  # Include useful tools for installation
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    micro
    parted
    gptfdisk
    dig
    jq
  ];
}

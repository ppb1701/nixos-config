{ config, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Copy your entire config into the ISO
  environment.etc."nixos-config" = {
    source = ./.;
  };

  # Include the install script
  environment.etc."nixos-config/install-nixos.sh" = {
    source = ./install-nixos.sh;
    mode = "0755";  # Make it executable
  };

  # Add useful tools to live environment
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    curl
    parted
    gptfdisk
  ];

  # Enable SSH in live environment (for remote install)
  services.openssh.enable = true;
  users.users.nixos.password = "nixos";

  # Helpful message on login
  environment.etc."issue".text = ''

    ╔════════════════════════════════════════════════════════╗
    ║                                                        ║
    ║   NixOS AdGuard Home Installation ISO                 ║
    ║                                                        ║
    ║   To install: sudo /etc/nixos-config/install-nixos.sh ║
    ║   To explore: cd /etc/nixos-config                    ║
    ║   For help:   cat /etc/nixos-config/README.md         ║
    ║                                                        ║
    ╚════════════════════════════════════════════════════════╝

  '';
}

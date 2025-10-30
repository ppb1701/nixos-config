{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Copy your entire configuration into the ISO
  # This includes install-nixos.sh with its permissions
  environment.etc."nixos-config" = {
    source = ./.;
  };

  environment.systemPackages = with pkgs; [
    git vim htop curl parted gptfdisk
  ];

  services.openssh.enable = true;
  users.users.nixos.password = "nixos";

  environment.etc."issue".text = ''

    ╔════════════════════════════════════════════════════════╗
    ║   NixOS AdGuard Home Installation ISO                 ║
    ║   To install: sudo /etc/nixos-config/install-nixos.sh ║
    ╚════════════════════════════════════════════════════════╝

  '';
}


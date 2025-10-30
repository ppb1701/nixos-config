{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Don't set isoBaseName - let it use the default

  services.openssh.enable = true;
  users.users.root.password = "nixos";

  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    gptfdisk
  ];
}


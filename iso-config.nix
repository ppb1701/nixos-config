{ config, pkgs, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Ensure both UEFI and BIOS boot work
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # ISO settings
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.squashfsCompression = "xz -Xdict-size 100%";

  # Enable SSH and set root password for live environment
  services.openssh.enable = true;
  users.users.root.password = "nixos";

  # Include useful tools in the ISO
  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    gptfdisk
  ];
}


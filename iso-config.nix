{ config, pkgs, lib, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

<<<<<<< HEAD
  # Don't set isoBaseName - let it use the default
=======
  # Ensure both UEFI and BIOS boot work
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Basic ISO settings
  isoImage.isoBaseName = "nixos-config";

  # IMPORTANT: Increase ISO size limit
  isoImage.squashfsCompression = "xz -Xdict-size 100%";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # Explicitly set larger volume size
  isoImage.volumeID = "NIXOS_ISO";
>>>>>>> main

  services.openssh.enable = true;
  users.users.root.password = "nixos";

  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    gptfdisk
  ];
}


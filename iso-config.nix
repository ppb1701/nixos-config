{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
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

  # Copy all files and directories into /etc/nixos on the ISO
  environment.etc = {
    # Root level files
    "nixos/configuration.nix".source = ./configuration.nix;
    "nixos/hardware-configuration.nix".source = ./hardware-configuration.nix;
    "nixos/iso-config.nix".source = ./iso-config.nix;
    "nixos/build-iso.sh".source = ./build-iso.sh;
    "nixos/install-nixos.sh".source = ./install-nixos.sh;
    "nixos/Readme.md".source = ./Readme.md;

    # Directories
    "nixos/modules".source = ./modules;
    "nixos/docs".source = ./docs;
    "nixos/home".source = ./home;
    "nixos/private".source = ./private;
  };

  # Enable SSH and set root password for live environment
  services.openssh.enable = true;
  users.users.root.password = "nixos";

  # Include useful tools in the ISO
  environment.systemPackages = with pkgs; [
    git
    vim
    micro
    parted
    gptfdisk
  ];
}

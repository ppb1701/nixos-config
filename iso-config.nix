
{ config, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Basic ISO settings
  isoImage.isoBaseName = "nixos-config";

  # IMPORTANT: Increase ISO size limit
  isoImage.squashfsCompression = "xz -Xdict-size 100%";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # Explicitly set larger volume size
  isoImage.volumeID = "NIXOS_ISO";

  # Enable SSH for remote installation
  services.openssh.enable = true;

  # Set root password for ISO
  users.users.root.password = "nixos";

  # Minimal packages needed for installation
  environment.systemPackages = with pkgs; [
    git
    vim
    parted
    gptfdisk
  ];
}

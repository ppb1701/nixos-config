# BIOS Boot Configuration (GRUB with MBR)
{ config, pkgs, lib, ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      device = "/dev/sda";  # Install to MBR of the disk
      # Don't specify efiSupport for BIOS mode
    };
  };
}

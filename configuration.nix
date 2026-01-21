{ config, pkgs, lib, ... }:

let
  # Explicitly add modules directory to Nix store
  modulesDir = builtins.path {
    path = /etc/nixos/modules;
    name = "nixos-modules";
  };

  # Explicitly add private directory to Nix store
  privateDir = builtins.path {
    path = /etc/nixos/private;
    name = "nixos-private";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    "${modulesDir}/networking.nix"
    "${modulesDir}/services.nix"
    "${modulesDir}/monitoring.nix"
    "${modulesDir}/system.nix"
    "${modulesDir}/boot-uefi.nix"
    "${modulesDir}/backups.nix"
    <home-manager/nixos>
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # HOME MANAGER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  home-manager.users.ppb1701 = import ./home/ppb1701.nix;
  home-manager.backupFileExtension = "backup";

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM VERSION
  # ═══════════════════════════════════════════════════════════════════════════
  system.stateVersion = "25.05";
}

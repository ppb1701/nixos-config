{ config, pkgs, lib, ... }:
# ⚠️⚠️⚠️ WARNING: CHANGE THIS PASSWORD IMMEDIATELY AFTER FIRST BOOT ⚠️⚠️⚠️
# ⚠️⚠️⚠️ THIS IS A TEMPORARY PASSWORD FOR INITIAL VM SETUP ONLY ⚠️⚠️⚠️
# ⚠️⚠️⚠️ RUN: passwd ppb1701  AFTER FIRST LOGIN ⚠️⚠️⚠️

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
    /etc/nixos/modules/networking.nix
    /etc/nixos/modules/services.nix
    /etc/nixos/modules/monitoring.nix
    /etc/nixos/modules/system.nix
    /etc/nixos/modules/timemachine.nix
    /etc/nixos/modules/nginx-virtualhosts.nix
    /etc/nixos/modules/vm.nix
    /etc/nixos/modules/backups.nix
    /etc/nixos/modules/homepage.nix
    /etc/nixos/modules/boot-uefi.nix
    <home-manager/nixos>
  ];

  # ⚠️⚠️⚠️ WARNING: CHANGE THIS PASSWORD IMMEDIATELY AFTER FIRST BOOT ⚠️⚠️⚠️
  # ⚠️⚠️⚠️ THIS IS A TEMPORARY PASSWORD FOR INITIAL VM SETUP ONLY ⚠️⚠️⚠️
  # ⚠️⚠️⚠️ RUN: passwd ppb1701  AFTER FIRST LOGIN ⚠️⚠️⚠️
  users.users.ppb1701 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };

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

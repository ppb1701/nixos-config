{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # FORCE UEFI BOOT FOR THE ISO ITSELF
  # ═══════════════════════════════════════════════════════════════════════════
  # This makes the ISO bootable on UEFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;  # ISO doesn't need to touch EFI vars

  # Ensure ISO supports both BIOS and UEFI boot
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # COPY CONFIGURATION FILES TO ISO
  # ═══════════════════════════════════════════════════════════════════════════
  environment.etc = pkgs.lib.mkMerge [
    # Base configuration files
    {
      "nixos/configuration.nix".source = ./configuration.nix;
      "nixos/configuration-uefi.nix".source = ./configuration-uefi.nix;
      "nixos/iso-config.nix".source = ./iso-config.nix;
      "nixos/.gitignore".source = ./.gitignore;

      "nixos/install-nixos.sh" = {
        source = ./install-nixos.sh;
        mode = "0755";
      };

      "nixos/build-iso.sh" = {
        source = ./build-iso.sh;
        mode = "0755";
      };

      # Create empty directories
      "nixos/modules/.keep".text = "";
      "nixos/private/.keep".text = "";
    }

    # Conditionally add module files if they exist
    (if builtins.pathExists ./modules/adguard-home.nix then {
      "nixos/modules/adguard-home.nix".source = ./modules/adguard-home.nix;
    } else {})

    (if builtins.pathExists ./modules/networking.nix then {
      "nixos/modules/networking.nix".source = ./modules/networking.nix;
    } else {})

    (if builtins.pathExists ./modules/syncthing.nix then {
      "nixos/modules/syncthing.nix".source = ./modules/syncthing.nix;
    } else {})

    # Conditionally add private files if they exist
    (if builtins.pathExists ./private/secrets.nix then {
      "nixos/private/secrets.nix".source = ./private/secrets.nix;
    } else {})

    (if builtins.pathExists ./private/syncthing-devices.nix then {
      "nixos/private/syncthing-devices.nix".source = ./private/syncthing-devices.nix;
    } else {})
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # AUTO-RUN INSTALLER
  # ═══════════════════════════════════════════════════════════════════════════
  systemd.services.auto-install = {
    description = "Automatic NixOS Installation (Ctrl+C to cancel)";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/install-nixos.sh";
      StandardInput = "tty";
      StandardOutput = "inherit";
      StandardError = "inherit";
      TTYPath = "/dev/tty1";
      TTYReset = "yes";
      TTYVHangup = "yes";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # LIVE ENVIRONMENT SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    micro
    htop
    parted
    gptfdisk
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  services.getty.autologinUser = "nixos";

  nixpkgs.hostPlatform = "x86_64-linux";
}

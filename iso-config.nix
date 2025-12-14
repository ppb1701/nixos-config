{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    "home-manager=${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz"}"
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # COPY CONFIGURATION FILES TO ISO
  # ═══════════════════════════════════════════════════════════════════════════

  # Copy individual configuration files
  environment.etc."nixos/configuration.nix".source = ./configuration.nix;
  environment.etc."nixos/configuration-uefi.nix".source = ./configuration-uefi.nix;
  environment.etc."nixos/configuration-bios.nix".source = ./configuration-bios.nix;
  environment.etc."nixos/iso-config.nix".source = ./iso-config.nix;
  environment.etc."nixos/.gitignore".source = ./.gitignore;
  environment.etc."nixos/hardware-configuration.nix".source = ./hardware-configuration.nix;
  environment.etc."nixos/starship.toml".source = ./starship.toml;
  environment.etc."nixos/Readme.md".source = ./Readme.md;

  # Copy scripts with executable permissions
  environment.etc."nixos/install-nixos.sh" = {
    source = ./install-nixos.sh;
    mode = "0755";
  };
  environment.etc."nixos/build-iso.sh" = {
    source = ./build-iso.sh;
    mode = "0755";
  };

  # Copy modules directory files
  environment.etc."nixos/modules/boot-bios.nix".source = ./modules/boot-bios.nix;
  environment.etc."nixos/modules/boot-uefi.nix".source = ./modules/boot-uefi.nix;
  environment.etc."nixos/modules/networking.nix".source = ./modules/networking.nix;
  environment.etc."nixos/modules/services.nix".source = ./modules/services.nix;
  environment.etc."nixos/modules/system.nix".source = ./modules/system.nix;

  # Copy home directory files
  environment.etc."nixos/home/ppb1701.nix".source = ./home/ppb1701.nix;

  # Copy private directory files
  environment.etc."nixos/private/ssh-keys.nix".source = ./private/ssh-keys.nix;
  environment.etc."nixos/private/secrets.nix".source = ./private/secrets.nix;
  environment.etc."nixos/private/ssh-keys.nix".source = ./private/alertmanager.env;
  environment.etc."nixos/private/syncthing-devices.nix".source = ./private/syncthing-devices.nix;
  environment.etc."nixos/private/syncthing-secrets.nix".source = ./private/syncthing-secrets.nix;

  # ═══════════════════════════════════════════════════════════════════════════
  # AUTO-RUN INSTALLER ON BOOT
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
  services.getty.autologinUser = "nixos";

  networking.hostName = "nixos-installer";
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    parted
    gptfdisk
    micro
    jq
    dig
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  system.stateVersion = "25.05";
}
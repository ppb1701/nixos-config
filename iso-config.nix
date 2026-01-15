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
  environment.etc."nixos/modules/monitoring.nix".source = ./modules/monitoring.nix;
  environment.etc."nixos/modules/system.nix".source = ./modules/system.nix;

  # Copy home directory files
  environment.etc."nixos/home/ppb1701.nix".source = ./home/ppb1701.nix;

  # Copy private directory files
  environment.etc."nixos/private/ssh-keys.nix".source = ./private/ssh-keys.nix;
  environment.etc."nixos/private/secrets.nix".source = ./private/secrets.nix;
  environment.etc."nixos/private/alertmanager.env".source = ./private/alertmanager.env;
  environment.etc."nixos/private/vaultwarden.env".source = ./private/vaultwarden.env;
  environment.etc."nixos/private/syncthing-devices.nix".source = ./private/syncthing-devices.nix;
  environment.etc."nixos/private/syncthing-secrets.nix".source = ./private/syncthing-secrets.nix;
  environment.etc."nixos/private/notediscovery-config.nix".source = ./private/notediscovery-config.nix;
  environment.etc."nixos/private/notediscovery-config.yaml".source = ./private/notediscovery-config.yaml;
  environment.etc."nixos/private/nextcloud-admin-pass".source = ./private/nextcloud-admin-pass;


  # Copy private-example directory files (these become the default private files in the ISO)
  environment.etc."nixos/private-example/README.md".source = ./private-example/README.md;
  environment.etc."nixos/private-example/secrets.nix".source = ./private-example/secrets.nix;
  environment.etc."nixos/private-example/vaultwarden.env".source = ./private-example/vaultwarden.env;
  environment.etc."nixos/private-example/ssh-keys.nix".source = ./private-example/ssh-keys.nix;
  environment.etc."nixos/private-example/alertmanager.env".source = ./private-example/alertmanager.env;
  environment.etc."nixos/private-example/syncthing-devices.nix".source =   ./private-example/syncthing-devices.nix;
  environment.etc."nixos/private-example/syncthing-secrets.nix".source = ./private-example/syncthing-secrets.nix;
  environment.etc."nixos/private-example/notediscovery-config.nix".source = ./private-example/notediscovery-config.nix;
  environment.etc."nixos/private-example/notediscovery-config.yaml".source = ./private-example/notediscovery-config.yaml;
  environment.etc."nixos/private-example/nextcloud-admin-pass".source = ./private-example/nextcloud-admin-pass;

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

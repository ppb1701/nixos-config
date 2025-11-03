{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Copy configuration files to the ISO
  environment.etc = {
    "nixos/configuration.nix".source = ./configuration.nix;
    "nixos/iso-config.nix".source = ./iso-config.nix;
    "nixos/install-nixos.sh" = {
      source = ./install-nixos.sh;
      mode = "0755";
    };
    "nixos/build-iso.sh" = {
      source = ./build-iso.sh;
      mode = "0755";
    };
    "nixos/.gitignore".source = ./.gitignore;
  };

  # Copy modules directory
  environment.etc."nixos/modules" = {
    source = ./modules;
  };

  # Copy private directory if it exists (for passwords/secrets)
  environment.etc."nixos/private" = {
    source = if builtins.pathExists ./private then ./private else builtins.toFile "empty" "";
  };

  # AUTO-RUN: Start installation script on boot
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

  # Networking
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  # System packages for the live environment
  environment.systemPackages = with pkgs; [
    git
    vim
    micro
    htop
    parted
    gptfdisk
  ];

  # Enable SSH for remote installation if needed
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Auto-login as nixos user (for manual intervention if needed)
  services.getty.autologinUser = "nixos";

  nixpkgs.hostPlatform = "x86_64-linux";
}

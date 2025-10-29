{ config, pkgs, ... }:

{
  home.stateVersion = "25.05";

  # User packages
  home.packages = with pkgs; [
    vivaldi
    gitui
    lxde.lxtask
    btop
    neofetch

    # LXQT extras
    lxqt.screengrab
    lxqt.pavucontrol-qt
    lxqt.qterminal
    lxqt.pcmanfm-qt
    lxmenu-data
    menu-cache
    lxqt.lximage-qt
    lxqt.lxqt-archiver
    lxqt.lxqt-sudo
    libsForQt5.breeze-icons
    networkmanagerapplet
    feh
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Patrick Boyd";
    userEmail = "your.email@example.com";  # Update this!

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Bash configuration
  programs.bash = {
    enable = true;

    shellAliases = {
      ll = "ls -lah";
      ".." = "cd ..";
      rebuild = "sudo nixos-rebuild switch";
      update = "sudo nixos-rebuild switch --upgrade";
    };
  };
}

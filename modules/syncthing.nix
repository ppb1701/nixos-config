{ config, pkgs, ... }:

let
  secrets = import ../private/syncthing-secrets.nix;
in
{
  services.syncthing = {
    enable = true;
    user = "ppb1701";
    dataDir = "/home/ppb1701";
    configDir = "/home/ppb1701/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      gui = {
        user = "ppb1701";
        password = secrets.guiPassword;  # From private file
      };
    };
  };

  imports = [
    ../private/syncthing-devices.nix
  ];
}

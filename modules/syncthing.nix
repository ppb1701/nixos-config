{ config, pkgs, lib, ... }:

let
  # Make private directory available in Nix store
  privateDir = builtins.path {
    path = /etc/nixos/private;
    name = "nixos-private";
  };
in
{
  imports = [
    "${privateDir}/syncthing-devices.nix"
  ];

  services.syncthing = {
    enable = true;
    user = "ppb1701";
    group = "users";
    dataDir = "/home/ppb1701/.local/share/syncthing";
    configDir = "/home/ppb1701/.config/syncthing";

    # Allow access from network (not just localhost)   

    settings = {
      gui = {
        user = "ppb1701";
        password = lib.mkDefault "";
      };
    };
  };
}

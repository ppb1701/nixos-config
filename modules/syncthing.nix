# modules/syncthing.nix
{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    user = "youruser";  # Placeholder
    dataDir = "/home/youruser";
    configDir = "/home/youruser/.config/syncthing";

    # Import device and folder definitions from private file
    # This file is gitignored and contains your actual setup
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      options = {
        # Rate limiting
        maxRecvKbps = 10000;  # 10 MB/s
        maxSendKbps = 5000;   # 5 MB/s

        # Network settings
        localAnnounceEnabled = true;
        globalAnnounceEnabled = false;
        relaysEnabled = false;

        # GUI settings
        urAccepted = -1;  # Disable usage reporting
      };

      # GUI access (localhost only by default)
      gui = {
        theme = "default";
      };

      # Device and folder definitions imported from private file
      # See private/syncthing-devices.nix.example
      devices = {};  # Populated from private file
      folders = {};  # Populated from private file
    };
  };

  # Firewall rules
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];  # Syncthing transfers
    allowedUDPPorts = [ 22000 21027 ];  # Syncthing discovery
  };
}

{ config, pkgs, ... }:

{
  # ═══════════════════════════════════════════════════════════════════════════
  # HOSTNAME
  # ═══════════════════════════════════════════════════════════════════════════
  networking.hostName = "nixos";

  # ═══════════════════════════════════════════════════════════════════════════
  # DNS CONFIGURATION - Control D (Fixed DNS Loop!)
  # ═══════════════════════════════════════════════════════════════════════════
  networking.nameservers = [ "76.76.2.2" "76.76.10.2" ];

  # ═══════════════════════════════════════════════════════════════════════════
  # NETWORKMANAGER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    insertNameservers = [ "76.76.2.2" "76.76.10.2" ];

    # Declaratively configure the wired connection
    # This prevents DHCP from overriding our DNS settings
    ensureProfiles = {
      environmentFiles = [ ];
      profiles = {
        "Wired connection 1" = {
          connection = {
            id = "Wired connection 1";
            uuid = "8e533501-4cf6-377b-b52c-2ae7c2c26b3a";
            type = "ethernet";
            interface-name = "enp1s0";
          };
          ipv4 = {
            method = "auto";
            ignore-auto-dns = true;  # Ignore DHCP DNS (prevents loop!)
            dns = "76.76.2.2;76.76.10.2;";
          };
          ipv6 = {
            method = "auto";
            ignore-auto-dns = true;
          };
        };
      };
    };
  };

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # FIREWALL CONFIGURATION (CONSOLIDATED FROM services.nix)
  # ═══════════════════════════════════════════════════════════════════════════
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22      # SSH
      53      # DNS (TCP) - AdGuard Home
      80      # HTTP - Nginx
      443     # HTTPS
      3000    # AdGuard Home web UI (direct access)
      8384    # Syncthing web UI (direct access)
      22000   # Syncthing file transfers
    ];

    allowedUDPPorts = [
      53      # DNS (UDP) - CRITICAL for AdGuard Home!
      22000   # Syncthing discovery
      21027   # Syncthing discovery
    ];
  };
}

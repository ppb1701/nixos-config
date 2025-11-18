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
  # FIREWALL CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      22      # SSH
      53      # DNS (TCP)
      80      # HTTP
      443     # HTTPS
      3000    # AdGuard Home web UI
      8384    # Syncthing web UI
      22000   # Syncthing sync protocol
    ];

    allowedUDPPorts = [
      53      # DNS (UDP) - CRITICAL for AdGuard Home!
      22000   # Syncthing sync protocol
    ];
  };
}

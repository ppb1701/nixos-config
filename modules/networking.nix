{ config, pkgs, ... }:

{
  # Disable systemd-resolved to free port 53 for AdGuard Home
  services.resolved.enable = false;

  # ═══════════════════════════════════════════════════════════════════════════
  # HOSTNAME
  # ═══════════════════════════════════════════════════════════════════════════
  networking.hostName = "nixos";

  
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      #"net.ipv6.conf.all.forwarding" = 1;
    };
  
  #networking.extraHosts = ''
   # 127.0.0.1 git.home
   # # OR use the LAN IP if Gitea moves to NixOS 1 as the main server
    ## 192.168.X.X git.home
  #'';

  # ═══════════════════════════════════════════════════════════════════════════
  # DNS CONFIGURATION - Control D (Fixed DNS Loop!)
  # ═══════════════════════════════════════════════════════════════════════════
  networking.nameservers = [ "76.76.2.2" "76.76.10.2" ];

  # ═══════════════════════════════════════════════════════════════════════════
  # NETWORKMANAGER CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  networking.networkmanager = {
    enable = true;
    dns = "default";
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
      2212    # SSH
      53      # DNS (TCP) - AdGuard Home
      80      # HTTP - Nginx, Nextcloud
      443     # HTTPS
      3000    # AdGuard Home web UI (direct access)
	  5000    # Note Discovery (direct access)
	  #8280    # Nextcloud
      #8000   # temp httpserver file transfer.  disable for harden normal use.
      8384    # Syncthing web UI (direct access)
      22000   # Syncthing file transfers
      3001    # Grafana
      2586    # ntfy
      9090    # Prometheus (optional - can access via nginx)
      9205    #Prometheus Nextcloud
      #8888    #SearX
    ];

    allowedUDPPorts = [
      53      # DNS (UDP) - CRITICAL for AdGuard Home!
      22000   # Syncthing discovery
      21027   # Syncthing discovery
    ];
    # Trust Tailscale interface
    trustedInterfaces = [ "tailscale0" "docker0" ];
    
    # Required for Tailscale NAT traversal
    checkReversePath = "loose";
  };
}

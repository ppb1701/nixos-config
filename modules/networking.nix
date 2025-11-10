{ config, pkgs, ... }:

{
  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # ============================================================
  # NETWORK CONFIGURATION
  # ============================================================
  # For VM: Use DHCP (static IP commented out)
  # For Physical Machine: Uncomment static IP section below
  # ============================================================

  # Static IP configuration (COMMENTED OUT FOR VM TESTING)
  # Uncomment these lines for physical machine deployment
  # IMPORTANT: Change interface name to match your hardware!
  # Find interface name with: ip addr show

  # networking.interfaces.enp0s3 = {  # ← CHANGE THIS to your interface name!
  #   ipv4.addresses = [{
  #     address = "192.168.1.154";
  #     prefixLength = 24;
  #   }];
  # };
  # 
  # networking.defaultGateway = "192.168.1.1";
  # networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];  # Fallback DNS

  # ============================================================
  # FIREWALL CONFIGURATION
  # ============================================================

  networking.firewall = {
    enable = true;

    # AdGuard Home ports (automatically opened by openFirewall = true in adguard module)
    # But we list them here for documentation
    # Port 53 (DNS) and 3000 (Web UI) opened by AdGuard Home module

  allowedTCPPorts = [ 
         22      # SSH
         53      # DNS (TCP) - ADD THIS
         80      # HTTP
         443     # HTTPS
         3000    # AdGuard Home web UI
         8384    # Syncthing web UI      
       ];
       allowedUDPPorts = [ 
         53      # DNS (UDP) - ADD THIS (CRITICAL!)        
       ];
  };
}

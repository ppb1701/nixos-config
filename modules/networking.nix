{ config, pkgs, ... }:

{
  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # Static IP configuration
  networking.interfaces.enp0s3 = {  # Change to your interface name!
    ipv4.addresses = [{
      address = "192.168.1.154";
      prefixLength = 24;
    }];
  };

  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];  # Fallback DNS

  # Firewall configuration
  networking.firewall = {
    enable = true;

    # AdGuard Home ports (opened automatically by openFirewall = true)
    # RustDesk ports (LAN only)
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };
}

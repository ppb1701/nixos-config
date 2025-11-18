{ config, pkgs, ... }:

{
  # AdGuard Home - DNS filtering and ad blocking
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    host = "0.0.0.0";
    port = 3000;

    settings = {
      users = [];

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        upstream_dns = [
          "76.76.2.2"
          "76.76.10.2"
          "9.9.9.9"
          "149.112.112.112"
        ];

        bootstrap_dns = [
          "9.9.9.9"
          "149.112.112.112"
        ];

        enable_dnssec = true;
        edns_client_subnet = {
          enabled = false;
        };
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
      };
    };
  };

  # Syncthing - File synchronization
  services.syncthing = {
    enable = true;
    user = "ppb1701";
    dataDir = "/home/ppb1701";
    configDir = "/home/ppb1701/.config/syncthing";

    guiAddress = "0.0.0.0:8384";  # Allow connections from any interface

    overrideDevices = true;
    overrideFolders = true;

    settings = import /etc/nixos/private/syncthing-secrets.nix;
  };

  # Nginx - Reverse Proxy for clean local URLs
 # Nginx - Reverse Proxy for clean local URLs
 services.nginx = {
   enable = true;
 
   recommendedProxySettings = true;
   recommendedTlsSettings = true;
 
   virtualHosts = {
     "adguard.home" = {
       default = true;  # Make this the default server
       locations."/" = {
         proxyPass = "http://127.0.0.1:3000";
         proxyWebsockets = true;
       };
     };
 
     "syncthing.home" = {
       locations."/" = {
         proxyPass = "http://127.0.0.1:8384";
         proxyWebsockets = true;
       };
     };
   };
 };
 

  # Firewall rules
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22      # SSH
      53      # AdGuard Home DNS
      80      # Nginx HTTP
      3000    # AdGuard Home web UI (direct access)
      8384    # Syncthing web UI (direct access)
      22000   # Syncthing file transfers
    ];
    allowedUDPPorts = [
      53      # AdGuard Home DNS
      22000   # Syncthing discovery
      21027   # Syncthing discovery
    ];
  };
}

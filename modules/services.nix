{ config, pkgs, ... }:

{
  # ═══════════════════════════════════════════════════════════════════════════
  # ADGUARD HOME - DNS FILTERING AND AD BLOCKING
  # ═══════════════════════════════════════════════════════════════════════════
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

  # ═══════════════════════════════════════════════════════════════════════════
  # SYNCTHING - FILE SYNCHRONIZATION
  # ═══════════════════════════════════════════════════════════════════════════
  services.syncthing = {
    enable = true;
    user = "ppb1701";
    dataDir = "/home/ppb1701";
    configDir = "/home/ppb1701/.config/syncthing";

    guiAddress = "0.0.0.0:8384";

    overrideDevices = true;
    overrideFolders = true;

    settings = import /etc/nixos/private/syncthing-secrets.nix;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # NGINX - REVERSE PROXY FOR CLEAN LOCAL URLS
  # ═══════════════════════════════════════════════════════════════════════════
  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "adguard.home" = {
        default = true;
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
}

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

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEMD-RESOLVED (DNS Resolution Service)
  # ═══════════════════════════════════════════════════════════════════════════
  services.resolved = {
    enable = true;
    dnssec = "false";
    domains = [ "~." ];
    fallbackDns = [ "76.76.2.2" "76.76.10.2" ];
    extraConfig = ''
      [Resolve]
      DNS=76.76.2.2 76.76.10.2
      FallbackDNS=76.76.2.2 76.76.10.2
      DNSStubListener=no
    '';
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # ADGUARD HOME (Network-wide Ad Blocking & DNS)
  # ═══════════════════════════════════════════════════════════════════════════
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    openFirewall = true;

    settings = {
      schema_version = 28;

      # Web interface
      http.address = "0.0.0.0:3000";

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
          "9.9.9.10"
          "149.112.112.10"
        ];

        # Local DNS mappings
        rewrites = [
          {
            domain = "router.local";
            answer = "192.168.50.1";
          }
          {
            domain = "gateway.local";
            answer = "192.168.50.1";
          }
        ];

        resolve_clients = true;
        use_private_ptr_resolvers = true;

        local_ptr_upstreams = [
          "192.168.50.1"  # ASUS router
        ];
      };

      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
          hosts = true;
        };
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;

        # Custom filtering rules for streaming services
        custom_rules = [
          # ===== PARAMOUNT+ RULES =====
          "||ads.cbsi.com^"
          "||ads-fa.cdn.cbsi.com^"
          "||cbsinteractive.hb.omtrdc.net^"
          "||pubads.g.doubleclick.net^"
          "@@||cbsaavideo.com^"
          "@@||cbsi.com^"
          "@@||cbsivideo.com^"
          "@@||paramount.com^"
          "@@||link.theplatform.com^"

          # ===== HISTORY CHANNEL RULES =====
          "||ads.aenetworks.com^"
          "||ads-east.aenetworks.com^"
          "||ads-west.aenetworks.com^"
          "||googleads.g.doubleclick.net^"
          "@@||aenetworks.com^"
          "@@||history.com^"
          "@@||historyvault.com^"

          # ===== APPLE TV: BLOCK iCLOUD PRIVATE RELAY =====
          "||mask.icloud.com^"
          "||mask-h2.icloud.com^"
          "||mask-api.icloud.com^"
        ];
      };

      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt";
          name = "Peter Lowe's List";
          id = 2;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_5.txt";
          name = "OISD Small";
          id = 3;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
          name = "The Big List of Hacked Malware Web Sites";
          id = 4;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
          name = "Malicious URL Blocklist";
          id = 5;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
          name = "HaGeZi's Pro Blocklist";
          id = 6;
        }
      ];

      querylog = {
        enabled = true;
        interval = "2160h";
        size_memory = 1000;
      };

      statistics = {
        enabled = true;
        interval = "24h";
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYNCTHING (File Synchronization)
  # ═══════════════════════════════════════════════════════════════════════════
  services.syncthing = {
    enable = true;
    user = "ppb1701";
    group = "users";
    dataDir = "/home/ppb1701/.local/share/syncthing";
    configDir = "/home/ppb1701/.config/syncthing";

    settings = {
      gui = {
        user = "ppb1701";
        password = lib.mkDefault "";
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SSH (Secure Shell)
  # ═══════════════════════════════════════════════════════════════════════════
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;  # SSH keys only
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # OTHER SERVICES
  # ═══════════════════════════════════════════════════════════════════════════
  services.printing.enable = true;
  services.gnome.gnome-keyring.enable = true;
}

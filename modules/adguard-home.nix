{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;

    # Make settings immutable (fully declarative)
    mutableSettings = false;

    # Open firewall ports automatically
    openFirewall = true;

    settings = {
      # Schema version (important!)
      schema_version = 28;

      # Web interface - accessible from network
      http.address = "0.0.0.0:3000";

      # DNS configuration
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        # Upstream DNS servers
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
          "9.9.9.9"
          "149.112.112.112"
        ];

        # Bootstrap DNS (for resolving DoH servers)
        bootstrap_dns = [
          "9.9.9.10"
          "149.112.112.10"
        ];

        # Client identification settings
        resolve_clients = true;
        use_private_ptr_resolvers = true;

        # Point to your router for client name resolution
        local_ptr_upstreams = [
          "192.168.1.1"  # Your ASUS router
        ];
      };

      # Client identification sources
      clients = {
        runtime_sources = {
          whois = true;
          arp = true;
          rdns = true;
          dhcp = true;
          hosts = true;
        };
      };

      # Filtering settings
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
      };

      # Filter lists (corrected format)
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

      # Query logging
      querylog = {
        enabled = true;
        interval = "2160h";  # 90 days
        size_memory = 1000;
      };

      # Statistics
      statistics = {
        enabled = true;
        interval = "24h";
      };
    };
  };
}

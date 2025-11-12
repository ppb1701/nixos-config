{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    openFirewall = true;

    settings = {
      schema_version = 28;

      # Web interface - works for both VM and physical machine
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

        # LOCAL DNS MAPPINGS (this is where your router goes)
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

        # MOVED INSIDE dns block (was outside before)
        resolve_clients = true;
        use_private_ptr_resolvers = true;

        # Works on physical machine, ignored in VM
        local_ptr_upstreams = [
          "192.168.50.1"  # Your ASUS router
        ];
      };  # <- dns closes HERE (after local_ptr_upstreams)

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
}

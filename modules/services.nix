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

  # Tailscale - Zero-config mesh VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";  # Enable subnet routing if needed
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # NGINX - REVERSE PROXY FOR CLEAN LOCAL URLS
  # ═══════════════════════════════════════════════════════════════════════════
  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Enable stub_status for Prometheus nginx exporter
   # Enable stub_status for Prometheus nginx exporter
appendHttpConfig = ''
  server {
    listen 127.0.0.1:8080;
    location /nginx_status {
      stub_status on;
      access_log off;
    }
  }
'';

    virtualHosts = {
		
		# ntfy notification service
		"ntfy.home" = {
		  locations."/" = {
		    proxyPass = "http://localhost:2586";
		    proxyWebsockets = true;
		  };
		};
		
		# Alertmanager UI (optional, for viewing alert status)
		"alertmanager.home" = {
		  locations."/" = {
		    proxyPass = "http://localhost:9093";
		  };
		};
    
		"grafana.home" = {
  			locations."/" = {
    		proxyPass = "http://127.0.0.1:3001";
    		proxyWebsockets = true;
  			};
		};

		"prometheus.home" = {
  			locations."/" = {
    		proxyPass = "http://127.0.0.1:9090";
     		};
   		};
    
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

  # ═══════════════════════════════════════════════════════════════════════════
  # PROMETHEUS - METRICS COLLECTION
  # ═══════════════════════════════════════════════════════════════════════════
  services.prometheus = {
    enable = true;
    port = 9090;
  
    # Retention period for metrics (adjust as needed)
    retentionTime = "30d";
  
    exporters = {
      # System metrics (CPU, memory, disk, network)
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
  
      # Nginx metrics
      nginx = {
        enable = true;
        port = 9113;
        scrapeUri = "http://127.0.0.1:8080/nginx_status";
      };
    };
  
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
      {
        job_name = "nginx";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" ];
        }];
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
        }];
      }
    ];
  };
  
  # ═══════════════════════════════════════════════════════════════════════════
  # GRAFANA - VISUALIZATION DASHBOARD
  # ═══════════════════════════════════════════════════════════════════════════
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3001;
        domain = "grafana.home";
      };
  
      # Security settings
      security = {
            admin_user = "admin";
            # Import password from separate file
            admin_password = (import /etc/nixos/private/secrets.nix).grafanaPassword;
      };
    };
  
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
    };
  };
  
 # ═══════════════════════════════════════════════════════════════════════════
 # LOKI - LOG AGGREGATION (OPTIONAL BUT RECOMMENDED)
 # ═══════════════════════════════════════════════════════════════════════════
 services.loki = {
   enable = true;
   configuration = {
     server.http_listen_port = 3100;
     auth_enabled = false;
 
     ingester = {
       lifecycler = {
         address = "127.0.0.1";
         ring = {
           kvstore = {
             store = "inmemory";
           };
           replication_factor = 1;
         };
       };
       chunk_idle_period = "1h";
       max_chunk_age = "1h";
       chunk_target_size = 999999;
       chunk_retain_period = "30s";
     };
 
     schema_config = {
       configs = [{
         from = "2022-06-06";
         store = "tsdb";
         object_store = "filesystem";
         schema = "v13";
         index = {
           prefix = "index_";
           period = "24h";
         };
       }];
     };
 
     storage_config = {
       tsdb_shipper = {
         active_index_directory = "/var/lib/loki/tsdb-index";
         cache_location = "/var/lib/loki/tsdb-cache";
       };
 
       filesystem = {
         directory = "/var/lib/loki/chunks";
       };
     };
 
     limits_config = {
       reject_old_samples = true;
       reject_old_samples_max_age = "168h";
     };
 
     compactor = {
       working_directory = "/var/lib/loki";
       compactor_ring = {
         kvstore = {
           store = "inmemory";
         };
       };
     };
   };
 };

# ═══════════════════════════════════════════════════════════════════════════
# NTFY - SELF-HOSTED NOTIFICATION SERVICE
# ═══════════════════════════════════════════════════════════════════════════
services.ntfy-sh = {
  enable = true;
  settings = {
    base-url = "http://ntfy.home";
    listen-http = "0.0.0.0:2586";

    # Enable message caching with SQLite (survives restarts)
    cache-file = "/var/lib/ntfy-sh/cache.db";
    cache-duration = "24h";

    # Keep messages for 12 hours so you can catch up when connecting via Tailscale
    keepalive-interval = "45s";

    # Disable public access (only accessible on your network)
    auth-default-access = "read-write";
  };
};

# ═══════════════════════════════════════════════════════════════════════════
# ALERTMANAGER - ALERT ROUTING AND NOTIFICATION
# ═══════════════════════════════════════════════════════════════════════════
services.prometheus.alertmanager = {
  enable = true;
  port = 9093;

  configuration = {
    route = {
      receiver = "ntfy";
      group_by = [ "alertname" "severity" ];
      group_wait = "30s";
      group_interval = "5m";
      repeat_interval = "4h";
    };

    receivers = [
      {
        name = "ntfy";
        webhook_configs = [
          {
            url = "http://localhost:2586/nixos";
            send_resolved = true;
          }
        ];
      }
    ];
  };
};

# ═══════════════════════════════════════════════════════════════════════════
# PROMETHEUS ALERT RULES
# ═══════════════════════════════════════════════════════════════════════════
services.prometheus.rules = [
  ''
    groups:
      - name: system_alerts
        interval: 30s
        rules:
          # Alert if any systemd service fails
          - alert: ServiceDown
            expr: node_systemd_unit_state{state="failed"} == 1
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Service {{ $labels.name }} is down"
              description: "Systemd service {{ $labels.name }} has been in failed state for more than 5 minutes."

          # Alert if disk usage is above 85%
          - alert: DiskSpaceWarning
            expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 15
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "Disk space low on {{ $labels.mountpoint }}"
              description: "Disk {{ $labels.mountpoint }} has less than 15% space remaining ({{ $value | humanize }}% free)."

          # Alert if disk usage is above 95%
          - alert: DiskSpaceCritical
            expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 5
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Disk space critically low on {{ $labels.mountpoint }}"
              description: "Disk {{ $labels.mountpoint }} has less than 5% space remaining!"

          # Alert if CPU usage is high for extended period
          - alert: HighCPUUsage
            expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "High CPU usage detected"
              description: "CPU usage has been above 80% for more than 15 minutes (current: {{ $value | humanize }}%)."

          # Alert if memory usage is high
          - alert: HighMemoryUsage
            expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage detected"
              description: "Memory usage has been above 90% for more than 10 minutes (current: {{ $value | humanize }}%)."

          # Alert if Nginx is returning lots of 5xx errors
          - alert: NginxHighErrorRate
            expr: rate(nginx_http_requests_total{status=~"5.."}[5m]) > 0.05
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High rate of 5xx errors from Nginx"
              description: "Nginx is returning {{ $value | humanize }} 5xx errors per second."
  ''
];

   
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "nixos";
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }
      ];
    };
  };
  
}

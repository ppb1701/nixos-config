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
  # TAILSCALE - ZERO-CONFIG MESH VPN
  # ═══════════════════════════════════════════════════════════════════════════
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # Nextcloud - Private Cloud
  # ═══════════════════════════════════════════════════════════════════════════
  
  services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
  
      hostName = "nextcloud.home";  # Or use localhost for local-only
  
      # Database configuration
      database.createLocally = true;
      config = {
        dbtype = "pgsql";  # PostgreSQL is recommended
        adminpassFile = "/etc/nixos/private/nextcloud-admin-pass";

      };
  
      datadir = "/mnt/nextcloud-data";
  
      # Enable HTTPS
      https = false;

      settings = {
          "auth.bruteforce.protection.enabled" = false;
          "ratelimit.protection.enabled" = false;
          "overwriteprotocol" = "http";
          trusted_domains = [
          	"nextcloud.home"
          	"localhost"          	
          	"nextcloud.vpn"
          ];
          trusted_proxies = [
                "100.64.0.0/10"  # Entire Tailscale IP range
              ];
        };

      # PHP settings for better performance
      phpOptions = {
        "opcache.interned_strings_buffer" = "16";
        "opcache.max_accelerated_files" = "10000";
        "opcache.memory_consumption" = "128";
        "opcache.revalidate_freq" = "1";
        "opcache.fast_shutdown" = "1";
      };
  
      # Auto-update apps
      autoUpdateApps.enable = true;
      autoUpdateApps.startAt = "05:00:00";
    };

    # Nextcloud Prometheus exporter
    services.prometheus.exporters.nextcloud = {
      enable = true;
      url = "http://nextcloud.home";
      username = "root";
      passwordFile = "/etc/nixos/private/nextcloud-admin-pass";
      port = 9205;
    };

services.nginx.virtualHosts."nextcloud.home".listen = [
  { addr = "0.0.0.0"; port = 8280; }
  { addr = "[::]"; port = 8280; }
];

  # ═══════════════════════════════════════════════════════════════════════════
  # NGINX - REVERSE PROXY FOR CLEAN LOCAL URLS
  # ═══════════════════════════════════════════════════════════════════════════
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

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
      "ntfy.home" = {
        locations."/" = {
          proxyPass = "http://localhost:2586";
          proxyWebsockets = true;
        };
      };

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

      "notes.home" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:5000";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
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
    retentionTime = "30d";

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };

      nginx = {
        enable = true;
        port = 9113;
        scrapeUri = "http://127.0.0.1:8080/nginx_status";
      };

      # Blackbox Exporter for HTTP health checks
      blackbox = {
        enable = true;
        port = 9115;
        configFile = pkgs.writeText "blackbox.yml" ''
          modules:
            http_2xx:
              prober: http
              timeout: 5s
              http:
                valid_status_codes: [200]
                method: GET
                follow_redirects: true
                preferred_ip_protocol: "ip4"
        '';
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
       # Nextcloud metrics exporter
  {
    job_name = "nextcloud";
    static_configs = [{
      targets = [ "localhost:9205" ];
    }];
  }

  # Nextcloud HTTP health check
  {
    job_name = "nextcloud-http";
    metrics_path = "/probe";
    params.module = [ "http_2xx" ];
    static_configs = [{
      targets = [ "http://nextcloud.home" ];
    }];
    relabel_configs = [
      {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      }
      {
        source_labels = [ "__param_target" ];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = "localhost:9115";
      }
    ];
  }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
        }];
      }
      {
        job_name = "syncthing";
        metrics_path = "/metrics";
        static_configs = [{
          targets = [ "127.0.0.1:8384" ];
        }];
        basic_auth = (import /etc/nixos/private/syncthing-secrets.nix).prometheus_auth;
      }
      # Blackbox exporter probes for HTTP health checks
      {
        job_name = "blackbox";
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        static_configs = [{
          targets = [
            "http://127.0.0.1:5000"      # NoteDiscovery
            "http://127.0.0.1:8384"      # Syncthing GUI
            "http://127.0.0.1:3000"      # AdGuard Home
          ];
        }];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9115";
          }
        ];
      }
    ];

  # Alert Rules
    rules = [
      ''
        groups:
          - name: system_alerts
            interval: 30s
            rules:
              - alert: ServiceDown
                expr: up == 0
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "Service down"
                  description: "A service has been down for more than 2 minutes."
    
              - alert: HTTPProbeFailure
                expr: probe_success{job="blackbox"} == 0
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "HTTP probe failed for {{ $labels.instance }}"
                  description: "{{ $labels.instance }} has been unreachable via HTTP for more than 2 minutes."
    
              - alert: DiskSpaceWarning
                expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 20
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "Low disk space on root filesystem"
                  description: "Root filesystem has less than 20 percent space remaining."
    
              - alert: DiskSpaceCritical
                expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "Critical disk space on root filesystem"
                  description: "Root filesystem has less than 10 percent space remaining."
    
              - alert: HighCPUUsage
                expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "High CPU usage detected"
                  description: "CPU usage is above 80 percent for more than 10 minutes."
    
              - alert: HighMemoryUsage
                expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High memory usage detected"
                  description: "Memory usage is above 90 percent."
    
              - alert: NginxHighErrorRate
                expr: rate(nginx_http_requests_total{status=~"5.."}[5m]) > 0.05
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High Nginx 5xx error rate"
                  description: "Nginx is returning too many 5xx errors."
    
          - name: nextcloud
            rules:
              - alert: NextcloudDown
                expr: probe_success{job="nextcloud-http"} == 0
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Nextcloud is unreachable"
                  description: "Nextcloud HTTP check has failed for 5 minutes"
    
              - alert: NextcloudDiskSpaceLow
                expr: (nextcloud_system_disk_free_bytes / nextcloud_system_disk_total_bytes) < 0.1
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "Nextcloud disk space low"
                  description: "Less than 10% free space on Nextcloud data drive"
      ''
    ];

    alertmanagers = [
      {
        static_configs = [{
          targets = [ "127.0.0.1:9093" ];
        }];
      }
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # ALERTMANAGER - ALERT ROUTING AND NOTIFICATION
  # ═══════════════════════════════════════════════════════════════════════════
  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;

    environmentFile = "/etc/nixos/private/alertmanager.env";

    configuration = {
      global = {
        smtp_smarthost = "smtp.fastmail.com:587";
        smtp_from = "$SMTP_USERNAME";
        smtp_auth_username = "$SMTP_USERNAME";
        smtp_auth_password = "$SMTP_PASSWORD";
        smtp_require_tls = true;
      };

      route = {
        receiver = "all-alerts";
        group_by = [ "alertname" "severity" ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
      };

      receivers = [
        {
          name = "all-alerts";
          webhook_configs = [
            {
              url = "http://localhost:2586/nixos";
              send_resolved = true;
            }
          ];
          email_configs = [
            {
              to = "$EMAIL_TO";
              headers = {
                Subject = "NixOS Server Alert";
              };
            }
          ];
        }
      ];
    };
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

      security = {
        admin_user = "admin";
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
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:3100";
        }
      ];
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # LOKI - LOG AGGREGATION
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
  # PROMTAIL - LOG SHIPPER
  # ═══════════════════════════════════════════════════════════════════════════
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

  # ═══════════════════════════════════════════════════════════════════════════
  # NTFY - SELF-HOSTED NOTIFICATION SERVICE
  # ═══════════════════════════════════════════════════════════════════════════
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://ntfy.home";
      listen-http = "0.0.0.0:2586";
      cache-file = "/var/lib/ntfy-sh/cache.db";
      cache-duration = "24h";
      keepalive-interval = "45s";
      auth-default-access = "read-write";
      behind-proxy = true;
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # NOTEDISCOVERY - WEB-BASED KNOWLEDGE BASE
  # ═══════════════════════════════════════════════════════════════════════════

  # One-time setup service - clones repo and installs dependencies
  systemd.services.notediscovery-setup = {
    description = "NoteDiscovery One-Time Setup";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "notediscovery";
      Group = "notediscovery";
    };

    path = with pkgs; [ git python3 ];

    script = ''
      if [ ! -d /var/lib/notediscovery/.git ]; then
        echo "Cloning NoteDiscovery..."
        ${pkgs.git}/bin/git clone https://github.com/gamosoft/NoteDiscovery.git /var/lib/notediscovery
      fi

      if [ ! -d /var/lib/notediscovery/venv ]; then
        echo "Creating Python virtual environment..."
        ${pkgs.python3}/bin/python3 -m venv /var/lib/notediscovery/venv
        /var/lib/notediscovery/venv/bin/pip install -r /var/lib/notediscovery/requirements.txt
      fi
    '';
  };

  # Main NoteDiscovery service
  systemd.services.notediscovery = {
    description = "NoteDiscovery Knowledge Base";
    after = [ "network.target" "syncthing.service" "notediscovery-setup.service" ];
    requires = [ "notediscovery-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "notediscovery";
      Group = "notediscovery";
      WorkingDirectory = "/var/lib/notediscovery";
      ExecStart = "/var/lib/notediscovery/venv/bin/python3 /var/lib/notediscovery/run.py";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/var/lib/notediscovery"
        (import /etc/nixos/private/notediscovery-config.nix).notesPath
      ];
    };

    environment = {
      PYTHONUNBUFFERED = "1";
      CONFIG_PATH = "/etc/nixos/private/notediscovery-config.yaml";
      PORT = "5000";
    };
  };

  # Create the notediscovery user and set proper directory permissions
  users.users.notediscovery = {
    isSystemUser = true;
    group = "notediscovery";
    home = "/var/lib/notediscovery";
    createHome = true;
  };

  users.groups.notediscovery = {};

  # Ensure proper permissions on the directory
  systemd.tmpfiles.rules = [
    "d /var/lib/notediscovery 0755 notediscovery notediscovery -"
  ];
}

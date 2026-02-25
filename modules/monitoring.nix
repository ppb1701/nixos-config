{ config, pkgs, lib, ... }:

let
  secrets = import /etc/nixos/private/secrets.nix;
  
  # Build rule groups conditionally
  systemAlertsRules = ''
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
  '' + lib.optionalString config.services.nginx.enable ''

    - alert: NginxHighErrorRate
      expr: rate(nginx_http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High Nginx 5xx error rate"
        description: "Nginx is returning too many 5xx errors."
  '';

  vaultwardenRules = lib.optionalString (config.services.vaultwarden.enable or false) ''
    - name: vaultwarden
      rules:
        - alert: VaultwardenDown
          expr: probe_success{instance="https://${secrets.tailscaleHostname}"} == 0
          for: 20m
          labels:
            severity: critical
          annotations:
            summary: "Vaultwarden password manager is down"
            description: "Vaultwarden has been unreachable for 20 minutes"
  '';

  nextcloudRules = lib.optionalString config.services.nextcloud.enable ''
    - name: nextcloud
      rules:
        - alert: NextcloudDown
          expr: probe_success{job="nextcloud-http"} == 0
          for: 20m
          labels:
            severity: critical
          annotations:
            summary: "Nextcloud is unreachable"
            description: "Nextcloud HTTP check has failed for 15 minutes"

        - alert: NextcloudDiskSpaceLow
          expr: (nextcloud_system_disk_free_bytes / nextcloud_system_disk_total_bytes) < 0.1
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Nextcloud disk space low"
            description: "Less than 10% free space on Nextcloud data drive"
  '';

in
{
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

      nginx = lib.mkIf config.services.nginx.enable {
        enable = true;
        port = 9113;
        scrapeUri = "http://127.0.0.1:8080/nginx_status";
      };

      nextcloud = lib.mkIf config.services.nextcloud.enable {
        enable = true;
        url = "http://nextcloud.home:8280";
        username = "root";
        passwordFile = "/etc/nixos/private/nextcloud-admin-pass";
        port = 9205;
      };

      blackbox = {
        enable = true;
        port = 9115;
        configFile = pkgs.writeText "blackbox.yml" ''
          modules:
            http_2xx:
              prober: http
              timeout: 10s
              http:
                valid_status_codes: [200]
                method: GET
                follow_redirects: true
                preferred_ip_protocol: "ip4"
                ip_protocol_fallback: false
        '';
      };
    };

    scrapeConfigs =
      # Core monitoring (always on)
      [
        {
          job_name = "node";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
        {
          job_name = "prometheus";
          static_configs = [{
            targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
          }];
        }
      ]
      # Optional: SearxNG
      ++ lib.optionals (config.services.searx.enable or false) [{
        job_name = "searx";
        static_configs = [{
          targets = [ "localhost:8888" ];
        }];
      }]
      # Optional: Nginx
      ++ lib.optionals config.services.nginx.enable [{
        job_name = "nginx";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" ];
        }];
      }]
      # Optional: Nextcloud
      ++ lib.optionals config.services.nextcloud.enable [
        {
          job_name = "nextcloud";
          static_configs = [{
            targets = [ "localhost:9205" ];
          }];
        }
        {
          job_name = "nextcloud-http";
          scrape_interval = "30s";
          metrics_path = "/probe";
          params.module = [ "http_2xx" ];
          static_configs = [{
            targets = [ "http://${secrets.tailscaleIP}:8280" ];
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
      ]
      # Optional: Syncthing
      ++ lib.optionals config.services.syncthing.enable [{
        job_name = "syncthing";
        metrics_path = "/metrics";
        static_configs = [{
          targets = [ "127.0.0.1:8384" ];
        }];
        basic_auth = (import /etc/nixos/private/syncthing-secrets.nix).prometheus_auth;
      }]
      # Blackbox probes - conditionally add targets
      ++ [{
        job_name = "blackbox";
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        static_configs = [{
          targets = lib.flatten [
            (lib.optional (config.services.syncthing.enable) "http://127.0.0.1:8384")
            (lib.optional (config.services.adguardhome.enable or false) "http://127.0.0.1:3000")
            (lib.optional (config.services.vaultwarden.enable or false) "https://${secrets.tailscaleHostname}")
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
      }];

    # Alert Rules
    rules = [
      ''
        groups:
          - name: system_alerts
            interval: 30s
            rules:
      ${systemAlertsRules}
      ${vaultwardenRules}
      ${nextcloudRules}
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
        secret_key = (import /etc/nixos/private/secrets.nix).grafanaSecretKey;
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
}

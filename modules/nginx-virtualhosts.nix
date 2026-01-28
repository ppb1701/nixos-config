{ config, pkgs, ... }:

{
  services.nginx.virtualHosts = {
      "search.home" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8888";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };

      "links.home" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8230";  # Linkwarden default port
        };
      };

      "cloud.home" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8280";
          proxyWebsockets = true;
        };
      };

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
}

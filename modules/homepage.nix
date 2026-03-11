{ config, pkgs, lib, ... }:

let
  secrets = import /etc/nixos/private/secrets.nix;
in
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8582;
    allowedHosts = "home.home";

    settings = {
      title = "Home (NixOS)";
      theme = "dark";
      color = "zinc";
      layout = {
        "Network" = { style = "row"; columns = 2; };
        "Services" = { style = "row"; columns = 3; };
        "Monitoring" = { style = "row"; columns = 3; };
      };
    };

    bookmarks = [];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = [
            "/"
            "/mnt/nextcloud-data"
          ];
        };
      }
      {
        datetime = {
          text_size = "xl";
          format = {
            timeStyle = "short";
            dateStyle = "short";
          };
        };
      }
    ];

    services = [
      {
        "Network" = lib.flatten (
          (lib.optionals config.services.adguardhome.enable [
            {
              "AdGuard Home" = {
                description = "Network-wide ad blocking";
                href = "http://adguard.home";
                icon = "adguard-home";
                ping = "http://127.0.0.1:3000";
              };
            }
          ]) ++
          (lib.optionals config.services.tailscale.enable [
            {
              "Tailscale" = {
                description = "Mesh VPN";
                icon = "tailscale";
                href = "https://login.tailscale.com/admin";
                ping = "http://127.0.0.1:41112";
              };
            }
          ])
        );
      }
      {
        "Services" = lib.flatten (
          (lib.optionals config.services.syncthing.enable [
            {
              "Syncthing" = {
                description = "File sync";
                href = "http://syncthing.home";
                icon = "syncthing";
                ping = "http://127.0.0.1:8384";
              };
            }
          ]) ++
          (lib.optionals config.services.nextcloud.enable [
            {
              "Nextcloud" = {
                description = "Private cloud";
                href = "http://cloud.home";
                icon = "nextcloud";
                ping = "http://127.0.0.1:8280";
              };
            }
          ]) ++
          (lib.optionals config.services.vaultwarden.enable [
            {
              "Vaultwarden" = {
                description = "Password manager";
                href = "https://${secrets.tailscaleHostname}";
                icon = "vaultwarden";
                ping = "http://127.0.0.1:8222";
              };
            }
          ]) ++
          (lib.optionals (config.systemd.services ? linkwarden) [
            {
              "Linkwarden" = {
                description = "Bookmarks";
                href = "http://links.home";
                icon = "linkwarden";
                ping = "http://127.0.0.1:8230";
              };
            }
          ]) ++
          (lib.optionals config.services.searx.enable [
            {
              "SearX" = {
                description = "Private search";
                href = "http://search.home";
                icon = "searxng";
                ping = "http://127.0.0.1:8888";
              };
            }
          ]) ++
          (lib.optionals (config.systemd.services ? notediscovery) [
            {
              "NoteDiscovery" = {
                description = "Knowledge base";
                href = "http://notes.home";
                icon = "mdi-notebook";
                ping = "http://127.0.0.1:5000";
              };
            }
          ]) ++
          (lib.optionals config.services.gitea.enable [
            {
              "Gitea" = {
                description = "Git hosting";
                href = "http://git.home";
                icon = "gitea";
                ping = "http://127.0.0.1:3300";
              };
            }
          ])
        );
      }
      {
        "Monitoring" = lib.flatten (
          (lib.optionals config.services.grafana.enable [
            {
              "Grafana" = {
                description = "Dashboards";
                href = "http://grafana.home";
                icon = "grafana";
                ping = "http://127.0.0.1:3001";
              };
            }
          ]) ++
          (lib.optionals config.services.prometheus.enable [
            {
              "Prometheus" = {
                description = "Metrics";
                href = "http://prometheus.home";
                icon = "prometheus";
                ping = "http://127.0.0.1:9090";
              };
            }
          ]) ++
          (lib.optionals config.services.prometheus.alertmanager.enable [
            {
              "Alertmanager" = {
                description = "Alerts";
                href = "http://alertmanager.home";
                icon = "alertmanager";
                ping = "http://127.0.0.1:9093";
              };
            }
          ]) ++
          (lib.optionals config.services.ntfy-sh.enable [
            {
              "ntfy" = {
                description = "Push notifications";
                href = "http://ntfy.home";
                icon = "ntfy";
                ping = "http://127.0.0.1:2586";
              };
            }
          ]) ++
           (lib.optionals config.virtualisation.libvirtd.enable [
                      {
                        "ISO Builder VM" = {
                          description = "NixOS ISO build VM";
                          icon = "mdi-virtual-machine";
                          href = "http://nixos2.home:16509";
                          ping = "http://127.0.0.1:16509";
                        };
                      }
                    ]) ++
          (lib.optionals config.services.loki.enable [
            {
              "Loki" = {
                description = "Log aggregation";
                href = "http://grafana.home/explore";
                icon = "loki";
                ping = "http://127.0.0.1:3100";
              };
            }
          ])
        );
      }
    ];
  };
}

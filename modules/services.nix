{ config, lib, pkgs, ... }:
let
  secrets = import /etc/nixos/private/secrets.nix;
in
{
  imports = [
    ./nginx-virtualhosts.nix
  ];

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
  # LINKWARDEN - BOOKMARK MANAGER
  # ═══════════════════════════════════════════════════════════════════════════
  systemd.services.linkwarden = {
        description = "Linkwarden Bookmark Manager";
        after = [ "network.target" "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];
        
       environment = {
          DATABASE_URL = "postgresql://linkwarden:${secrets.linkwardenDbPassword}@localhost:5432/linkwarden";
          NEXTAUTH_URL = "http://links.home";
          NEXTAUTH_URL_INTERNAL = "http://localhost:8230";
          NEXTAUTH_SECRET = secrets.linkwardenNextAuthSecret;
          NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
          STORAGE_FOLDER = "/var/lib/linkwarden/data";
          LINKWARDEN_HOST = "0.0.0.0";
          LINKWARDEN_PORT = "8230";  # Change from PORT to LINKWARDEN_PORT
          NODE_ENV = "production";
        };
        
        serviceConfig = {
          Type = "simple";
          User = "linkwarden";
          Group = "linkwarden";
          WorkingDirectory = "/var/lib/linkwarden";
          ExecStart = "${pkgs.linkwarden}/bin/linkwarden";
          Restart = "on-failure";
          RestartSec = "10s";
          
          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [
              "/var/lib/linkwarden"
              "/var/cache/linkwarden"  
            ];
        };
      };
    
      # Create linkwarden user
      users.users.linkwarden = {
        isSystemUser = true;
        group = "linkwarden";
        home = "/var/lib/linkwarden";
        createHome = true;
      };
      
      users.groups.linkwarden = {};

      # PostgreSQL - needed by Linkwarden and potentially other services
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "linkwarden" ];
        ensureUsers = [{
          name = "linkwarden";
          ensureDBOwnership = true;
        }];
      };

   # ═══════════════════════════════════════════════════════════════════════════
  # GITEA - GIT HOSTING (PRIMARY INSTANCE)
  # ═══════════════════════════════════════════════════════════════════════════
  services.gitea = {
    enable = false;
    # Optional: Pin a specific version if you want stability
    # package = pkgs.gitea;

    database = {
      type = "sqlite3";
      path = "/var/lib/gitea/data/gitea.db";
    };

    settings = {
      server = {
        DOMAIN = "git.home";
        ROOT_URL = "http://git.home";
        HTTP_PORT = 3300; 
        HTTP_ADDR = "127.0.0.1"; 
      };
      security = {
        SECRET_KEY = lib.mkForce secrets.giteaSecret;
        INTERNAL_TOKEN = lib.mkForce secrets.giteaInternalToken;
      };
    
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
      };
    };
    

    # Optional: Pre-configure an admin user
    # lfs = {
    #   enable = true;
    # };
  };

  # Ensure Gitea user/group exists
  users.users.gitea = {
    isSystemUser = true;
    group = "gitea";
    home = "/var/lib/gitea";
    createHome = false; # systemd/tmpfiles handles this
  };
  users.groups.gitea = {};


  # ═══════════════════════════════════════════════════════════════════════════
  # SYNCTHING - FILE SYNCHRONIZATION
  # ═══════════════════════════════════════════════════════════════════════════
  services.syncthing = {
    enable = true;
    user = "ppb1701";
    dataDir = "/home/ppb1701";
    configDir = "/home/ppb1701/.config/syncthing";
    group = "syncthing";

    guiAddress = "0.0.0.0:8384";

    overrideDevices = true;
    overrideFolders = true;

    settings = import /etc/nixos/private/syncthing-devices.nix;
    
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # TAILSCALE - ZERO-CONFIG MESH VPN
  # ═══════════════════════════════════════════════════════════════════════════
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-routes=192.168.50.0/24" ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # VAULTWARDEN (Password Manager)
  # ═══════════════════════════════════════════════════════════════════════════
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/local/vaultwarden/backup";
  
    config = {
      ROCKET_ADDRESS = "127.0.0.1";  # Only listen locally
      ROCKET_PORT = 8222;
  
      # We'll set this after we get your Tailscale hostname
      DOMAIN = "https://${secrets.tailscaleHostname}";  # Reference from secrets
  
      # Allow signups initially so you can create your account
      SIGNUPS_ALLOWED = false;
  
      # Disable invitations for now (can enable later if needed)
      INVITATIONS_ALLOWED = false;
    };
  
    # Admin token and other secrets
    environmentFile = "/etc/nixos/private/vaultwarden.env";
  };
 
    # ═══════════════════════════════════════════════════════════════════════════
    # SearX - Self-Hosted Search
    # ═══════════════════════════════════════════════════════════════════════════
    services.searx = {
      enable = true;
  
      settings = {
        general = {
          instance_name = "ppb1701 Search";
          contact_url = false;
        };
  
        server = {
          port = 8888;
          bind_address = "0.0.0.0";
          secret_key = secrets.searxSecret;
          #base_url = "http://search.home";
          image_proxy = true;
        };
  
        search = {
          safe_search = 0;
          autocomplete = "google";
          default_lang = "en";
        };
  
        ui = {
          infinite_scroll = true;
          theme_args.simple_style = "dark";
		};
      };
    }; 
   
  
  # ═══════════════════════════════════════════════════════════════════════════
  # NEXTCLOUD - PRIVATE CLOUD
  # ═══════════════════════════════════════════════════════════════════════════
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "nextcloud.home";

    maxUploadSize = "70G";
    
      phpOptions = {
            upload_max_filesize = lib.mkForce "70G";
            post_max_size = lib.mkForce "0";
            memory_limit = lib.mkForce "2G";  # Use mkForce to override the default
            max_execution_time = lib.mkForce "3600";
            output_buffering = lib.mkForce "0";
          };
      
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = "/etc/nixos/private/nextcloud-admin-pass";
    };

    datadir = "/mnt/nextcloud-data";
    https = false;

    settings = {
      "auth.bruteforce.protection.enabled" = false;
      "ratelimit.protection.enabled" = false;
      "overwriteprotocol" = "http";
      trusted_domains = [        
        "localhost"
        "cloud.home"
      ];
      trusted_proxies = [
        "100.64.0.0/10"
      ];
      "log_type" = "file";
      "logfile" = "/mnt/nextcloud-data/data/nextcloud.log";
      "loglevel" = 2;
    };

    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";
  };

  # Configure Nextcloud to use port 8280 to avoid conflict with AdGuard Home
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
  
    #virtualhosts defined in ngix-virtualhosts.nix
    
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
      SupplementaryGroups = [ "syncthing" ];
      UMask = "0002";  # Creates files with group write by default
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
    extraGroups = [ "syncthing" "users" ];
    home = "/var/lib/notediscovery";
    createHome = true;
  };

  users.groups.notediscovery = {};

  # Ensure proper permissions on the directory
  systemd.tmpfiles.rules = [
    "d /var/lib/notediscovery 0755 notediscovery notediscovery -"
  ];

  
  # Fix Blog subdirectories after NoteDiscovery starts
  systemd.services.fix-blog-permissions = {
    description = "Fix Blog directory permissions for Syncthing";
    after = [ "notediscovery.service" ];
    wantedBy = [ "multi-user.target" ];
  
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  
    script = ''
      # Recursively fix ownership and permissions
      ${pkgs.coreutils}/bin/chown -R ppb1701:syncthing /var/lib/obsidian/ppb/Blog
      ${pkgs.coreutils}/bin/chmod -R u+rwX,g+rwX /var/lib/obsidian/ppb/Blog
      ${pkgs.findutils}/bin/find /var/lib/obsidian/ppb/Blog -type d -exec chmod g+s {} \;
    '';
  };
}

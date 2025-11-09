{ config, pkgs, ... }:

{
  # Install RustDesk
  environment.systemPackages = with pkgs; [
    rustdesk
  ];

  # RustDesk service for headless operation
  systemd.services.rustdesk = {
    description = "RustDesk Remote Desktop Service";
    after = [ "network-online.target" "display-manager.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk}/bin/rustdesk --service";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "ppb1701";
      Environment = "DISPLAY=:0";
    };
  };

  # Prevent system sleep (important for headless server)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}

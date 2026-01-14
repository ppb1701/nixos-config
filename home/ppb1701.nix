{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  # ═══════════════════════════════════════════════════════════════════════════
  # STARSHIP PROMPT - Capy-UI Inspired Theme
  # ═══════════════════════════════════════════════════════════════════════════
  programs.starship = {
    enable = true;
    settings = {
      # Electric Blue (#1e80c7) + Onyx Black terminal background

      directory = {
        style = "bold #1e80c7";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bold #1e80c7";
      };

      git_status = {
        style = "#4A9EFF";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };

      package = {
        style = "bold #1e80c7";
      };

      character = {
        success_symbol = "[❯](bold #1e80c7)";
        error_symbol = "[❯](bold #FF6B6B)";
      };

      dart = {
        style = "bold #1e80c7";
      };

      nodejs = {
        style = "bold #1e80c7";
      };

      ruby = {
        style = "bold #1e80c7";
      };

      cmd_duration = {
        style = "dimmed #4A9EFF";
      };

      aws.symbol = "  ";
      buf.symbol = " ";
      bun.symbol = " ";
      c.symbol = " ";
      cpp.symbol = " ";
      cmake.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      deno.symbol = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fossil_branch.symbol = " ";
      gcloud.symbol = "  ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      ocaml.symbol = " ";

      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CachyOS = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        Nobara = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };

      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      pixi.symbol = "󰏗 ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      swift.symbol = " ";
      zig.symbol = " ";
      gradle.symbol = " ";
    };
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # ZSH CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

 shellAliases = {
   # Help - List all custom aliases
   help = ''
     echo "
╔════════════════════════════════════════════════════════════╗
║                    NIXOS CUSTOM ALIASES                    ║
╠════════════════════════════════════════════════════════════╣
║ SYSTEM MANAGEMENT:                                         ║
║   rebuild    - Rebuild and switch to new config            ║
║   test       - Test new config without switching           ║
║   rollback   - Rollback to previous generation             ║
║   update     - Update system and rebuild                   ║
║   cleanup    - Clean old generations                       ║
║   optimize    - Deduplicate store                          ║
╠════════════════════════════════════════════════════════════╣
║ CONFIG EDITING:                                            ║
║   ec         - Edit configuration.nix                      ║
║   eh         - Edit home/ppb1701.nix                       ║
║   en         - Edit modules/networking.nix                 ║
║   es         - Edit modules/services.nix                   ║
║   esy        - Edit modules/system.nix                     ║
║   em         - Edit modules/monitoring.nix                 ║
║   ebios      - Edit modules/boot-bios.nix                  ║
║   euefi      - Edit modules/boot-uefi.nix                  ║
║   ep         - Edit private/ssh-keys.nix                   ║
║   escrt      - Edit private/secrets.nix                    ║
║   ea         - Edit private/alertmanager.env               ║
║   eny        - Edit private/notediscovery-config.yaml      ║
║   enx        - Edit private/notediscovery-config.nix       ║
╠════════════════════════════════════════════════════════════╣
║ GIT OPERATIONS:                                            ║
║   gc         - Git commit (add all & commit)               ║
║   gp         - Git push                                    ║
║   gl         - Git pull                                    ║
║   gs         - Git status                                  ║
╠════════════════════════════════════════════════════════════╣
║ SERVICE MANAGEMENT:                                        ║
║   ags/agr/agl - AdGuard status/restart/logs                ║
║   sts/str/stl - Syncthing status/restart/logs              ║
║   sss/ssr     - SSH status/restart                         ║
╠════════════════════════════════════════════════════════════╣
║ SYSTEM INFO:                                               ║
║   sysinfo    - System information (neofetch)               ║
║   diskspace  - Disk usage                                  ║
║   meminfo    - Memory usage                                ║
║   cpuinfo    - CPU information                             ║
║   myip       - Public IP address                           ║
║   localip    - Local IP address                            ║
║   ports      - Open ports                                  ║
╚════════════════════════════════════════════════════════════╝
"
   '';

   # System management (with auto-reload!)
   rebuild = "nh os switch -f '<nixpkgs/nixos>' -- -I nixos-config=/etc/nixos/configuration.nix && exec zsh";
   rebuild-boot = "nh os boot -f '<nixpkgs/nixos>' -- -I nixos-config=/etc/nixos/configuration.nix && exec zsh";
   test = "nh os test -f '<nixpkgs/nixos>' -- -I nixos-config=/etc/nixos/configuration.nix && exec zsh";
   rollback = "sudo nixos-rebuild switch --rollback && exec zsh";
   update = "sudo nixos-rebuild switch --upgrade && exec zsh";
   cleanup = "nh clean -v all --keep 3";
   optimize = "sudo nix-store --optimize";

   # Config editing
   ec = "sudo micro /etc/nixos/configuration.nix";
   eh = "sudo micro /etc/nixos/home/ppb1701.nix";
   en = "sudo micro /etc/nixos/modules/networking.nix";
   em = "sudo micro /etc/nixos/modules/monitoring.nix";
   es = "sudo micro /etc/nixos/modules/services.nix";
   esy = "sudo micro /etc/nixos/modules/system.nix";
   ep = "sudo micro /etc/nixos/private/ssh-keys.nix";
   escrt = "sudo micro /etc/nixos/private/secrets.nix";
   eu = "sudo micro /etc/nixos/configuration-uefi.nix";
   eb = "sudo micro /etc/nixos/configuration-bios.nix";
   ebios = "sudo micro /etc/nixos/modules/boot-bios.nix";
   euefi = "sudo micro /etc/nixos/modules/boot-uefi.nix";
   ea ="sudo micro /etc/nixos/private/alertmanager.env";
   eny ="sudo micro /etc/nixos/private/notediscovery-config.yaml";
   enx ="sudo micro /etc/nixos/private/notediscovery-config.nix";

   # Git operations
   gc = "cd /etc/nixos && sudo git add . && sudo git commit";
   gp = "cd /etc/nixos && sudo git push";
   gl = "cd /etc/nixos && sudo git pull";
   gs = "cd /etc/nixos && sudo git status";

   # Service management
   ags = "sudo systemctl status adguardhome";
   agr = "sudo systemctl restart adguardhome";
   agl = "sudo journalctl -u adguardhome -f";
   sts = "sudo systemctl status syncthing@ppb1701";
   str = "sudo systemctl restart syncthing@ppb1701";
   stl = "sudo journalctl -u syncthing@ppb1701 -f";
   sss = "sudo systemctl status sshd";
   ssr = "sudo systemctl restart sshd";

   # System info
   sysinfo = "neofetch";
   diskspace = "df -h";
   meminfo = "free -h";
   cpuinfo = "lscpu";
   myip = "curl -s ifconfig.me";
   localip = "ip -4 addr show enp1s0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'";
   ports = "sudo ss -tulpn";

   # Utilities
   ll = "ls -lah";
   la = "ls -A";
   l = "ls -CF";
   c = "clear";
   h = "history";
   q = "exit";
 };

  

    initContent = ''
      # Starship prompt initialization
      eval "$(starship init zsh)"
    '';
  };
}

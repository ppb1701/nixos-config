{ pkgs, ... }:

{
  home.stateVersion = "25.05";

  # ═══════════════════════════════════════════════════════════════════════════
  # STARSHIP PROMPT - Electric Blue Theme
  # ═══════════════════════════════════════════════════════════════════════════
  programs.starship = {
    enable = true;
    settings = {
      # Capy-UI Inspired Starship Theme
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
  };  # ← SEMICOLON HERE

  # ═══════════════════════════════════════════════════════════════════════════
  # ZSH CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -lAh";
  	  update = "sudo nixos-rebuild switch";
  	  ec = "sudo micro /etc/nixos/configuration.nix";
  	  eb = "sudo micro /etc/nixos/configuration-bios.nix";
  	  eu = "sudo micro /etc/nixos/configuration-uefi.nix";
      eh = "sudo micro /etc/nixos/home.nix";
  	  ea = "sudo micro /etc/nixos/modules/adguard-home.nix";
  	  en = "sudo micro /etc/nixos/modules/networking.nix";
  	  es = "sudo micro /etc/nixos/modules/syncthing.nix";
    };

    initContent = ''
      # Starship prompt initialization
      eval "$(starship init zsh)"
    '';
  };  # ← SEMICOLON HERE
}

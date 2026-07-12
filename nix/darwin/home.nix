{
  lcars,
  lib,
  pkgs,
  profile,
  ...
}:

let
  fishModule = ../modules/home/fish.nix;

  resolverLib = import ../lib/resolve-module.nix { };
  inherit (resolverLib) resolveModule;

  aerospaceModule = resolveModule {
    inherit profile;
    base = ../modules/home/aerospace;
    ext = "";
  };
  tunaModule = resolveModule {
    inherit profile;
    base = ../modules/home/tuna;
    ext = "";
  };

  fishBindingsPath = resolveModule {
    inherit profile;
    base = ../modules/home/fish;
    ext = ".bindings";
    sep = "-";
  };
  hasFishBindings = builtins.pathExists fishBindingsPath;
in
{
  imports = [
    ../modules/home/ghostty.nix
    ../modules/home/neovim.nix
    ../modules/home/oh_my_posh.nix
    ../modules/home/zellij.nix
    # ../modules/home/leader_key.nix
    tunaModule
    ../modules/home/helix.nix
    ../modules/home/helix.scripts-manager.nix
    aerospaceModule
    ../modules/home/rtk.nix
    #../modules/home/darwin # this can be for aerospace
  ]
  ++ (lib.optional lcars.shell.fish.enable fishModule)
  ++ (lib.optional (lcars.shell.fish.enable && hasFishBindings) {
    # Per-profile fish shellInit additions (aliases, corporate proxy
    # settings, etc.). `interactiveShellInit` is a `types.lines` option, so
    # this module's definition is automatically concatenated with the base
    # definition set in fish.nix — no `lib.mkMerge` plumbing required here.
    programs.fish.interactiveShellInit = import fishBindingsPath;
  });
  home.stateVersion = "25.05"; # Please read the comment before changing.
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    #android-tools
    #python3
    pyenv
    #fd
    #tldr
    # TODO:More nvim
    nixd
    nixfmt
    deadnix
    statix
    #wget
    #$imagemagickBig
    # /nvim
    #unstable.kitty
    obsidian

    # For rust
    rustup # Rust toolchain installer
    ripgrep
    fd

    # /Terminal tools
    # Coding tools
    unstable.devenv
  ];

  # I prefer the default: vim
  # home.sessionVariables = { EDITOR = "nvim"; };

  # Setup programs options
  programs = {
    bash = {
      enable = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    eza = {
      enable = true;
      colors = "auto";
      git = true;
      icons = "auto";
    };
    git = {
      enable = true;
      signing.format = null;
      settings = {
        difftool = {
          prompt = false;
        };
        pager = {
          difftool = true;
        };
        user = {
          name = "Adiel Hercules";
          email = "me@adielhercules.com";
        };
        "init" = {
          "defaultBranch" = "main";
        };
      };
    };
    difftastic = {
      enable = true;
      package = pkgs.unstable.difftastic;
      git = {
        diffToolMode = true;
      };
      options = {
        display = "inline";
      };
    };
    # zsh = {
    #   enable = true;
    #   autocd = true;
    #   enableCompletion = true;
    #   history = {
    #     ignoreDups = true;
    #     ignoreSpace = true;
    #   };
    #   #oh-my-zsh = {
    #   #  enable = true;
    #   #  plugins = [ "git" ];
    #   #};
    #   syntaxHighlighting = {
    #     enable = true;
    #     highlighters = [ "brackets" ];
    #   };
    # };
    fzf = {
      enable = true;
    };
    ripgrep = {
      enable = true;
    };
    zoxide = {
      enable = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Suppress GTK4 theme migration warning (macOS-only setup, no GTK apps)
  gtk.gtk4.theme = null;
}

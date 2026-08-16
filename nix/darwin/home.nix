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

  # Both git-personal.nix and git-work.nix always exist, so this always
  # resolves to the profile-specific file (no shared fallback needed).
  gitProfileModule = resolveModule {
    inherit profile;
    base = ../modules/home/git;
    sep = "-";
  };
in
{
  imports = [
    ../modules/home/ghostty.nix
    ../modules/home/oh-my-posh.nix
    ../modules/home/zellij.nix
    ../modules/home/sketchybar
    tunaModule
    ../modules/home/helix.nix
    ../modules/home/helix.scripts-manager.nix
    aerospaceModule
    ../modules/home/rtk.nix
    ../modules/home/opencode
    ../modules/home/opencode2.nix
    ../modules/home/headroom.nix
    gitProfileModule
  ]
  ++ (lib.optional lcars.shell.fish.enable fishModule)
  ++ (lib.optional (lcars.shell.fish.enable && hasFishBindings) {
    # Per-profile fish shellInit additions (aliases, corporate proxy
    # settings, etc.). `interactiveShellInit` is a `types.lines` option, so
    # this module's definition is automatically concatenated with the base
    # definition set in fish.nix — no `lib.mkMerge` plumbing required here.
    programs.fish.interactiveShellInit = import fishBindingsPath;
  });
  # home-manager stateVersion. Change only when upgrading nixpkgs major
  # releases (24.05 -> 25.05, etc.). See:
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home = {
    stateVersion = "25.05";
    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      pyenv
      fd
      tldr
      nixd
      nixfmt
      deadnix
      statix
      obsidian

      # For rust
      rustup # Rust toolchain installer
      ripgrep

      # /Terminal tools
    ];

    # Force-overwrite .bashrc/.profile: on machines migrated from a manual
    # (pre-Nix) dotfiles setup, these paths may already be symlinks pointing
    # elsewhere. Home Manager's backupFileExtension mechanism does not
    # reliably back up existing symlinks (unlike regular files, e.g.
    # .bash_profile), so activation fails with "would be clobbered" unless
    # force is set explicitly for these two.
    file.".bashrc".force = true;
    file.".profile".force = true;
  };

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
      includes = [ { path = "~/.config/git/config.local"; } ];
      settings = {
        difftool = {
          prompt = false;
        };
        pager = {
          difftool = true;
        };
        "init" = {
          "defaultBranch" = "main";
        };
      };
    };
    difftastic = {
      enable = true;
      # pkgs.unstable: difftastic ships frequent language-grammar/diff
      # rendering improvements upstream; pinned to unstable to stay closer
      # to that cadence rather than the slower-moving 26.05 stable channel.
      package = pkgs.unstable.difftastic;
      git = {
        diffToolMode = true;
      };
      options = {
        display = "inline";
      };
    };
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

  # This is a Darwin-only config with no GTK applications, and as of
  # stylix's release-26.05 branch, its GTK home-manager target
  # unconditionally sets `gtk.gtk4.theme`, which previously conflicted
  # with a workaround for a theme migration warning. Disabling the target
  # entirely (rather than fighting it with an override) avoids both the
  # conflict and any unnecessary GTK theming machinery. This option only
  # exists at the home-manager level (GTK has no nix-darwin module), so it
  # must be set here rather than in the darwin-level `stylix` block in
  # nix/darwin/default.nix.
  stylix.targets.gtk.enable = false;
}

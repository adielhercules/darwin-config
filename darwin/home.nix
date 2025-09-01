{ lcars, lib, pkgs, ... }:

let fishModule = ../modules/home/fish.nix;
in {
  imports = [
    ../modules/home/ghostty.nix
    ../modules/home/neovim.nix
    ../modules/home/oh_my_posh.nix
    ../modules/home/zellij.nix
    ../modules/home/leader_key.nix
    #../modules/home/darwin # this can be for aerospace
  ] ++ (lib.optional lcars.shell.fish.enable fishModule);
  home.stateVersion = "24.11"; # Please read the comment before changing.
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
    nixfmt-classic
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
  ];

  # I prefer the default: vim
  # home.sessionVariables = { EDITOR = "nvim"; };

  # Setup programs options
  programs = {
    bash = { enable = true; };
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
      userName = "Adiel Hercules";
      userEmail = "me@adielhercules.com";
      difftastic = {
        enable = true;
        enableAsDifftool = true;
        display = "inline";
        package = pkgs.unstable.difftastic;
      };
      extraConfig = {
        difftool = { prompt = false; };
        pager = { difftool = true; };
      };
    };
    zsh = {
      enable = true;
      autocd = true;
      enableCompletion = true;
      history = {
        ignoreDups = true;
        ignoreSpace = true;
      };
      #oh-my-zsh = {
      #  enable = true;
      #  plugins = [ "git" ];
      #};
      syntaxHighlighting = {
        enable = true;
        highlighters = [ "brackets" ];
      };
    };
    fzf = { enable = true; };
    ripgrep = { enable = true; };
    zoxide = { enable = true; };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

{ config, lib, files, pkgs, ... }:

{

  home.sessionVariables = { EDITOR = "nvim"; };
  home.packages = with pkgs; [
    unstable.neovim
    nixd
    nixfmt-classic
    deadnix
    statix
    nodejs_22
    (lua5_1.withPackages (ps: with ps; [ luarocks ]))
  ];

  xdg.configFile = {
    "nvim" = { source = config.lib.file.mkOutOfStoreSymlink "${files}/nvim.astro-v5"; };
  };
}


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
    "nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${files}/nvim.astro-v5";
    };
  };
  home.activation.nvim = with config.lib.stylix.colors.withHashtag;
    let
      theme = ''
        --DO NOT EDIT. Auto generated from current stylix theme during deploy
        require('mini.base16').setup({
          use_cterm = true,
          palette = {
            base00 = '${base00}',
            base01 = '${base01}',
            base02 = '${base02}',
            base03 = '${base03}',
            base04 = '${base04}',
            base05 = '${base05}',
            base06 = '${base06}',
            base07 = '${base07}',
            base08 = '${base08}',
            base09 = '${base09}',
            base0A = '${base0A}',
            base0B = '${base0B}',
            base0C = '${base0C}',
            base0D = '${base0D}',
            base0E = '${base09}',
            base0F = '${base0F}'
          }
        })

        -- Set overrides for hl groups
        -- Using the command for this one, so we can just change the existing one, instead of replacing it
        vim.cmd \"highlight NeogitDiffDeleteCursor guifg='${base08}' gui=bold\"

        -- Set transparent background to window
        vim.api.nvim_create_autocmd(\"ColorScheme\", {
          pattern = \"*\",
          callback = function()
           vim.cmd [[
              highlight Normal guibg=NONE ctermbg=NONE
              highlight NormalNC guibg=NONE ctermbg=NONE
              highlight NonText guibg=NONE ctermbg=NONE
              highlight SignColumn guibg=NONE ctermbg=NONE
              highlight VertSplit guibg=NONE ctermbg=NONE
              highlight StatusLine guibg=NONE ctermbg=NONE
              highlight StatusLineNC guibg=NONE ctermbg=NONE
              highlight LineNr guibg=NONE ctermbg=NONE
              highlight LineNrAbove guibg=NONE ctermbg=NONE
              highlight LineNrBelow guibg=NONE ctermbg=NONE
              highlight Folded guibg=NONE ctermbg=NONE
              highlight FoldColumn guibg=NONE ctermbg=NONE
              highlight TabLine guibg=NONE ctermbg=NONE
              highlight TabLineFill guibg=NONE ctermbg=NONE
              highlight TabLineSel guibg=NONE ctermbg=NONE
              highlight EndOfBuffer guibg=NONE ctermbg=NONE
              highlight MsgArea guibg=NONE ctermbg=NONE
              highlight Pmenu guibg=NONE ctermbg=NONE
              highlight PmenuSel guibg=NONE ctermbg=NONE
              highlight PmenuSbar guibg=NONE ctermbg=NONE
              highlight PmenuThumb guibg=NONE ctermbg=NONE
            ]]
          end
        })
      '';
    in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run echo "${theme}" > "${config.home.homeDirectory}/.config/nvim/colors/stylix.lua"
    '';
}

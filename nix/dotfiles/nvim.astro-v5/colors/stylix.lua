--DO NOT EDIT. Auto generated from current stylix theme during deploy
require('mini.base16').setup({
  use_cterm = true,
  palette = {
    base00 = '#0e121b',
    base01 = '#232a3b',
    base02 = '#203554',
    base03 = '#a2a2b9',
    base04 = '#848ab9',
    base05 = '#ccdeff',
    base06 = '#f5f6fa',
    base07 = '#88bbff',
    base08 = '#ff2200',
    base09 = '#ff8800',
    base0A = '#ffaa00',
    base0B = '#00b844',
    base0C = '#88ccff',
    base0D = '#2255ff',
    base0E = '#ff8800',
    base0F = '#cc2233'
  }
})

-- Set overrides for hl groups
-- Using the command for this one, so we can just change the existing one, instead of replacing it
vim.cmd "highlight NeogitDiffDeleteCursor guifg='#ff2200' gui=bold"

-- Set transparent background to window
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
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


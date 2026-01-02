-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.typescript" },
  -- Coding
  { import = "astrocommunity.recipes.ai" },
  { import = "astrocommunity.lsp.inc-rename-nvim" },
  { import = "astrocommunity.search.nvim-spectre" },
  { import = "astrocommunity.recipes.diagnostic-virtual-lines-current-line" },
  -- Motion
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.motion.harpoon" },
  -- Git
  -- { import = "astrocommunity.git.blame-nvim" },
  -- { import = "astrocommunity.git.git-blame-nvim" },
  -- Colorschemes
  { import = "astrocommunity.color.transparent-nvim" },
  { import = "astrocommunity.color.modes-nvim" },
  { import = "astrocommunity.recipes.cache-colorscheme" },
  -- Other
  { import = "astrocommunity.editing-support.undotree" },
  { import = "astrocommunity.file-explorer.oil-nvim" },
  -- { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.recipes.heirline-vscode-winbar" },
  { import = "astrocommunity.scrolling.mini-animate" },
}

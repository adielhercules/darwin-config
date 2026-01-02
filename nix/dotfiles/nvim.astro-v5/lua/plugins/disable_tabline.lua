-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Use this file to disable the tabline in AstroNvim.
-- I don't personally like the tabbar, however I do like the added functionality
-- to move between buffers as they act as tabs, hence I want the functionality
-- to still be there; I hide the tabline but keep the functionality.
return {
  {
    "AstroNvim/astrocore",
    ---@param opts AstroCoreOpts
    opts = function(_, opts)
      if vim.tbl_get(opts, "options", "opt", "showtabline") then opts.options.opt.showtabline = nil end
    end,
  },
}

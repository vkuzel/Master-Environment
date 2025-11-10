require("config.lazy")
require("config.keymaps")

-- show line numbers
vim.opt.number = true

-- Softwrap and visual guide for markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.textwidth = 0
    vim.opt_local.wrapmargin = 0
    vim.opt_local.colorcolumn = "120"
    vim.cmd [[highlight ColorColumn ctermbg=236 guibg=#2c2c2c]]
  end,
})


require("config.lazy")

-- show line numbers
vim.opt.number = true

-- Ctrl - delete word
vim.keymap.set("i", "<C-Backspace>", "<C-w>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-Del>", "X<Esc>lbce", { noremap = true, silent = true })

-- Ctrl + Shift + C/X/V - copy, paste, cut
vim.keymap.set({'n', 'v'}, '<C-S-c>', '"+y', {desc = 'Copy to system clipboard'})
vim.keymap.set('v', '<C-S-x>', '"+d', {desc = 'Cut to system clipboard'})
vim.keymap.set({'n', 'v'}, '<C-S-v>', '"+p', {desc = 'Paste from system clipboard'})
vim.keymap.set('i', '<C-S-v>', '<C-R>+', {desc = 'Paste from clipboard in insert mode'})
vim.keymap.set('c', '<C-S-v>', '<C-R>+', {desc = 'Paste from clipboard in command mode'})

-- Toggle vim tree
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true })

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


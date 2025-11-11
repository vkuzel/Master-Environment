-- Ctrl - delete word
vim.keymap.set("i", "<C-Backspace>", "<C-w>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-Del>", "X<Esc>lbce", { noremap = true, silent = true })

-- Ctrl + Shift + C/X/V - copy, paste, cut
vim.keymap.set({'n', 'v'}, '<C-S-c>', '"+y', {desc = 'Copy to system clipboard'})
vim.keymap.set('v', '<C-S-x>', '"+d', {desc = 'Cut to system clipboard'})
vim.keymap.set({'n', 'v'}, '<C-S-v>', '"+p', {desc = 'Paste from system clipboard'})
vim.keymap.set('i', '<C-S-v>', '<C-R>+', {desc = 'Paste from clipboard in insert mode'})
vim.keymap.set('c', '<C-S-v>', '<C-R>+', {desc = 'Paste from clipboard in command mode'})

-- Tab controls
vim.keymap.set({'n', 'v', 'i'}, '<C-t>', ':tabnew<CR>', { noremap = true, silent = true })
vim.keymap.set({'n', 'v', 'i'}, '<C-w>', ':close<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-S-PageUp>', ':-tabmove<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-S-PageDown>', ':+tabmove<CR>', { noremap = true, silent = true })

-- Toggle vim tree
vim.keymap.set('n', '<A-1>', ':NvimTreeToggle<CR>', { noremap = true, silent = true })


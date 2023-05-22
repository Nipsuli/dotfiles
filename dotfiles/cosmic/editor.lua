-- Override Cosmic editor options

--[[ local g = vim.g ]]
local map = require('cosmic.utils').map
--[[ local opt = vim.opt ]]
local api = vim.api

api.nvim_create_autocmd("TermOpen", { command = "setlocal nonumber norelativenumber"})
api.nvim_create_autocmd("TermOpen", { command = "resize 20"})
api.nvim_create_autocmd("TermOpen", { command = "startinsert"})
map('t', '<C-o>', '<C-\\><C-n>')
map('n', '<leader>ot', ':bo sp +te<cr>')

-- Default leader is <space>
-- g.mapleader = ','

-- Default indent = 2
-- opt.shiftwidth = 4
-- opt.softtabstop = 4
-- opt.tabstop = 4

-- Add additional keymaps or disable existing ones
-- To view maps set, use `:Telescope keymaps`
-- or `:map`, `:map <leader>`

-- Example: Additional insert mapping:
-- map('i', 'jj', '<esc>')
map('n', '<leader>w', ':w!')

-- Mapping options:
-- map('n', ...)
-- map('v', ...)
-- map('i', ...)
-- map('t', ...)

-- Example: Disable find files keymap
-- vim.keymap.del('n', '<leader>f')

-- See :h vim.keymap for more info

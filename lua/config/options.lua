-- Leader key.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable true color support
vim.opt.termguicolors = true

-- Turn on line number.
vim.opt.number = true
-- vim.opt.relativenumber = true

-- Enable mouse mode.
vim.opt.mouse = "a"

-- Sync with OS clipboard.
--  see `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"
vim.g.clipboard = 'osc52'

-- Save undo history.
vim.opt.undofile = true

-- Always show sign column.
vim.opt.signcolumn = "yes"

-- Highlight whitespace characters.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", }

-- Enable live preview of substitutions.
vim.opt.inccommand = "split"

-- Show the line where the cursor is on.
vim.opt.cursorline = true

-- Set highlight on search.
vim.opt.hlsearch = true

-- Enable line wrapping.
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.breakindentopt = 'shift:2,min:20' -- Shift 2 spaces, min 20 chars

-- Default formatting.
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.textwidth = 80

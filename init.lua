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

-- Set highlight on search, but clear on pressing <Esc> in normal mode.
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

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

-- Configure signs used for diagnostics.
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
  virtual_text = true, -- Show inline diagnostics
})

-- Default color scheme.
vim.cmd.colorscheme("catppuccin")

-- Enable treesitter for formatting and syntax highlighting.
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" }, { confirm = false })

require("nvim-treesitter.install").update("all")

require("nvim-treesitter.config").setup({
  auto_install = true, -- autoinstall languages that are not installed yet
})

-- Configure blink completion engine.
vim.pack.add({ "https://github.com/saghen/blink.cmp" }, { confirm = false })

require("blink.cmp").setup({
  completion = {
    documentation = {
      auto_show = true,
    },
  },

  keymap = {
    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

    ['<C-y>'] = { 'select_and_accept', 'fallback' },
    ['<C-e>'] = { 'cancel', 'fallback' },
    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },

    ['<Tab>'] = { 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  },

  fuzzy = {
    implementation = "lua",
  },
})

-- Telescope fuzzy finder.
vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",        -- Library dependency
  "https://github.com/nvim-tree/nvim-web-devicons",  -- Icons (nerd font)
  "https://github.com/nvim-telescope/telescope.nvim"
}, { confirm = false })

require("telescope").setup({})

local pickers = require("telescope.builtin")

vim.keymap.set("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers", })
vim.keymap.set("n", "<leader>sb", pickers.buffers, { desc = "[S]earch [B]uffers", })
vim.keymap.set("n", "<leader>sf", pickers.find_files, { desc = "[S]earch [F]iles", })
vim.keymap.set("n", "<leader>sw", pickers.grep_string, { desc = "[S]earch Current [W]ord", })
vim.keymap.set("n", "<leader>sg", pickers.live_grep, { desc = "[S]earch by [G]rep", })
vim.keymap.set("n", "<leader>sr", pickers.resume, { desc = "[S]earch [R]esume", })

vim.keymap.set("n", "<leader>sh", pickers.help_tags, { desc = "[S]earch [H]elp", })
vim.keymap.set("n", "<leader>sm", pickers.man_pages, { desc = "[S]earch [M]anuals", })

-- Keybinding helper.
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })

require("which-key").setup({
  spec = {
    { "<leader>s", group = "[S]earch", icon = { icon = "", color = "green", }, },
  }
})

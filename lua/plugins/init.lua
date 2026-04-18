-- Install all plugins in one vim.pack.add call so the dependency set is easy to audit.
vim.pack.add({
  "https://github.com/catppuccin/nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/saghen/blink.cmp",
  "https://github.com/nvim-lua/plenary.nvim",       -- Library dependency
  "https://github.com/nvim-tree/nvim-web-devicons", -- Icons (nerd font)
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/folke/which-key.nvim",
}, { confirm = false })

-- which-key first so other plugin modules can call which-key.add() for their group specs.
require("plugins.which-key")

require("plugins.colorscheme")
require("plugins.treesitter")
require("plugins.blink")
require("plugins.telescope")

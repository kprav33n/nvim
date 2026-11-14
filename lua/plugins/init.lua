-- Install all plugins in one vim.pack.add call so the dependency set is easy to audit.
vim.pack.add({
  "https://github.com/catppuccin/nvim",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/saghen/blink.cmp",
  "https://github.com/nvim-lua/plenary.nvim",       -- Library dependency
  "https://github.com/nvim-tree/nvim-web-devicons", -- Icons (nerd font)
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/NeogitOrg/neogit",
  "https://github.com/sindrets/diffview.nvim",       -- Git diff views (neogit dependency, optional)
  "https://github.com/lewis6991/gitsigns.nvim",      -- Git signs in the signcolumn
  "https://github.com/supermaven-inc/supermaven-nvim",
  "https://github.com/Huijiro/blink-cmp-supermaven",
  "https://github.com/MunifTanjim/nui.nvim",         -- UI components (neo-tree dependency)
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/nvim-lualine/lualine.nvim",
}, { confirm = false })

-- which-key first so other plugin modules can call which-key.add() for their group specs.
require("plugins.which-key")

require("plugins.colorscheme")
require("plugins.treesitter")
require("plugins.blink")
require("plugins.telescope")
require("plugins.git")
require("plugins.supermaven")
require("plugins.neo-tree")
require("plugins.tabs")
require("plugins.lualine")

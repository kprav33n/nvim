-- Enable treesitter for formatting and syntax highlighting.
require("nvim-treesitter.install").update("all")

require("nvim-treesitter.config").setup({
  auto_install = true, -- autoinstall languages that are not installed yet
})

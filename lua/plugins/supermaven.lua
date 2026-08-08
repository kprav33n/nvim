-- Supermaven AI code completion.
require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<C-l>",
    accept_word = "<C-j>",
    clear_suggestion = "<C-]>",
  },
})

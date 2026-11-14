-- Claude Code IDE integration.
require("claudecode").setup({
  terminal = {
    provider = "native", -- No snacks.nvim; plain :terminal split.
  },
})

-- Claude keymaps.
vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<CR>", { desc = "[A]I [C]laude Toggle" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<CR>", { desc = "[A]I [F]ocus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<CR>", { desc = "[A]I [R]esume Session" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<CR>", { desc = "[A]I [C]ontinue Last Session" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", { desc = "[A]I Select [M]odel" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", { desc = "[A]I Add [B]uffer" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<CR>", { desc = "[A]I [S]end Selection" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", { desc = "[A]I [A]ccept Diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", { desc = "[A]I [D]eny Diff" })

require("which-key").add({
  { "<leader>a", group = "[A]I", mode = { "n", "v" }, icon = { icon = "󰚩", color = "orange" } },
})

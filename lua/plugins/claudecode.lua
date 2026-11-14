-- Claude Code IDE integration.
require("claudecode").setup({
  terminal = {
    provider = "native", -- No snacks.nvim; plain :terminal split.
  },
  -- Review proposed edits side by side in their own tab, away from neo-tree,
  -- with focus left on Claude's prompt. :w accepts, :q rejects.
  diff_opts = {
    layout = "vertical",
    open_in_new_tab = true,
    keep_terminal_focus = true,
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

-- In neo-tree, add the file or directory under the cursor to Claude's context.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("claudecode_tree", { clear = true }),
  pattern = "neo-tree",
  callback = function(ev)
    vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<CR>", { buffer = ev.buf, desc = "[A]I [S]end File" })
  end,
})

require("which-key").add({
  { "<leader>a", group = "[A]I", mode = { "n", "v" }, icon = { icon = "󰚩", color = "orange" } },
})

-- Clear search highlight on Esc in normal mode; still send Esc so plugins see it.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>")

-- Quit and quit without saving.
vim.keymap.set("n", "<leader>x", "<cmd>qa<CR>", { desc = "E[x]it" })
vim.keymap.set("n", "<leader>X", "<cmd>qa!<CR>", { desc = "E[X]it without saving" })

-- Move between windows.
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })
vim.keymap.set("n", "<C-M-Left>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-M-Down>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-M-Up>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-M-Right>", "<C-w>l", { desc = "Window right" })

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Clear search highlight on Esc in normal mode.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Quit and quit without saving.
vim.keymap.set("n", "<leader>x", "<cmd>qa<CR>", { desc = "[E]xit" })
vim.keymap.set("n", "<leader>X", "<cmd>qa!<CR>", { desc = "[E]xit without saving" })

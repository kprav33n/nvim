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
-- Ctrl+Alt+arrows also work from terminal panes, which resume typing on return.
for key, dir in pairs({ Left = "h", Down = "j", Up = "k", Right = "l" }) do
  local lhs, desc = "<C-M-" .. key .. ">", "Window " .. key:lower()
  vim.keymap.set("n", lhs, "<C-w>" .. dir, { desc = desc })
  vim.keymap.set("t", lhs, function()
    local buf = vim.api.nvim_get_current_buf()
    vim.cmd.wincmd(dir)
    -- Only when the move left the terminal.
    vim.b[buf].resume_terminal = vim.api.nvim_get_current_buf() ~= buf or nil
  end, { desc = desc })
end
vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("resume_terminal", { clear = true }),
  callback = function()
    if vim.bo.buftype == "terminal" and vim.b.resume_terminal then
      vim.b.resume_terminal = nil
      vim.cmd.startinsert()
    end
  end,
})

-- Move the line or selection up and down, re-indenting as it goes.
vim.keymap.set("n", "<M-S-Down>", "<Cmd>silent! move .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<M-S-Up>", "<Cmd>silent! move .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("x", "<M-S-Down>", ":<C-u>silent! '<,'>move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("x", "<M-S-Up>", ":<C-u>silent! '<,'>move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Briefly highlight yanked text.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

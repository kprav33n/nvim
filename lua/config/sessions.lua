-- Sessions: one per startup directory, saved on quit, restored by plain `nvim`.
local dir = vim.fn.stdpath("state") .. "/sessions/"
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "globals", "tabpages", "winsize" }

local cwd = vim.fn.getcwd()
local function session_file()
  return dir .. cwd:gsub("/", "%%") .. ".vim"
end

-- Only manage the session when nvim was started without file arguments.
local enabled = vim.fn.argc(-1) == 0

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("session_restore", { clear = true }),
  nested = true, -- Let restored buffers fire FileType etc.
  callback = function()
    local file = session_file()
    if enabled and vim.fn.filereadable(file) == 1 then
      vim.cmd.source(vim.fn.fnameescape(file))
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("session_save", { clear = true }),
  callback = function()
    if not enabled then return end
    -- Drop explorer/Neogit-style windows; they can't be restored.
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= "" then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
    vim.api.nvim_exec_autocmds("User", { pattern = "SessionSavePre" })
    vim.fn.mkdir(dir, "p")
    vim.cmd.mksession({ vim.fn.fnameescape(session_file()), bang = true })
  end,
})

-- Forget this directory's session and stop saving it for this run.
vim.api.nvim_create_user_command("SessionDelete", function()
  enabled = false
  vim.fn.delete(session_file())
  vim.notify("Session deleted for " .. cwd)
end, { desc = "Delete the session for the startup directory" })

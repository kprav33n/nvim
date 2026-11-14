-- Telescope fuzzy finder.
require("telescope").setup({})

local pickers = require("telescope.builtin")

-- File finder that also accepts a typed path (/abs, ~/x, ./x, ../x):
-- a file opens (or is created), a directory reopens the finder there.
-- <C-e> drops to :edit with the typed text for <Tab> completion.
local function find_files(opts)
  opts = opts or {}
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local function typed_path()
    local typed = state.get_current_line()
    return typed, vim.fn.fnamemodify(vim.fn.expand(typed), ":p")
  end
  -- Use the typed path when it looks like a path and exists, or nothing matches.
  local function use_path()
    local typed, path = typed_path()
    local exists = vim.uv.fs_stat(path) ~= nil
    return (typed:match("^[~/]") or typed:match("^%.%.?/")) and exists or state.get_selected_entry() == nil
  end
  opts.attach_mappings = function(bufnr, map)
    actions.select_default:replace_if(use_path, function()
      local typed, path = typed_path()
      if typed == "" then return end
      if vim.fn.isdirectory(path) == 1 then
        actions.close(bufnr)
        find_files(vim.tbl_extend("force", opts, { cwd = path, prompt_title = vim.fn.fnamemodify(path, ":~") }))
      elseif vim.fn.isdirectory(vim.fn.fnamemodify(path, ":h")) == 1 then
        actions.close(bufnr)
        vim.cmd.edit(vim.fn.fnameescape(path))
      else
        vim.notify("No such directory: " .. vim.fn.fnamemodify(path, ":h"), vim.log.levels.WARN)
      end
    end)
    map({ "i", "n" }, "<C-e>", function()
      local typed = state.get_current_line()
      actions.close(bufnr)
      vim.api.nvim_feedkeys(":edit " .. typed, "n", false)
    end)
    return true
  end
  pickers.find_files(opts)
end

vim.keymap.set("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers", })
vim.keymap.set("n", "<leader>sb", pickers.buffers, { desc = "[S]earch [B]uffers", })
vim.keymap.set("n", "<leader>sf", function() find_files() end, { desc = "[S]earch [F]iles", })
vim.keymap.set("n", "<leader>sw", pickers.grep_string, { desc = "[S]earch Current [W]ord", })
vim.keymap.set("n", "<leader>sg", pickers.live_grep, { desc = "[S]earch by [G]rep", })
-- Capitals narrow the scope: current directory only (no subdirectories).
vim.keymap.set("n", "<leader>sF", function()
  find_files({ prompt_title = "Find Files (current dir only)", find_command = { "rg", "--files", "--max-depth", "1" } })
end, { desc = "[S]earch [F]iles in Current Dir", })
vim.keymap.set("n", "<leader>sG", function()
  pickers.live_grep({ prompt_title = "Live Grep (current dir only)", additional_args = { "--max-depth", "1" } })
end, { desc = "[S]earch by [G]rep in Current Dir", })
vim.keymap.set("n", "<leader>s/", function()
  pickers.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({ previewer = false }))
end, { desc = "[S]earch Current File ([/])", })
vim.keymap.set("n", "<leader>sr", pickers.resume, { desc = "[S]earch [R]esume", })
vim.keymap.set("n", "<leader>sd", pickers.diagnostics, { desc = "[S]earch [D]iagnostics", })
vim.keymap.set("n", "<leader>s.", pickers.oldfiles, { desc = "[S]earch Recent Files ([.])", })

vim.keymap.set("n", "<leader>sh", pickers.help_tags, { desc = "[S]earch [H]elp", })
vim.keymap.set("n", "<leader>sm", pickers.man_pages, { desc = "[S]earch [M]anuals", })

require("which-key").add({
  { "<leader>s", group = "[S]earch", icon = { icon = "", color = "green", }, },
})

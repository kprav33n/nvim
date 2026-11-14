-- Telescope fuzzy finder.
require("telescope").setup({})

local pickers = require("telescope.builtin")

vim.keymap.set("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers", })
vim.keymap.set("n", "<leader>sb", pickers.buffers, { desc = "[S]earch [B]uffers", })
vim.keymap.set("n", "<leader>sf", pickers.find_files, { desc = "[S]earch [F]iles", })
vim.keymap.set("n", "<leader>sw", pickers.grep_string, { desc = "[S]earch Current [W]ord", })
vim.keymap.set("n", "<leader>sg", pickers.live_grep, { desc = "[S]earch by [G]rep", })
-- Capitals narrow the scope: current directory only (no subdirectories).
vim.keymap.set("n", "<leader>sF", function()
  pickers.find_files({ prompt_title = "Find Files (current dir only)", find_command = { "rg", "--files", "--max-depth", "1" } })
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

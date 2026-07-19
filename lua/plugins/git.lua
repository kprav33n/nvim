-- Git integration.
require("gitsigns").setup({})

local neogit = require("neogit")
neogit.setup({})

local pickers = require("telescope.builtin")

vim.keymap.set("n", "<leader>gg", function() neogit.open() end, { desc = "[G]it [S]tatus (Neogit)" })
vim.keymap.set("n", "<leader>gc", function() neogit.open({ "commit" }) end, { desc = "[G]it [C]ommit" })
vim.keymap.set("n", "<leader>gp", function() neogit.open({ "pull" }) end, { desc = "[G]it [P]ull" })
vim.keymap.set("n", "<leader>gP", function() neogit.open({ "push" }) end, { desc = "[G]it [P]ush" })
vim.keymap.set("n", "<leader>gl", pickers.git_commits, { desc = "[G]it [L]og" })
vim.keymap.set("n", "<leader>gb", pickers.git_branches, { desc = "[G]it [B]ranches" })
vim.keymap.set("n", "<leader>gB", function() require("gitsigns").blame() end, { desc = "[G]it [B]lame" })

require("which-key").add({
  { "<leader>g", group = "[G]it", icon = { icon = "", color = "green" } },
})

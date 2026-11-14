-- File explorer.
require("neo-tree").setup({
  close_if_last_window = true,
  popup_border_style = "rounded",
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    hijack_netrw_behavior = "open_current",
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = true,
      never_show = { ".git" },
    },
  },
  window = {
    width = 32,
    mappings = {
      ["<space>"] = "none", -- Keep <Space> free for the leader key.
      ["l"] = "open",
      ["h"] = "close_node",
    },
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle reveal<CR>", { desc = "[E]xplorer Toggle" })
-- Switch focus between the tree and the last file window.
vim.keymap.set("n", "<leader>E", function()
  if vim.bo.filetype == "neo-tree" then
    vim.cmd.wincmd("p")
  else
    vim.cmd("Neotree focus")
  end
end, { desc = "[E]xplorer Focus Toggle" })
vim.keymap.set("n", "<leader>ge", "<cmd>Neotree float git_status<CR>", { desc = "[G]it [E]xplorer" })
vim.keymap.set("n", "<leader>sB", "<cmd>Neotree float buffers<CR>", { desc = "[S]earch [B]uffers (Tree)" })

require("which-key").add({
  { "<leader>e", icon = { icon = "", color = "yellow" } },
  { "<leader>E", icon = { icon = "", color = "yellow" } },
})

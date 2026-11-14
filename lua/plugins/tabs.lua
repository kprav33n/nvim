-- Tab pages, named after Greek letters.
-- Names live in t:tabname, which lualine's "tabs" component displays.
local letters = {
  "α alpha", "β beta", "γ gamma", "δ delta", "ε epsilon", "ζ zeta",
  "η eta", "θ theta", "ι iota", "κ kappa", "λ lambda", "μ mu",
  "ν nu", "ξ xi", "ο omicron", "π pi", "ρ rho", "σ sigma",
  "τ tau", "υ upsilon", "φ phi", "χ chi", "ψ psi", "ω omega",
}

-- First letter not already used by another tab.
local function next_name()
  local used = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, "tabname")
    if ok then used[name] = true end
  end
  for _, name in ipairs(letters) do
    if not used[name] then return name end
  end
  return tostring(#vim.api.nvim_list_tabpages())
end

local function name_tab(tab)
  local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, "tabname")
  if not ok or name == "" then
    vim.api.nvim_tabpage_set_var(tab, "tabname", next_name())
  end
end

local group = vim.api.nvim_create_augroup("greek_tabs", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "TabNewEntered" }, {
  group = group,
  callback = function() name_tab(vim.api.nvim_get_current_tabpage()) end,
})
-- Also name the first tab when this file is re-sourced after startup.
if vim.v.vim_did_enter == 1 then
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do name_tab(tab) end
end

-- Rename the current tab; an empty name reverts to the next free letter.
local function rename_tab()
  vim.ui.input({ prompt = "Tab name: ", default = vim.t.tabname }, function(input)
    if input == nil then return end
    vim.t.tabname = nil -- So next_name() can reuse this tab's own letter.
    vim.t.tabname = input ~= "" and input or next_name()
    vim.cmd.redrawtabline()
  end)
end

-- Tab keymaps.
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<leader>td", "<cmd>tabclose<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>to", "<cmd>tabonly<CR>", { desc = "Close other tabs" })
vim.keymap.set("n", "<leader>t]", "<cmd>tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>t[", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
vim.keymap.set("n", "<leader>tl", "g<Tab>", { desc = "Last-used tab", remap = true })
vim.keymap.set("n", "<leader>tr", rename_tab, { desc = "Rename tab" })

require("which-key").add({ { "<leader>t", group = "Tabs" } })

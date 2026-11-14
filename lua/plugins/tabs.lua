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

-- Carry tab names through sessions (only uppercase string globals are saved).
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "SessionSavePre",
  callback = function()
    local names = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      local ok, name = pcall(vim.api.nvim_tabpage_get_var, tab, "tabname")
      names[#names + 1] = ok and name or ""
    end
    vim.g.TabNames = vim.json.encode(names)
  end,
})
vim.api.nvim_create_autocmd("SessionLoadPost", {
  group = group,
  callback = function()
    local ok, names = pcall(vim.json.decode, vim.g.TabNames or "")
    if not ok then return end
    for i, tab in ipairs(vim.api.nvim_list_tabpages()) do
      if names[i] and names[i] ~= "" then vim.api.nvim_tabpage_set_var(tab, "tabname", names[i]) end
    end
    vim.cmd.redrawtabline()
  end,
})

-- Rename the current tab; an empty name reverts to the next free letter.
local function rename_tab()
  vim.ui.input({ prompt = "Tab name: ", default = vim.t.tabname }, function(input)
    if input == nil then return end
    vim.t.tabname = nil -- So next_name() can reuse this tab's own letter.
    vim.t.tabname = input ~= "" and input or next_name()
    vim.cmd.redrawtabline()
  end)
end

-- Directory picker: zoxide entries (by frecency), then git repos under ~.
local dir_source = [[
{ zoxide query -l
  find ~ -maxdepth 4 \( -name .cache -o -name .local -o -name node_modules \) -prune \
    -o -name .git -printf '%h\n'
} 2>/dev/null | awk '!seen[$0]++']]

local function pick_dir()
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local conf = require("telescope.config").values

  require("telescope.pickers").new({}, {
    prompt_title = "Tab Directory (<CR> tcd, <C-g> cd, <C-e> edit path)",
    finder = require("telescope.finders").new_oneshot_job({ "sh", "-c", dir_source }, {
      entry_maker = function(path)
        return { value = path, path = path, ordinal = path, display = vim.fn.fnamemodify(path, ":~") }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(bufnr, map)
      -- Selected entry, or the typed text as a path when nothing matches.
      local function change_dir(cmd)
        local entry = state.get_selected_entry()
        local typed = vim.fn.fnamemodify(vim.fn.expand(state.get_current_line()), ":p")
        local dir = entry and entry.value or typed
        if vim.fn.isdirectory(dir) == 0 then
          vim.notify("Not a directory: " .. dir, vim.log.levels.WARN)
          return
        end
        actions.close(bufnr)
        vim.cmd[cmd](vim.fn.fnameescape(dir))
        vim.system({ "zoxide", "add", dir }) -- Rank dirs used from nvim too.
      end
      actions.select_default:replace(function() change_dir("tcd") end)
      map({ "i", "n" }, "<C-g>", function() change_dir("cd") end)
      -- Drop to :tcd with the typed text, for <Tab> path completion.
      map({ "i", "n" }, "<C-e>", function()
        local typed = state.get_current_line()
        actions.close(bufnr)
        vim.api.nvim_feedkeys(":tcd " .. typed, "n", false)
      end)
      return true
    end,
  }):find()
end

-- Tab keymaps.
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<leader>td", "<cmd>tabclose<CR>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>to", "<cmd>tabonly<CR>", { desc = "Close other tabs" })
vim.keymap.set("n", "<leader>t]", "<cmd>tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<leader>t[", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
vim.keymap.set("n", "<leader>tl", "g<Tab>", { desc = "Last-used tab", remap = true })
vim.keymap.set("n", "<leader>tr", rename_tab, { desc = "Rename tab" })
vim.keymap.set("n", "<leader>tc", pick_dir, { desc = "Change tab directory" })

require("which-key").add({ { "<leader>t", group = "Tabs" } })

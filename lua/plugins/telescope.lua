-- Telescope fuzzy finder.
require("telescope").setup({
  defaults = {
    -- Stack the preview above the results.
    layout_strategy = "vertical",
    -- Keep the preview on shorter screens (default cutoff is 40 lines).
    layout_config = { vertical = { preview_cutoff = 25 } },
  },
})

-- Route vim.ui.select (code actions, :PyVenv, ...) through telescope.
require("telescope").load_extension("ui-select")

local pickers = require("telescope.builtin")

local actions = require("telescope.actions")
local state = require("telescope.actions.state")

-- True when the prompt is a path (/abs, ~/x, ./x, ../x) rather than a fuzzy query.
local function is_path(text)
  return text:match("^[~/]") ~= nil or text:match("^%.%.?/") ~= nil
end

-- Open a typed path: a file opens (or is created), a directory reopens the finder there.
local function open_typed(bufnr, typed, reopen)
  local path = vim.fn.fnamemodify(vim.fn.expand(typed), ":p")
  if vim.fn.isdirectory(path) == 1 then
    actions.close(bufnr)
    reopen({ cwd = path, prompt_title = vim.fn.fnamemodify(path, ":~") })
  elseif vim.fn.isdirectory(vim.fn.fnamemodify(path, ":h")) == 1 then
    actions.close(bufnr)
    vim.cmd.edit(vim.fn.fnameescape(path))
  else
    vim.notify("No such directory: " .. vim.fn.fnamemodify(path, ":h"), vim.log.levels.WARN)
  end
end

-- <C-e>: drop to :edit with the typed text for native <Tab> completion.
local function map_edit(bufnr, map)
  map({ "i", "n" }, "<C-e>", function()
    local typed = state.get_current_picker(bufnr):_get_prompt() -- Raw, unfiltered.
    actions.close(bufnr)
    vim.api.nvim_feedkeys(":edit " .. typed, "n", false)
  end)
end

-- File finder that accepts typed paths (used by <leader>sF).
local function find_files(opts)
  opts = opts or {}
  -- Use the typed path when it looks like a path and exists, or nothing matches.
  local function use_path()
    local typed = state.get_current_line()
    local exists = vim.uv.fs_stat(vim.fn.expand(typed)) ~= nil
    return is_path(typed) and exists or state.get_selected_entry() == nil
  end
  opts.attach_mappings = function(bufnr, map)
    actions.select_default:replace_if(use_path, function()
      local typed = state.get_current_line()
      if typed ~= "" then
        open_typed(bufnr, typed, function(o) find_files(vim.tbl_extend("force", opts, o)) end)
      end
    end)
    map_edit(bufnr, map)
    return true
  end
  pickers.find_files(opts)
end

-- Entries of the directory typed so far, dirs first; dotfiles only when asked.
local function dir_finder(typed_dir, hidden)
  local dir = vim.fn.fnamemodify(vim.fn.expand(typed_dir), ":p")
  local dirs, files = {}, {}
  if vim.fn.isdirectory(dir) == 1 then
    for name, kind in vim.fs.dir(dir) do
      if hidden or name:sub(1, 1) ~= "." then
        local path = vim.fs.joinpath(dir, name)
        local is_dir = kind == "directory" or (kind == "link" and vim.fn.isdirectory(path) == 1)
        table.insert(is_dir and dirs or files, { name = name, path = path, is_dir = is_dir })
      end
    end
  end
  local by_name = function(a, b) return a.name < b.name end
  table.sort(dirs, by_name)
  table.sort(files, by_name)
  return require("telescope.finders").new_table({
    results = vim.list_extend(dirs, files),
    entry_maker = function(e)
      local display = e.name .. (e.is_dir and "/" or "")
      return { value = e.path, path = e.path, ordinal = e.name, display = display,
        is_dir = e.is_dir, completion = typed_dir .. display }
    end,
  })
end

-- File finder with incremental path completion (used by <leader>sf).
-- Fuzzy search by default; a path prompt lists that directory as you type.
-- <Tab> completes the highlighted entry; <CR> enters a dir or opens a file,
-- and on a prompt ending in "/" fuzzy-finds inside that directory.
local function find_files_complete(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.uv.cwd()
  local mode = "fuzzy"
  -- fzy matches short prompts like "." that the default file sorter drops.
  opts.sorter = require("telescope.sorters").get_fzy_sorter()

  local function fuzzy_finder()
    return require("telescope.finders").new_oneshot_job(
      opts.find_command or { "rg", "--files", "--color", "never" },
      { cwd = opts.cwd, entry_maker = require("telescope.make_entry").gen_from_file(opts) })
  end

  -- Swap the result list when the prompt switches between fuzzy and a directory.
  opts.on_input_filter_cb = function(prompt)
    if is_path(prompt) then
      local typed_dir, part = prompt:match("^(.*/)([^/]*)$")
      if not typed_dir then typed_dir, part = prompt .. "/", "" end -- bare "~"
      local hidden = part:sub(1, 1) == "."
      local key = typed_dir .. (hidden and "\0hidden" or "")
      if key ~= mode then
        mode = key
        return { prompt = part, updated_finder = dir_finder(typed_dir, hidden) }
      end
      return { prompt = part }
    elseif mode ~= "fuzzy" then
      mode = "fuzzy"
      return { updated_finder = fuzzy_finder() }
    end
  end

  opts.attach_mappings = function(bufnr, map)
    -- Raw prompt; get_current_line() returns it after on_input_filter_cb.
    local function prompt()
      return state.get_current_picker(bufnr):_get_prompt()
    end
    local function complete(entry)
      state.get_current_picker(bufnr):set_prompt(entry.completion)
    end
    -- Fuzzy picks with a match keep Telescope's normal <CR>.
    local function custom()
      return is_path(prompt()) or state.get_selected_entry() == nil
    end
    actions.select_default:replace_if(custom, function()
      local typed = prompt()
      local entry = state.get_selected_entry()
      if typed:sub(-1) ~= "/" and entry and entry.completion then
        if entry.is_dir then
          complete(entry)
        else
          actions.close(bufnr)
          vim.cmd.edit(vim.fn.fnameescape(entry.path))
        end
      elseif typed ~= "" then
        open_typed(bufnr, typed, function(o) find_files_complete(vim.tbl_extend("force", opts, o)) end)
      end
    end)
    map({ "i", "n" }, "<Tab>", function()
      local entry = state.get_selected_entry()
      if is_path(prompt()) and entry and entry.completion then
        complete(entry)
      else
        actions.toggle_selection(bufnr)
        actions.move_selection_worse(bufnr)
      end
    end)
    map_edit(bufnr, map)
    return true
  end
  pickers.find_files(opts)
end

vim.keymap.set("n", "<leader>sp", pickers.builtin, { desc = "[S]earch Builtin [P]ickers", })
vim.keymap.set("n", "<leader>sb", pickers.buffers, { desc = "[S]earch [B]uffers", })
vim.keymap.set("n", "<leader>sf", function() find_files_complete() end, { desc = "[S]earch [F]iles", })
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

-- Language servers via the built-in client; nvim-lspconfig supplies the configs.
-- Built-in keys: grn rename, gra action, grr refs, gri impl, gO symbols, K hover.
local servers = { "lua_ls", "rust_analyzer", "basedpyright", "ruff", "clangd", "gopls" }

-- Neovim runtime for lua_ls, so vim.* resolves in this config.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
    },
  },
})

-- Python interpreter inside a venv directory, if it has one.
local function venv_python(dir)
  local python = vim.fs.joinpath(dir, "bin", "python")
  return vim.fn.executable(python) == 1 and python or nil
end

-- Candidate venvs: active one, project-local ones, then (if asked) shared dirs.
local function find_venvs(root, include_shared)
  local found, seen = {}, {}
  local function add(dir)
    dir = vim.fs.normalize(dir)
    if not seen[dir] and venv_python(dir) then
      seen[dir] = true
      table.insert(found, dir)
    end
  end
  if vim.env.VIRTUAL_ENV then add(vim.env.VIRTUAL_ENV) end
  for _, name in ipairs({ ".venv", "venv", "env" }) do
    add(vim.fs.joinpath(root, name))
  end
  for _, shared in ipairs(include_shared and { "~/venvs", "~/.virtualenvs" } or {}) do
    for name, kind in vim.fs.dir(shared) do
      if kind == "directory" then add(vim.fs.joinpath(shared, name)) end
    end
  end
  return found
end

-- Point basedpyright at the project's venv when none is active.
vim.lsp.config("basedpyright", {
  before_init = function(_, config)
    local venv = find_venvs(config.root_dir or vim.fn.getcwd())[1]
    if venv then
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = venv_python(venv)
    end
  end,
})

-- Switch the current buffer's basedpyright to another venv.
local function set_venv(dir)
  local python = venv_python(vim.fn.fnamemodify(dir, ":p"))
  if not python then
    vim.notify("No bin/python in " .. dir, vim.log.levels.ERROR)
    return
  end
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" })
  if #clients == 0 then
    vim.notify("basedpyright is not attached to this buffer", vim.log.levels.WARN)
    return
  end
  for _, client in ipairs(clients) do
    client.settings.python = client.settings.python or {}
    client.settings.python.pythonPath = python
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  end
  vim.notify("Python venv: " .. dir)
end

vim.api.nvim_create_user_command("PyVenv", function(opts)
  if opts.args ~= "" then return set_venv(opts.args) end
  local client = vim.lsp.get_clients({ bufnr = 0, name = "basedpyright" })[1]
  local root = client and client.root_dir or vim.fn.getcwd()
  vim.ui.select(find_venvs(root, true), { prompt = "Python venv" }, function(dir)
    if dir then set_venv(dir) end
  end)
end, { nargs = "?", complete = "dir", desc = "Pick the venv basedpyright uses" })

vim.keymap.set("n", "<leader>sv", "<cmd>PyVenv<cr>", { desc = "[S]elect Python [V]env" })

-- Enable only the servers that are installed.
for _, name in ipairs(servers) do
  local cmd = vim.lsp.config[name] and vim.lsp.config[name].cmd
  if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(name)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
  callback = function(args)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end
    local pickers = require("telescope.builtin")
    map("gd", pickers.lsp_definitions, "[G]oto [D]efinition")
    map("<leader>sS", pickers.lsp_dynamic_workspace_symbols, "[S]earch Workspace [S]ymbols")
    -- Whole buffer, or just the selection in visual mode.
    vim.keymap.set({ "n", "x" }, "<leader>f", function()
      vim.lsp.buf.format({ timeout_ms = 3000 })
      if vim.fn.mode() ~= "n" then vim.cmd.normal({ vim.keycode("<Esc>"), bang = true }) end
    end, { buffer = args.buf, desc = "[F]ormat" })
  end,
})

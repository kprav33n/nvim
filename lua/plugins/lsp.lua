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
  end,
})

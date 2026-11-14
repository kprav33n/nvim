-- Treesitter highlighting and indent; missing parsers install on first use.
-- Needs the tree-sitter CLI and a C compiler. Update parsers with :TSUpdate.
local ts = require("nvim-treesitter")
local available = require("nvim-treesitter.parsers")
local installing = {}

local function attach(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
    return
  end
  -- Deferred so the filetype's own indent script doesn't override it.
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) and vim.treesitter.query.get(lang, "indents") then
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then return end
    if vim.treesitter.language.add(lang) then
      attach(args.buf, lang)
    elseif available[lang] and not installing[lang] and vim.fn.executable("tree-sitter") == 1 then
      installing[lang] = true
      ts.install({ lang }):await(function()
        installing[lang] = nil
        vim.schedule(function() attach(args.buf, lang) end)
      end)
    end
  end,
})

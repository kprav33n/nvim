-- Statusline.
local lualine = require("lualine")

-- Single global statusline; lualine shows the mode so hide the built-in one.
vim.opt.laststatus = 3
vim.opt.showmode = false

-- Git diff counts from gitsigns (avoids lualine running its own git diff).
local function gitsigns_diff()
  local gs = vim.b.gitsigns_status_dict
  if gs then
    return { added = gs.added, modified = gs.changed, removed = gs.removed }
  end
end

-- Macro recording indicator (showmode is off, so surface it here).
local function macro_recording()
  local reg = vim.fn.reg_recording()
  return reg ~= "" and ("recording @" .. reg) or ""
end

-- Names of LSP clients attached to the current buffer.
local function lsp_clients()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, client.name)
  end
  return #names > 0 and ("\u{f013} " .. table.concat(names, ", ")) or ""
end

lualine.setup({
  options = {
    theme = "catppuccin-nvim", -- Follows the active catppuccin flavour.
    globalstatus = true,
    -- Rounded "bubble" separators (nerd font glyphs as escapes so they survive edits).
    component_separators = { left = "\u{e0b5}", right = "\u{e0b7}" },
    section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" },
    always_show_tabline = false,
    disabled_filetypes = { statusline = { "dashboard", "alpha" } },
  },
  sections = {
    lualine_a = { { "mode", separator = { left = "\u{e0b6}" }, right_padding = 2 } },
    lualine_b = {
      { "branch", icon = "\u{e0a0}" },
      { "diff", source = gitsigns_diff, symbols = { added = "\u{eadc} ", modified = "\u{eade} ", removed = "\u{eadf} " } },
    },
    lualine_c = {
      { "filename", path = 1, symbols = { modified = "●", readonly = "\u{f023}", unnamed = "[No Name]", newfile = "[New]" } },
      { "diagnostics", sources = { "nvim_diagnostic" } },
    },
    lualine_x = {
      { macro_recording, color = { fg = require("catppuccin.palettes").get_palette().red, gui = "bold" } },
      { "searchcount", maxcount = 999 },
      lsp_clients,
      { "filetype" },
      { "encoding", cond = function() return vim.bo.fileencoding ~= "utf-8" end },
      { "fileformat", cond = function() return vim.bo.fileformat ~= "unix" end },
    },
    lualine_y = { "progress" },
    lualine_z = { { "location", separator = { right = "\u{e0b4}" }, left_padding = 2 } },
  },
  -- Tab names (Greek letters, see plugins/tabs.lua); hidden with a single tab.
  tabline = {
    lualine_a = { { "tabs", mode = 1, max_length = vim.o.columns, show_modified_status = false } },
  },
  extensions = { "neo-tree", "quickfix", "man" },
})

-- Redraw immediately when macro recording starts/stops.
vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
  group = vim.api.nvim_create_augroup("lualine_macro", { clear = true }),
  callback = function()
    vim.schedule(lualine.refresh)
  end,
})

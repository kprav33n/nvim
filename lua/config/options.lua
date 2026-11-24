-- Leader key.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable true color support
vim.opt.termguicolors = true

-- Line numbers: absolute and relative side by side.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.statuscolumn = "%s%{&nu && !v:virtnum ? printf('%*d %2s', len(line('$')), v:lnum, v:relnum ? v:relnum : '') : ''} "

-- Case-insensitive search unless the pattern has a capital.
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep context around the cursor.
vim.opt.scrolloff = 8

-- Open splits to the right and below.
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Faster CursorHold (gitsigns) and which-key popup.
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Ask to save instead of failing on :q with changes.
vim.opt.confirm = true

-- Enable mouse mode.
vim.opt.mouse = "a"

-- Sync with OS clipboard.
--  see `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"

-- Copy via OSC 52 (works over SSH). Paste returns the last copy instead of
-- querying the terminal, which many terminals/tmux never answer (hangs on p).
-- Paste from the system clipboard with the terminal's own paste key.
local osc52 = require("vim.ui.clipboard.osc52")
local last = {}
local function copy(reg)
  local send = osc52.copy(reg)
  return function(lines, regtype)
    last[reg] = { lines, regtype }
    send(lines)
  end
end
local function paste(reg)
  return function() return last[reg] or { {}, "v" } end
end
vim.g.clipboard = {
  name = "OSC 52 (copy only)",
  copy = { ["+"] = copy("+"), ["*"] = copy("*") },
  paste = { ["+"] = paste("+"), ["*"] = paste("*") },
}

-- Save undo history.
vim.opt.undofile = true

-- Always show sign column.
vim.opt.signcolumn = "yes"

-- Highlight whitespace characters.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", }

-- Enable live preview of substitutions.
vim.opt.inccommand = "split"

-- Show the line where the cursor is on.
vim.opt.cursorline = true

-- Set highlight on search.
vim.opt.hlsearch = true

-- Enable line wrapping.
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.breakindentopt = 'shift:2,min:20' -- Shift 2 spaces, min 20 chars

-- Default formatting.
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.textwidth = 80

-- Reload buffers changed on disk (e.g. by Claude Code or git).
-- FocusGained needs `set -g focus-events on` in tmux.
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("auto_checktime", { clear = true }),
  callback = function()
    -- :checktime is not allowed in the command-line window.
    if vim.fn.getcmdwintype() == "" then vim.cmd.checktime() end
  end,
})
-- Terminal mode fires none of the events above, so poll while in it.
vim.fn.timer_start(1000, function()
  if vim.api.nvim_get_mode().mode == "t" then vim.cmd.checktime() end
end, { ["repeat"] = -1 })

-- Experimental messages and command-line UI (no "Press ENTER" prompts).
require("vim._core.ui2").enable()

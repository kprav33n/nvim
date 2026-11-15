-- Quick jump: label lines, words or characters in the visible windows, then
-- jump to the one whose label is typed.
local labels = "aoeuhtns" -- Label keys (Dvorak home row); nearest targets get the shortest labels.
local word_timeout = 500 -- Idle milliseconds that end word input.

local ns = vim.api.nvim_create_namespace("jump")
vim.api.nvim_set_hl(0, "JumpLabel", { default = true, link = "IncSearch" })
vim.api.nvim_set_hl(0, "JumpDim", { default = true, link = "Comment" })

local esc, cr, bs = vim.keycode("<Esc>"), vim.keycode("<CR>"), vim.keycode("<BS>")

-- "n", "x" (visual) or "o" (operator-pending).
local function current_mode()
  local mode = vim.fn.mode(true)
  if mode:sub(1, 2) == "no" then return "o" end
  if mode:find("^[vV\22]") then return "x" end
  return "n"
end

-- Every split of the tab, or only the current window when the jump extends a
-- selection or an operator.
local function target_wins(mode)
  if mode ~= "n" then return { vim.api.nvim_get_current_win() } end
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

-- Whether byte `i` begins a word: after a non-alphanumeric or on a camelCase hump.
local function starts_word(line, i)
  local prev, cur = line:sub(i - 1, i - 1), line:sub(i, i)
  if not prev:find("[%w\128-\255]") then return true end
  return prev:find("%l") ~= nil and cur:find("%u") ~= nil
end

-- Matcher returning the 0-based byte columns of `needle` in a line. Smartcase:
-- case only matters when the needle has a capital. With `word_start`, a needle
-- that begins with a letter or digit only matches at the start of a word.
local function finder(needle, word_start)
  local fold = needle == vim.fn.tolower(needle)
  word_start = word_start and needle:find("^[%w\128-\255]") ~= nil
  return function(line)
    local cols, hay, from = {}, fold and vim.fn.tolower(line) or line, 1
    while true do
      local s, e = hay:find(needle, from, true)
      if not s then return cols end
      if not word_start or starts_word(line, s) then cols[#cols + 1] = s - 1 end
      from = e + 1
    end
  end
end

-- Visible targets as { win, lnum, col, dist }. Without `find`, one per line.
local function collect(wins, find)
  local targets = {}
  local cur_win = vim.api.nvim_get_current_win()
  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      local cursor = vim.api.nvim_win_get_cursor(win)
      local info, leftcol = vim.fn.getwininfo(win)[1], vim.fn.winsaveview().leftcol
      local width = info.width - info.textoff
      local function add(lnum, col)
        local here = win == cur_win and lnum == cursor[1]
        if here and (not find or col == cursor[2]) then return end
        if find and not vim.wo.wrap then
          local vcol = vim.fn.virtcol({ lnum, col + 1 })
          if vcol <= leftcol or vcol > leftcol + width then return end
        end
        local dist = math.abs(lnum - cursor[1]) * 10000 + math.abs(col - cursor[2])
        targets[#targets + 1] = { win = win, lnum = lnum, col = col, dist = dist }
      end

      local lnum, last = vim.fn.line("w0"), vim.fn.line("w$")
      while lnum <= last do
        local fold_end = vim.fn.foldclosedend(lnum)
        local line = vim.fn.getline(lnum)
        if not find then
          add(lnum, (line:find("%S") or 1) - 1)
        elseif fold_end == -1 then
          for _, col in ipairs(find(line)) do add(lnum, col) end
        end
        lnum = (fold_end == -1 and lnum or fold_end) + 1
      end
    end)
  end

  -- Current window first, then nearest to each window's cursor.
  table.sort(targets, function(a, b)
    if a.win ~= b.win then
      if a.win == cur_win or b.win == cur_win then return a.win == cur_win end
      return a.win < b.win
    end
    return a.dist < b.dist
  end)
  return targets
end

-- Give each target a prefix-free chord, using as many short ones as possible.
local function assign(targets)
  local keys = vim.split(labels, "")
  local len, cap = 1, #keys
  while cap < #targets do len, cap = len + 1, cap * #keys end

  local prefixes = { "" }
  for _ = 2, len do
    local longer = {}
    for _, prefix in ipairs(prefixes) do
      for _, key in ipairs(keys) do longer[#longer + 1] = prefix .. key end
    end
    prefixes = longer
  end

  -- Prefixes that can stay one key shorter and still leave room for the rest.
  local short = len > 1 and math.floor((cap - #targets) / (#keys - 1)) or 0
  local i = 1
  for p, prefix in ipairs(prefixes) do
    for _, key in ipairs(p <= short and { "" } or keys) do
      if not targets[i] then return end
      targets[i].label = prefix .. key
      i = i + 1
    end
  end
end

-- Show the labels and read keys until one target is chosen; nil on cancel.
local function pick(targets, linewise)
  local rows, typed = {}, ""
  for _, t in ipairs(targets) do
    rows[t.win] = rows[t.win] or {}
    rows[t.win][t.lnum - 1] = rows[t.win][t.lnum - 1] or {}
    table.insert(rows[t.win][t.lnum - 1], t)
  end
  for _, win_rows in pairs(rows) do
    for _, row in pairs(win_rows) do
      table.sort(row, function(a, b) return a.col < b.col end)
    end
  end

  -- Ephemeral marks, so a buffer shown in two windows gets separate labels.
  vim.api.nvim_set_decoration_provider(ns, {
    on_line = function(_, win, buf, row)
      if not rows[win] then return end
      -- Dim everything but the labels.
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        ephemeral = true,
        priority = 999,
        end_row = row + 1,
        hl_group = "JumpDim",
      })
      local live = vim.tbl_filter(function(t)
        return vim.startswith(t.label, typed)
      end, rows[win][row] or {})
      for i, t in ipairs(live) do
        -- Don't run into the next label on the line.
        local room = live[i + 1] and live[i + 1].col - t.col or #t.label
        vim.api.nvim_buf_set_extmark(buf, ns, row, t.col, {
          ephemeral = true,
          priority = 1000,
          virt_text = { { t.label:sub(#typed + 1, #typed + room), "JumpLabel" } },
          virt_text_pos = "overlay",
          virt_text_win_col = linewise and 0 or nil,
        })
      end
    end,
  })

  local ok, choice = pcall(function()
    while true do
      vim.cmd.redraw({ bang = true })
      typed = typed .. vim.fn.getcharstr()
      local live = false
      for _, t in ipairs(targets) do
        if t.label == typed then return t end
        live = live or vim.startswith(t.label, typed)
      end
      if not live then return nil end
    end
  end)
  vim.api.nvim_set_decoration_provider(ns, {})
  vim.cmd.redraw({ bang = true })
  return ok and choice or nil
end

local function jump(target, mode, linewise)
  if mode == "n" then
    vim.cmd("normal! m'")
    vim.api.nvim_set_current_win(target.win)
  elseif mode == "o" and linewise then
    vim.cmd("normal! V")
  end
  vim.api.nvim_win_set_cursor(target.win, { target.lnum, target.col })
  if mode == "n" then vim.cmd("normal! zv") end
end

local function run(find)
  local mode, linewise = current_mode(), find == nil
  local targets = collect(target_wins(mode), find)
  if #targets == 0 then
    vim.notify("No jump targets", vim.log.levels.WARN)
    return
  end
  local target = targets[1]
  if #targets > 1 then
    assign(targets)
    target = pick(targets, linewise)
  end
  if target then jump(target, mode, linewise) end
end

local function prompt(text)
  vim.api.nvim_echo({ { text } }, false, {})
  vim.cmd.redraw()
end

-- Next key, or "" after `timeout` idle milliseconds (nil waits forever).
local function getkey(timeout)
  if not timeout then return vim.fn.getcharstr() end
  local key = ""
  vim.wait(timeout, function()
    key = vim.fn.getcharstr(0)
    return key ~= ""
  end, 10)
  return key
end

-- Read text until <CR> or an idle pause; nil on <Esc> or when left empty.
local function read_word()
  local word = ""
  while true do
    prompt("Jump to word: " .. word)
    local ok, key = pcall(getkey, word ~= "" and word_timeout or nil)
    if not ok or key == esc then return nil end
    if key == "" or key == cr then break end
    if key == bs then
      word = vim.fn.strcharpart(word, 0, vim.fn.strchars(word) - 1)
    elseif vim.fn.strdisplaywidth(key) > 0 and key:byte() ~= 0x80 then
      word = word .. key
    end
  end
  return word ~= "" and word or nil
end

local function read_char()
  prompt("Jump to char: ")
  local ok, key = pcall(getkey)
  if not ok or key == esc or key:byte() == 0x80 then return nil end
  return key
end

local function jump_line() run(nil) end

local function jump_word()
  local word = read_word()
  prompt("")
  if word then run(finder(word, true)) end
end

local function jump_char()
  local char = read_char()
  prompt("")
  if char then run(finder(char)) end
end

local modes = { "n", "x", "o" }
vim.keymap.set(modes, "<leader>jl", jump_line, { desc = "[J]ump to [L]ine" })
vim.keymap.set(modes, "<leader>jw", jump_word, { desc = "[J]ump to [W]ord" })
vim.keymap.set(modes, "<leader>jj", jump_word, { desc = "[J]ump to Word ([J])" })
vim.keymap.set(modes, "<leader>jc", jump_char, { desc = "[J]ump to [C]haracter" })

require("which-key").add({
  { "<leader>j", group = "[J]ump", mode = modes, icon = { icon = "󰆾", color = "blue" } },
})

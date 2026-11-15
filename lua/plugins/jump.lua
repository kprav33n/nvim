-- Quick jump: label lines, words or characters in the visible windows, then
-- jump to the one whose label is typed.
local labels = "aoeuhtns" -- Label keys (Dvorak home row); nearest targets get the shortest labels.
local overflow_labels = "idgcrl" -- Extra keys, added one at a time only to avoid three-key chords.
local word_timeout = 500 -- Idle milliseconds that end word input.

local M = {}
local pending -- Jump chosen for the operator that is waiting on M.apply.
local remote_op -- Operator and register a remote jump reruns at its target.
local last -- Redoes the latest operator jump from the new cursor, for `.`.
local ns = vim.api.nvim_create_namespace("jump")
vim.api.nvim_set_hl(0, "JumpLabel", { default = true, link = "IncSearch" })
vim.api.nvim_set_hl(0, "JumpDim", { default = true, link = "Comment" })
vim.api.nvim_set_hl(0, "JumpMatch", { default = true, link = "Search" })

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

-- Visible targets as { win, lnum, col, dist, after }, at the columns `find(line, lnum)`
-- returns for each line. `linewise` targets stand for their whole line.
local function collect(wins, find, linewise)
  local targets = {}
  local cur_win = vim.api.nvim_get_current_win()
  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      local cursor = vim.api.nvim_win_get_cursor(win)
      local info, leftcol = vim.fn.getwininfo(win)[1], vim.fn.winsaveview().leftcol
      local width = info.width - info.textoff
      local function add(lnum, col)
        local here = win == cur_win and lnum == cursor[1]
        if here and (linewise or col == cursor[2]) then return end
        if not linewise and not vim.wo.wrap then
          local vcol = vim.fn.virtcol({ lnum, col + 1 })
          if vcol <= leftcol or vcol > leftcol + width then return end
        end
        local dist = math.abs(lnum - cursor[1]) * 10000 + math.abs(col - cursor[2])
        local after = lnum > cursor[1] or (lnum == cursor[1] and col > cursor[2])
        targets[#targets + 1] = { win = win, lnum = lnum, col = col, dist = dist, after = after }
      end

      local lnum, last = vim.fn.line("w0"), vim.fn.line("w$")
      while lnum <= last do
        local fold_end = vim.fn.foldclosedend(lnum)
        local line = vim.fn.getline(lnum)
        if linewise or fold_end == -1 then
          for _, col in ipairs(find(line, lnum)) do add(lnum, col) end
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
  for _, key in ipairs(vim.split(overflow_labels, "", { trimempty = true })) do
    if #keys * #keys >= #targets then break end
    keys[#keys + 1] = key
  end
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

-- Read keys until they spell one target's label; nil on any other key.
-- `show(typed)` redraws the labels before each key.
local function read_label(targets, show)
  local ok, choice = pcall(function()
    local typed = ""
    while true do
      show(typed)
      typed = typed .. vim.fn.getcharstr()
      local live = false
      for _, t in ipairs(targets) do
        if t.label == typed then return t end
        live = live or vim.startswith(t.label, typed)
      end
      if not live then return nil end
    end
  end)
  return ok and choice or nil
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

  local choice = read_label(targets, function(keys)
    typed = keys
    vim.cmd.redraw({ bang = true })
  end)
  vim.api.nvim_set_decoration_provider(ns, {})
  vim.cmd.redraw({ bang = true })
  return choice
end

local function jump(target, mode, opts)
  if mode == "n" then
    vim.cmd("normal! m'")
    vim.api.nvim_set_current_win(target.win)
  elseif mode == "o" and opts.linewise then
    vim.cmd("normal! V")
  elseif mode == "o" and opts.inclusive and target.after then
    vim.cmd("normal! v")
  end
  vim.api.nvim_win_set_cursor(target.win, { target.lnum, target.col })
  if mode == "n" then vim.cmd("normal! zv") end
end

-- Label the targets `find` yields and return the jump to the chosen one as a
-- function, or nil when cancelled. Options: `linewise` for whole-line targets,
-- `inclusive` to make an operator take the target character too.
local function run(find, opts)
  opts = opts or {}
  local mode = current_mode()
  local targets = collect(target_wins(mode), find, opts.linewise)
  if #targets == 0 then
    vim.notify("No jump targets", vim.log.levels.WARN)
    return
  end
  local target = targets[1]
  if #targets > 1 then
    assign(targets)
    target = pick(targets, opts.linewise)
  end
  if not target then return nil end

  -- `.` goes to the target as far from the cursor, in the same direction.
  local nth = 0
  for _, t in ipairs(targets) do
    if t.win == target.win and t.after == target.after then nth = nth + 1 end
    if t == target then break end
  end
  return function()
    jump(target, mode, opts)
    if mode ~= "o" then return end
    last = function()
      local again = vim.tbl_filter(function(t)
        return t.after == target.after
      end, collect({ vim.api.nvim_get_current_win() }, find, opts.linewise))
      if again[nth] then jump(again[nth], mode, opts) end
    end
  end
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

-- Read the text to jump to, highlighting its matches as it is typed. Ends at
-- `max` characters, on <CR>, or after an idle pause when there is no `max`.
-- Returns nil on <Esc> or when left empty.
local function read_text(label, max, word_start)
  local text, find, wins = "", nil, {}
  for _, win in ipairs(target_wins(current_mode())) do wins[win] = true end
  vim.api.nvim_set_decoration_provider(ns, {
    on_line = function(_, win, buf, row)
      if not find or not wins[win] then return end
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
      for _, col in ipairs(find(line)) do
        vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
          ephemeral = true,
          priority = 1000,
          end_col = math.min(col + #text, #line),
          hl_group = "JumpMatch",
        })
      end
    end,
  })

  local ok, done = pcall(function()
    while true do
      find = text ~= "" and finder(text, word_start) or nil
      vim.cmd.redraw({ bang = true })
      prompt(label .. text)
      if max and vim.fn.strchars(text) >= max then return true end
      local key = getkey(not max and text ~= "" and word_timeout or nil)
      if key == esc then return false end
      if key == "" or key == cr then return true end
      if key == bs then
        text = vim.fn.strcharpart(text, 0, vim.fn.strchars(text) - 1)
      elseif vim.fn.strdisplaywidth(key) > 0 and key:byte() ~= 0x80 then
        text = text .. key
      end
    end
  end)
  vim.api.nvim_set_decoration_provider(ns, {})
  vim.cmd.redraw({ bang = true })
  prompt("")
  return ok and done and text ~= "" and text or nil
end

local function jump_line()
  return run(function(line) return { (line:find("%S") or 1) - 1 } end, { linewise = true })
end

local function jump_word()
  local word = read_text("Jump to word: ", nil, true)
  return word and run(finder(word, true))
end

local function jump_char()
  local char = read_text("Jump to char: ", 1)
  return char and run(finder(char), { inclusive = true })
end

local function jump_chars()
  local chars = read_text("Jump to chars: ", 2)
  return chars and run(finder(chars))
end

-- Every word start, with nothing to type first.
local function jump_starts()
  return run(function(line)
    local cols = {}
    for col in line:gmatch("()[%w_\128-\255]+") do cols[#cols + 1] = col - 1 end
    return cols
  end)
end

-- Every visible diagnostic.
local function jump_diagnostic()
  return run(function(_, lnum)
    local cols = {}
    for _, d in ipairs(vim.diagnostic.get(0, { lnum = lnum - 1 })) do cols[d.col] = true end
    return vim.tbl_keys(cols)
  end)
end

-- Label each other split in a float at its centre and focus the chosen one.
local function jump_window()
  local cur, targets, floats = vim.api.nvim_get_current_win(), {}, {}
  for _, win in ipairs(target_wins("n")) do
    if win ~= cur then targets[#targets + 1] = { win = win } end
  end
  local target = targets[1]
  if #targets > 1 then
    assign(targets)
    for _, t in ipairs(targets) do
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = "wipe"
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", "  " .. t.label .. "  ", "" })
      local width, height = #t.label + 4, 3
      local float = vim.api.nvim_open_win(buf, false, {
        relative = "win",
        win = t.win,
        row = math.max(math.floor((vim.api.nvim_win_get_height(t.win) - height) / 2), 0),
        col = math.max(math.floor((vim.api.nvim_win_get_width(t.win) - width) / 2), 0),
        width = width,
        height = height,
        style = "minimal",
        focusable = false,
        noautocmd = true,
      })
      vim.wo[float].winhighlight = "NormalFloat:JumpLabel"
      floats[#floats + 1] = float
    end
    target = read_label(targets, function() vim.cmd.redraw() end)
    for _, float in ipairs(floats) do vim.api.nvim_win_close(float, true) end
  end
  if target then vim.api.nvim_set_current_win(target.win) end
end

-- Syntax nodes around the cursor, innermost first, as targets with a `range`.
-- A label sits at its node's start, or at its end when the start is taken or
-- off screen.
local function node_targets()
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if parser then parser:parse() end
  local node = parser and vim.treesitter.get_node()
  local win = vim.api.nvim_get_current_win()
  local top, bottom = vim.fn.line("w0"), vim.fn.line("w$")
  local targets, taken, seen = {}, {}, {}
  while node do
    local sr, sc, er, ec = node:range()
    if ec == 0 and er > sr then
      er = er - 1
      ec = #vim.fn.getline(er + 1)
    end
    ec = math.max(ec - 1, 0)
    local range = { sr, sc, er, ec }
    local id = table.concat(range, ":")
    for _, pos in ipairs(seen[id] and {} or { { sr, sc }, { er, ec } }) do
      local key = pos[1] .. ":" .. pos[2]
      if not taken[key] and pos[1] + 1 >= top and pos[1] + 1 <= bottom then
        taken[key] = true
        targets[#targets + 1] = { win = win, lnum = pos[1] + 1, col = pos[2], range = range }
        break
      end
    end
    seen[id] = true
    node = node:parent()
  end
  return targets
end

local function select_range(range, mode)
  if mode == "x" then vim.cmd("normal! \27") end
  vim.api.nvim_win_set_cursor(0, { range[1] + 1, range[2] })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { range[3] + 1, range[4] })
end

-- Label the syntax nodes around the cursor and select the chosen one.
local function jump_node()
  local mode, targets = current_mode(), node_targets()
  if #targets == 0 then
    vim.notify("No syntax node here", vim.log.levels.WARN)
    return nil
  end
  local target = targets[1]
  if #targets > 1 then
    assign(targets)
    target = pick(targets)
  end
  if not target then return nil end

  local nth = vim.fn.index(targets, target) + 1
  return function()
    select_range(target.range, mode)
    if mode ~= "o" then return end
    -- `.` takes the node as many levels out from the new cursor.
    last = function()
      local again = node_targets()[nth]
      if again then select_range(again.range, mode) end
    end
  end
end

-- Run the jump an operator is waiting on; with none waiting, this is `.`
-- repeating the previous one.
function M.apply()
  local act = pending or last
  pending = nil
  if act then act() end
end

-- Jump to a typed word in any split, start the cancelled operator again there
-- for the motion typed next, then return to where it began.
function M.remote()
  local op, reg = unpack(remote_op)
  local word = read_text("Remote word: ", nil, true)
  local act = word and run(finder(word, true))
  if not act then return end

  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local mark = vim.api.nvim_buf_set_extmark(buf, ns, cursor[1] - 1, cursor[2], {})
  act()
  vim.api.nvim_feedkeys('"' .. reg .. op, "n", false)
  -- Back in Normal mode the operator, and any insert it began, is over.
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*:n",
    once = true,
    callback = vim.schedule_wrap(function()
      local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark, {})
      vim.api.nvim_buf_del_extmark(buf, ns, mark)
      if pos[1] and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_set_current_win(win)
        vim.api.nvim_win_set_cursor(win, { pos[1] + 1, pos[2] })
      end
    end),
  })
end

-- Bind <leader>j{key} to a jump: `choose` shows the labels and returns the jump
-- as a function, or nil when cancelled.
local function map(key, choose, desc)
  vim.keymap.set({ "n", "x" }, "<leader>j" .. key, function()
    local act = choose()
    if act then act() end
  end, { desc = desc })
  -- After an operator, an expr mapping lets a cancelled jump cancel the operator too.
  vim.keymap.set("o", "<leader>j" .. key, function()
    pending = choose()
    return pending and "<Cmd>lua require('plugins.jump').apply()<CR>" or "<Esc>"
  end, { expr = true, desc = desc })
end

map("l", jump_line, "[J]ump to [L]ine")
map("w", jump_word, "[J]ump to [W]ord")
map("j", jump_word, "[J]ump to Word ([J])")
map("c", jump_char, "[J]ump to [C]haracter")
map("t", jump_chars, "[J]ump to [T]wo Characters")
map("s", jump_starts, "[J]ump to Word [S]tart")
map("d", jump_diagnostic, "[J]ump to [D]iagnostic")
map("n", jump_node, "[J]ump to Syntax [N]ode")
vim.keymap.set("n", "<leader>jW", jump_window, { desc = "[J]ump to [W]indow" })
-- The operator is cancelled here and started again at the target.
vim.keymap.set("o", "<leader>jr", function()
  remote_op = { vim.v.operator, vim.v.register }
  return "<Esc><Cmd>lua require('plugins.jump').remote()<CR>"
end, { expr = true, desc = "[J]ump [R]emote: Operate at a Word, Then Return" })

require("which-key").add({
  { "<leader>j", group = "[J]ump", mode = { "n", "x", "o" }, icon = { icon = "󰆾", color = "blue" } },
})

return M

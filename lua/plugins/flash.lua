-- Flash: labelled jumps and treesitter selection.
local flash = require("flash")

flash.setup({
  labels = "aoeuhtnsid", -- Dvorak home row only.
  label = { uppercase = false },
})

local autojump_ms = 1000 -- Idle milliseconds before jumping to a lone match.

-- flash.jump(), plus a jump to the only match once typing pauses.
local function jump()
  local state = require("flash.repeat").get_state("jump")
  local timer = assert(vim.uv.new_timer())
  local done = false
  local ns = vim.on_key(function()
    timer:start(autojump_ms, 0, vim.schedule_wrap(function()
      -- <CR> is flash's own "jump to the first match" key.
      if not done and #state.results == 1 then vim.api.nvim_input("<CR>") end
    end))
  end)
  local ok, err = pcall(state.loop, state)
  done = true
  vim.on_key(nil, ns)
  timer:close()
  if not ok then error(err, 0) end
end

vim.keymap.set({ "n", "x", "o" }, "s", jump, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function() flash.treesitter() end, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", function() flash.remote() end, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Treesitter Search" })
vim.keymap.set("c", "<C-s>", function() flash.toggle() end, { desc = "Toggle Flash Search" })

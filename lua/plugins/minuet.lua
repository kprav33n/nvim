-- Inline code completion with Claude. Off until the key file exists: chmod 600,
-- holding "x-api-key: <key>". curl reads it, so the key stays out of the
-- environment (Claude Code would inherit it) and out of process listings.
local key_file = vim.fs.normalize("~/.config/minuet/header")
if vim.fn.filereadable(key_file) == 0 then return end

local enabled = true

require("minuet").setup({
  provider = "claude",
  provider_options = {
    claude = {
      model = "claude-haiku-5-5",
      api_key = function() return "unused" end, -- Minuet requires a value.
      transform = {
        function(request)
          request.headers["x-api-key"] = nil -- Sent from key_file.
          return request
        end,
      },
      max_tokens = 256,
      stream = true, -- Keep partial text if the request times out.
      optional = {
        -- On by default, and would spend max_tokens before any code.
        thinking = { type = "disabled" },
        output_config = { effort = "low" },
        -- End after one suggestion; nothing shows until the reply completes.
        stop_sequences = { "<endCompletion>" },
      },
    },
  },
  curl_extra_args = { "-H", "@" .. key_file },
  enable_predicates = { function() return enabled end }, -- <A-]> ignores this.
  n_completions = 1,
  context_window = 8000, -- Characters around the cursor.
  -- Debounce alone paces requests; throttle drops triggers without retrying.
  debounce = 400,
  throttle = 0,
  virtualtext = {
    auto_trigger_ft = { "c", "cpp", "cuda", "python" },
    -- Otherwise blink's menu blocks suggestions.
    show_on_completion_menu = true,
    -- <Tab> also accepts (plugins/blink.lua). Single suggestion, so no prev.
    keymap = {
      accept = "<A-A>",
      accept_line = "<A-a>",
      accept_word = "<A-w>",
      next = "<A-]>", -- Requests a suggestion when none is shown.
      dismiss = "<A-e>",
    },
  },
})

-- All buffers, unlike minuet's own toggle. Back on after a restart.
vim.keymap.set("n", "<leader>at", function()
  enabled = not enabled
  vim.notify("Inline completion " .. (enabled and "on" or "off"))
end, { desc = "[A]I [T]oggle Inline Completion" })

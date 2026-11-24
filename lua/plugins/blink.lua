-- Configure blink completion engine.
require("blink.cmp").setup({
  completion = {
    documentation = {
      auto_show = true,
    },
    trigger = {
      prefetch_on_insert = false,
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  keymap = {
    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

    ['<C-y>'] = { 'select_and_accept', 'fallback' },
    ['<C-e>'] = { 'cancel', 'fallback' },
    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },

    ['<Tab>'] = {
      function()
        -- Not loaded without a key file (plugins/minuet.lua).
        local minuet = package.loaded["minuet.virtualtext"]
        if minuet and minuet.action.is_visible() then
          minuet.action.accept()
          return true
        end
        return false
      end,
      'snippet_forward',
      'fallback',
    },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  },

  fuzzy = {
    implementation = "lua",
  },
})

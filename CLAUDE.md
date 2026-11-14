# Neovim Configuration

Personal Neovim config targeting **Neovim 0.12**. Currently everything lives in a single `init.lua`; the plan is to modularize it (see below).

## Neovim 0.12 specifics

This config uses modern APIs available in 0.12. When suggesting changes, prefer these over legacy equivalents:

- **`vim.pack`** is the built-in plugin manager. No `lazy.nvim`, `packer`, or `vim-plug`. Plugins are declared with `vim.pack.add({ "https://github.com/owner/repo" }, { confirm = false })`. Versions are pinned in `nvim-pack-lock.json` (auto-managed — don't hand-edit).
- **`vim.diagnostic.config`** uses the new table form for signs (`signs = { text = { [severity] = "icon" } }`), not the deprecated `sign_define` calls.
- Built-in LSP client and `vim.lsp.completion` are available if LSP is added later; prefer these over `nvim-lspconfig` boilerplate where reasonable.
- `vim.keymap.set` and `vim.api.nvim_create_autocmd` are the canonical keymap/autocmd APIs.

## Current layout

```
init.lua                  -- everything (options, diagnostics, plugins, keymaps)
nvim-pack-lock.json       -- vim.pack lockfile (auto-managed)
claude/skills/neovim/     -- Claude Code skill for driving nvim over $NVIM;
                             symlinked from ~/.claude/skills/neovim
```

Installed plugins (via `vim.pack`): `nvim-treesitter`, `blink.cmp`, `plenary.nvim`, `nvim-web-devicons`, `telescope.nvim`, `which-key.nvim`.

**Note:** `catppuccin` is set as the colorscheme in `init.lua` but is **not** declared in the pack lockfile. It is either installed out-of-band or missing. When touching the colorscheme, verify it's actually present and add it to `vim.pack.add` if not.

## Target modular layout

When modularizing, follow this structure (standard Neovim Lua convention):

```
init.lua                       -- bootstrap: requires config + plugins
lua/
  config/
    options.lua                -- vim.opt, vim.g
    keymaps.lua                -- global keymaps (not plugin-specific)
    diagnostics.lua            -- vim.diagnostic.config
  plugins/
    init.lua                   -- single vim.pack.add for all sources, then require each module
    treesitter.lua
    blink.lua
    telescope.lua              -- includes its pickers + keymaps
    neo-tree.lua               -- file explorer + <leader>e keymaps
    lualine.lua                -- global statusline (catppuccin theme, gitsigns diff)
    claudecode.lua             -- Claude Code IDE integration + <leader>a keymaps
    jump.lua                   -- custom label jump (line/word/char) + <leader>j keymaps
    which-key.lua              -- includes group specs for other plugins
    colorscheme.lua            -- vim.cmd.colorscheme + (when added) catppuccin pack entry
```

Guidelines for the split:
- `init.lua` should be tiny — just `require("config.options")`, `require("config.keymaps")`, `require("config.diagnostics")`, `require("plugins")`.
- Keep plugin-specific keymaps inside the plugin's own module (e.g., telescope's `<leader>s*` bindings live in `plugins/telescope.lua`), not in `config/keymaps.lua`.
- Which-key group specs for a plugin also live in that plugin's module — call `require("which-key").add(...)` from there so the spec sits next to the bindings it describes.
- Prefer one `vim.pack.add` call in `plugins/init.lua` listing every source, then `require` each plugin module. This keeps network/install behavior predictable and makes the dependency set easy to audit.
- Don't introduce a plugin-spec abstraction layer. `vim.pack` is simple; keep it simple.

## Conventions

- **Leader:** `<Space>` (both `mapleader` and `maplocalleader`).
- **Indent:** 2 spaces, expandtab, `textwidth=80`.
- **Clipboard:** OSC52 (`vim.g.clipboard = 'osc52'`) — this config is expected to work over SSH, so don't replace with `xclip`/`wl-copy`-based providers without asking.
- **Search keymaps:** `<leader>s<key>` namespace, with `[S]earch [X]` descriptions so which-key renders them nicely. Keep this pattern for any new pickers.
- **Keymap descriptions:** always set `desc` on `vim.keymap.set` — which-key depends on it.
- **Comments:** the existing file uses short section-header comments (`-- Leader key.`, `-- Telescope fuzzy finder.`). Match that style when editing; don't write essays.

## Common tasks

- **Add a plugin:** append its URL to the `vim.pack.add` list, then write a setup module. Run `:checkhealth vim.pack` or restart nvim to install. The lockfile updates automatically.
- **Update plugins:** `:lua vim.pack.update()` (all) or pass names. Commit the lockfile change.
- **Remove a plugin:** delete from `vim.pack.add`, delete the setup module, then `:lua vim.pack.del({ "plugin-name" })` to clean the install.
- **Test changes:** reload with `:source %` for option/keymap tweaks; restart nvim for plugin changes.

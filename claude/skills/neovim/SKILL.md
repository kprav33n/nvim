---
name: neovim
description: Inspect or drive the user's running Neovim over RPC. Use when $NVIM is set (Claude Code runs inside a Neovim terminal) and the user asks to show something in their editor, e.g. put results in the quickfix list, list open or unsaved buffers, run an Ex command, or query editor state.
---

# Driving the parent Neovim

When Claude Code runs in a Neovim `:terminal`, `$NVIM` holds the socket of that
Neovim. Check it first; if it is empty, this skill does not apply.

```sh
[ -n "$NVIM" ] && echo "$NVIM"
```

## Commands

Evaluate a Vimscript expression and print the result. Always end with
`| cat` (or capture with `$(...)`): nvim only prints the result when stdout
is a pipe, and the Bash tool's stdout is not one.

```sh
nvim --server "$NVIM" --remote-expr 'getcwd()' | cat
```

Run Lua through `luaeval()`. Return JSON for anything structured, and pass
data in as the second argument (`_A` in Lua) instead of quoting it into the
code:

```sh
nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(_A)", {"k": 1})' | cat
```

Run an Ex command with `execute()`:

```sh
nvim --server "$NVIM" --remote-expr 'execute("checktime")'
```

## Recipes

Listed buffers with their unsaved state:

```sh
nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.tbl_map(function(b) return { name = b.name, changed = b.changed == 1 } end, vim.fn.getbufinfo({ buflisted = 1 })))")' | cat
```

Fill the quickfix list from `file:line:col: text` lines and show it without
taking focus from the terminal:

```sh
nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.setqflist({}, \" \", { title = _A.title, lines = _A.lines, efm = \"%f:%l:%c: %m\" })", {"title": "Claude", "lines": ["init.lua:1:1: example"]})'
nvim --server "$NVIM" --remote-expr 'execute("botright copen | wincmd p")'
```

## Rules

- Prefer `--remote-expr`. Use `--remote-send` only when keystrokes are the
  point; it types into whatever window has focus, usually this terminal.
- The current window is normally the Claude terminal, so `%` and
  `nvim_get_current_buf()` are not the user's file. Use the IDE selection
  context or `getbufinfo()` to find it.
- Do not change buffer text over RPC; use the normal edit tools so the user
  gets a diff.
- Never run commands that discard work or close the editor (`:q`, `:qa`,
  `:bd!`, `:e!`, `:%d`) unless the user asked for exactly that.
- Do not write unsaved buffers (`:w`, `:wa`) without being asked.

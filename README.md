# nvim-scratchpad

A Neovim plugin implementing a Scratchpad: create auto-named files in a global directory and run them in a terminal.

## Features

- **Auto-named scratch files** — Create files with auto-incrementing names (`scratch_1.js`, `scratch_2.py`, etc.) in a configurable global directory
- **Multiple filetypes** — Preconfigured for Lua, JavaScript, TypeScript, Python, Shell, Ruby, Markdown, JSON, and plain text
- **Run scripts** — Execute scratch files via custom commands (e.g., `node`, `python3`) in a reused terminal buffer
- **Browse and manage** — View all scratches with `:Scratches` (uses snacks.nvim picker if available, falls back to `vim.ui.select`)
- **Optional keymaps** — Suggested default keymaps for quick access
- **Soft dependency** — Works with or without folke/snacks.nvim for a nicer file picker

## Requirements

- Neovim >= 0.10
- Optional: [folke/snacks.nvim](https://github.com/folke/snacks.nvim) for a better picker (falls back to `vim.ui.select` if not installed)

## Installation

### lazy.nvim

```lua
{
  "lgoeckener/nvim-scratchpad",
  dependencies = { "folke/snacks.nvim" },
  opts = {}
}
```

Note: `folke/snacks.nvim` is optional. The plugin uses it for an enhanced file picker, but will gracefully fall back to `vim.ui.select` if it's not available.

## Configuration

The plugin uses sensible defaults. Override them in `opts`:

```lua
require("scratch").setup({
  dir = vim.fn.stdpath("data") .. "/scratch",      -- scratch directory
  default_keymaps = false,                          -- master switch for the keymaps below
  keys = {                                          -- per-action; override or set false to disable
    new    = "<leader>sn",                          -- :Scratch
    browse = "<leader>ss",                          -- :Scratches
    run    = "<leader>sr",                          -- :ScratchRun
  },
  filetypes = {
    lua        = { run = "lua" },
    javascript = { ext = "js",  run = "node" },
    typescript = { ext = "ts",  run = "node --experimental-strip-types" },
    python     = { ext = "py",  run = "python3" },
    sh         = { run = "bash" },
    ruby       = { ext = "rb",  run = "ruby" },
    markdown   = { ext = "md" },
    json       = {},
    text       = { ext = "txt" },
  }
})
```

**Config details:**

- `dir` — Where scratch files are stored (default: `~/.local/share/nvim/scratch`)
- `default_keymaps` — Master switch for the keymaps in `keys` (disabled by default)
- `keys` — Per-action keymaps used when `default_keymaps = true`. Override any single entry (the rest keep their defaults), or set one to `false` to skip just that mapping
- `filetypes` — Per-filetype config:
  - `ext` — File extension. Defaults to the filetype key when omitted (e.g., `lua` → `.lua`, `json` → `.json`)
  - `run` — Shell command to execute the file. The file path is appended to this command (e.g., `node` becomes `node /path/to/scratch_1.js`)

## Commands

- **`:Scratch [filetype]`** — Create a new scratch file. If no filetype is given, opens a picker to choose one
- **`:Scratches`** — Browse and open existing scratch files
- **`:ScratchRun`** — Run the current scratch file (only works on files inside the scratch directory)

## Keymaps

When `default_keymaps = true`, these keymaps are registered (all customizable via `keys`):

- **`<leader>sn`** — `:Scratch` — Create a new scratch
- **`<leader>ss`** — `:Scratches` — Browse scratches
- **`<leader>sr`** — `:ScratchRun` — Run current scratch

Each is overridable individually. For example, if `<leader>s` is already taken in your config,
remap or disable just the ones you need:

```lua
require("scratch").setup({
  default_keymaps = true,
  keys = {
    new    = "<leader>cn",  -- move "new" somewhere else
    run    = "<leader>cr",  -- move "run"
    browse = false,         -- disable this one; use :Scratches instead
  },
})
```

Or leave `default_keymaps = false` and map the commands yourself for full control.

## How it works

- **Flat global directory** — All scratch files live in a single directory (`dir` config option, default: `~/.local/share/nvim/scratch`)
- **Auto-increment naming** — Files are named `scratch_N.ext` where N is globally auto-incremented across all filetypes. The next index is computed by scanning the directory for the highest existing N
- **Terminal execution** — Scripts run in a reused terminal split at the bottom of the window. The terminal persists across multiple runs, making it easy to see output history
- **Scratch-only execution** — `:ScratchRun` only works on files inside the scratch directory; running it on other files will show an error
- **No in-plugin deletion** — The directory simply grows; manage files manually if needed

## Running tests

Run the test suite with:

```bash
make test
```

This launches Neovim in headless mode with plenary and runs all tests in `tests/`.

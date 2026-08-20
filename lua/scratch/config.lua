local M = {}

M.defaults = {
  dir = vim.fn.stdpath("data") .. "/scratch",
  default_keymaps = false,      -- master switch; when true, register the keys below
  -- Per-action keymaps. Override any single entry, or set one to false to skip it.
  keys = {
    new    = "<leader>sn",  -- :Scratch  (new scratch, opens filetype picker)
    browse = "<leader>ss",  -- :Scratches
    run    = "<leader>sr",  -- :ScratchRun
  },
  filetypes = {
    lua        = { run = "lua" },       -- system lua interpreter (plain shell; no Neovim API access)
    javascript = { ext = "js",  run = "node" },
    typescript = { ext = "ts",  run = "node --experimental-strip-types" },
    python     = { ext = "py",  run = "python3" },
    sh         = { run = "bash" },
    ruby       = { ext = "rb",  run = "ruby" },
    markdown   = { ext = "md" },        -- no run command (not executable)
    json       = {},                    -- ext defaults to "json"
    text       = { ext = "txt" },
  },
}

-- Deep copy helper for nested tables
local function deep_copy(tbl)
  if type(tbl) ~= "table" then
    return tbl
  end
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = deep_copy(v)
  end
  return copy
end

-- Initialize M.options with a deep copy of defaults
M.options = deep_copy(M.defaults)

-- Deep-merge user opts over defaults. User filetypes MERGE with (not replace) defaults:
-- a user entry for an existing key overrides that key; new keys are added.
-- Idempotent. Stores result in M.options and returns it.
function M.setup(opts)
  opts = opts or {}

  -- Merge top-level options (filetypes and keys are merged per-entry below)
  for key, value in pairs(opts) do
    if key ~= "filetypes" and key ~= "keys" then
      M.options[key] = value
    end
  end

  -- Merge filetypes: user entries override defaults, new entries are added
  if opts.filetypes then
    for ft, config in pairs(opts.filetypes) do
      M.options.filetypes[ft] = deep_copy(config)
    end
  end

  -- Merge keys: overriding one action keeps the other defaults. A value of
  -- false disables that action's keymap.
  if opts.keys then
    for action, lhs in pairs(opts.keys) do
      M.options.keys[action] = lhs
    end
  end

  return M.options
end

-- Return the config entry for a filetype, or nil if not configured.
function M.get(ft)
  return M.options.filetypes[ft]
end

-- Return the file extension for a filetype: entry.ext or the ft key itself. nil if unknown ft.
function M.ext_for(ft)
  local entry = M.get(ft)
  if entry == nil then
    return nil
  end
  return entry.ext or ft
end

-- Return a sorted array of configured filetype names (keys). Used to build the picker.
function M.filetype_names()
  local names = {}
  for ft in pairs(M.options.filetypes) do
    table.insert(names, ft)
  end
  table.sort(names)
  return names
end

return M

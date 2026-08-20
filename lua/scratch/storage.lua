local config = require("scratch.config")

local M = {}

-- PURE, testable without filesystem: given a list of basenames, return the next index.
-- Ignores names not matching `^scratch_(%d+)%.`. Returns 1 for an empty list.
function M.compute_next_index(names)
  local max_index = 0
  for _, name in ipairs(names) do
    local num = name:match("^scratch_(%d+)%.")
    if num then
      max_index = math.max(max_index, tonumber(num))
    end
  end
  return max_index + 1
end

-- Absolute path of the scratch dir (from config.options.dir).
function M.dir()
  return config.options.dir
end

-- Create the scratch dir if missing.
function M.ensure_dir()
  vim.fn.mkdir(M.dir(), "p")
end

-- List existing scratch files. Returns array of { path = <abs>, name = <basename> },
-- sorted by index ascending. Only files matching `^scratch_%d+%.`.
function M.list()
  local dir = M.dir()
  local names = vim.fn.readdir(dir)
  local entries = {}
  for _, name in ipairs(names) do
    local num = name:match("^scratch_(%d+)%.")
    if num then
      table.insert(entries, { path = dir .. "/" .. name, name = name, index = tonumber(num) })
    end
  end
  table.sort(entries, function(a, b)
    return a.index < b.index
  end)
  local result = {}
  for _, entry in ipairs(entries) do
    table.insert(result, { path = entry.path, name = entry.name })
  end
  return result
end

-- Create a new empty scratch file for filetype `ft`.
-- Returns the absolute path. Errors (error()) if ft has no known extension.
function M.create(ft)
  local ext = config.ext_for(ft)
  if ext == nil then
    error("scratch.storage: unknown filetype '" .. tostring(ft) .. "'")
  end

  M.ensure_dir()

  local dir = M.dir()
  local names = vim.fn.readdir(dir)
  local next_index = M.compute_next_index(names)
  local name = "scratch_" .. next_index .. "." .. ext
  local path = dir .. "/" .. name

  vim.fn.writefile({}, path)

  return path
end

-- Resolve `path` to its canonical real path, resolving symlinks. Falls back to
-- textual normalization (no symlink resolution) if the path doesn't exist on disk.
local function realpath(path)
  return vim.uv.fs_realpath(path) or vim.fn.fnamemodify(path, ":p")
end

-- True if `path` (absolute or the buffer name) resides directly in the scratch dir.
-- Compares canonical real paths so a symlinked ancestor (e.g. /tmp -> /private/tmp
-- on macOS) doesn't cause a false negative.
function M.is_scratch(path)
  if path == nil or path == "" then
    return false
  end
  local dir = realpath(M.dir()):gsub("/$", "")
  local file_dir = realpath(vim.fn.fnamemodify(path, ":p:h"))
  return file_dir == dir
end

return M

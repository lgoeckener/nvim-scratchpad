local config = require("scratch.config")
local storage = require("scratch.storage")

local M = {}

-- True if snacks.picker is loadable.
local function has_snacks()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks and snacks.picker ~= nil
end

-- Present the configured filetypes for selection. On choose, call on_choice(ft).
-- Always goes through vim.ui.select: if the user has snacks' `ui_select` config
-- enabled, snacks already replaces vim.ui.select globally, so this gets the
-- enhanced picker "for free" without depending on snacks.picker's private,
-- undocumented `select` internal (snacks docs: "not meant to be used directly").
function M.pick_filetype(on_choice)
  local names = config.filetype_names()

  vim.ui.select(names, { prompt = "Scratch filetype" }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

-- Present existing scratches (storage.list()) for selection. On choose, open the file.
-- snacks.picker with file preview if available, else vim.ui.select over basenames.
-- If the list is empty, notify "no scratches yet" and return.
function M.browse()
  local items = storage.list()

  if #items == 0 then
    vim.notify("No scratches yet")
    return
  end

  if has_snacks() then
    local ok = pcall(function()
      local snacks = require("snacks")
      snacks.picker.files({ cwd = storage.dir() })
    end)
    if ok then
      return
    end
  end

  local names = {}
  for _, item in ipairs(items) do
    table.insert(names, item.name)
  end

  vim.ui.select(names, { prompt = "Scratches" }, function(choice)
    if not choice then
      return
    end
    for _, item in ipairs(items) do
      if item.name == choice then
        vim.cmd.edit(vim.fn.fnameescape(item.path))
        return
      end
    end
  end)
end

return M

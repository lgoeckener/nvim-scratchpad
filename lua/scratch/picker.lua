local config = require("scratch.config")
local storage = require("scratch.storage")

local M = {}

-- True if snacks.picker is loadable.
local function has_snacks()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks and snacks.picker ~= nil
end

-- Blocking yes/no confirmation before an irreversible delete.
local function confirm_delete(name)
  return vim.fn.confirm("Delete " .. name .. "?", "&Yes\n&No", 2) == 1
end

-- snacks picker items' `file` is relative to the picker's `cwd` (here storage.dir()),
-- not necessarily absolute -- resolve it before treating it as a real path.
local function resolve_item_path(item)
  if not item or not item.file then
    return nil
  end
  if item.file:sub(1, 1) == "/" then
    return item.file
  end
  return storage.dir() .. "/" .. item.file
end

-- Confirm, then delete `path` via storage.delete, notifying on success/failure.
-- Returns true if the file was actually deleted.
local function delete_and_notify(path, name)
  if not confirm_delete(name) then
    return false
  end
  local ok, err = pcall(storage.delete, path)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return false
  end
  vim.notify("Deleted " .. name)
  return true
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
      snacks.picker.files({
        cwd = storage.dir(),
        actions = {
          delete_scratch = function(picker, item)
            local action_ok = pcall(function()
              local path = resolve_item_path(item)
              if path and delete_and_notify(path, vim.fn.fnamemodify(path, ":t")) then
                picker:refresh()
              end
            end)
            if not action_ok then
              vim.notify("scratch: delete action failed", vim.log.levels.ERROR)
            end
          end,
        },
        win = {
          input = { keys = { ["<c-x>"] = { "delete_scratch", mode = { "n", "i" } } } },
          list = { keys = { ["<c-x>"] = "delete_scratch" } },
        },
      })
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
        vim.ui.select({ "Open", "Delete" }, { prompt = choice }, function(action)
          if action == "Open" then
            vim.cmd.edit(vim.fn.fnameescape(item.path))
          elseif action == "Delete" then
            delete_and_notify(item.path, item.name)
          end
        end)
        return
      end
    end
  end)
end

return M

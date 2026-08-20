local M = {}

local function do_create(ft)
  local ok, path_or_err = pcall(function()
    return require("scratch.storage").create(ft)
  end)
  if not ok then
    vim.notify(path_or_err, vim.log.levels.ERROR)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(path_or_err))
end

-- Create a scratch of filetype `ft` and open it (vim.cmd.edit). If `ft` is nil,
-- open the filetype picker first, then create+open on choice.
function M.create(ft)
  if ft == nil or ft == "" then
    require("scratch.picker").pick_filetype(function(chosen)
      do_create(chosen)
    end)
  else
    do_create(ft)
  end
end

M.list = function() require("scratch.picker").browse() end
M.run = function() require("scratch.run").run() end

-- Merge config (config.setup), register user commands, and register keymaps when
-- options.default_keymaps is true. Idempotent.
function M.setup(opts)
  local options = require("scratch.config").setup(opts)

  vim.api.nvim_create_user_command("Scratch", function(args)
    local ft = args.args
    if ft == "" then
      ft = nil
    end
    M.create(ft)
  end, {
    nargs = "?",
    complete = function()
      return require("scratch.config").filetype_names()
    end,
  })

  vim.api.nvim_create_user_command("Scratches", function()
    M.list()
  end, {})

  vim.api.nvim_create_user_command("ScratchRun", function()
    M.run()
  end, {})

  if options.default_keymaps then
    local specs = {
      { action = "new", rhs = "<Cmd>Scratch<CR>", desc = "New scratch" },
      { action = "browse", rhs = "<Cmd>Scratches<CR>", desc = "Browse scratches" },
      { action = "run", rhs = "<Cmd>ScratchRun<CR>", desc = "Run scratch" },
    }
    for _, spec in ipairs(specs) do
      local lhs = options.keys[spec.action]
      -- A falsy or empty lhs disables that individual keymap.
      if lhs and lhs ~= "" then
        vim.keymap.set("n", lhs, spec.rhs, { desc = spec.desc })
      end
    end
  end
end

return M

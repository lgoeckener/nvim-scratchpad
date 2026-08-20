local scratch = require("scratch")

describe("default keymaps", function()
  it("applies an override, keeps other defaults, and skips a disabled action", function()
    -- Concrete leader so the default "<leader>s*" lhs resolve to a known prefix.
    vim.g.mapleader = ","
    scratch.setup({
      default_keymaps = true,
      keys = { new = "<F7>", run = false },
    })

    -- Overridden action maps to the new lhs.
    assert.are.equal(vim.fn.maparg("<F7>", "n"), "<Cmd>Scratch<CR>")
    -- Untouched action keeps its default lhs (",ss").
    assert.are.equal(vim.fn.maparg(",ss", "n"), "<Cmd>Scratches<CR>")
    -- Disabled action (false) registers no mapping at its default lhs (",sr").
    assert.are.equal(vim.fn.maparg(",sr", "n"), "")
  end)
end)

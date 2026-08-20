local run = require("scratch.run")

describe("run.build_command", function()
  it("appends a shell-escaped path containing a space", function()
    local path = "/a b/scratch_1.js"
    local expected = "node " .. vim.fn.shellescape(path)
    assert.equals(expected, run.build_command("node", path))
  end)

  it("appends a shell-escaped simple path", function()
    local path = "/tmp/scratch_1.js"
    local expected = "node " .. vim.fn.shellescape(path)
    assert.equals(expected, run.build_command("node", path))
  end)
end)

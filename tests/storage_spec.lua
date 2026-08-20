local storage = require("scratch.storage")

describe("storage.compute_next_index", function()
  it("returns max index plus one", function()
    local result = storage.compute_next_index({ "scratch_1.js", "scratch_2.py" })
    assert.equals(3, result)
  end)

  it("returns 1 for an empty list", function()
    local result = storage.compute_next_index({})
    assert.equals(1, result)
  end)

  it("ignores names not matching the scratch pattern", function()
    local result = storage.compute_next_index({ "scratch_1.js", "notes.md" })
    assert.equals(2, result)
  end)

  it("picks the max index, not the count", function()
    local result = storage.compute_next_index({ "scratch_5.js", "scratch_2.py" })
    assert.equals(6, result)
  end)
end)

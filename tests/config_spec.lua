local config = require("scratch.config")

describe("config", function()
  -- Isolate each test: setup() mutates the module-global M.options, so reset it
  -- to a pristine copy of the defaults before every scenario.
  before_each(function()
    config.options = vim.deepcopy(config.defaults)
  end)

  it("exposes defaults before setup is called", function()
    assert.are.equal(config.options.dir, config.defaults.dir)
    assert.are.equal(config.options.default_keymaps, config.defaults.default_keymaps)
    assert.are.same(config.options.filetypes.lua, config.defaults.filetypes.lua)
  end)

  it("overrides an existing filetype while keeping the other defaults", function()
    config.setup({ filetypes = { lua = { run = "custom_lua_runner" } } })

    assert.are.equal(config.options.filetypes.lua.run, "custom_lua_runner")
    assert.are.equal(config.options.filetypes.javascript.ext, "js")
    assert.are.equal(config.options.filetypes.python.ext, "py")
  end)

  it("adds a new user filetype without dropping defaults", function()
    config.setup({ filetypes = { go = { ext = "go", run = "go run" } } })

    assert.are.equal(config.options.filetypes.go.run, "go run")
    assert.are.equal(config.options.filetypes.lua.run, "lua")
  end)

  it("merges top-level options", function()
    config.setup({ dir = "/custom/scratch/dir", default_keymaps = true })

    assert.are.equal(config.options.dir, "/custom/scratch/dir")
    assert.are.equal(config.options.default_keymaps, true)
  end)

  it("ext_for returns the configured extension", function()
    assert.are.equal(config.ext_for("javascript"), "js")
  end)

  it("ext_for falls back to the filetype key when ext is omitted", function()
    assert.are.equal(config.ext_for("json"), "json")
  end)

  it("ext_for returns nil for an unknown filetype", function()
    assert.are.equal(config.ext_for("unknown_type"), nil)
  end)

  it("get returns nil for an unknown filetype", function()
    assert.are.equal(config.get("nonexistent"), nil)
  end)

  it("filetype_names returns all keys sorted", function()
    local names = config.filetype_names()
    local sorted = vim.deepcopy(names)
    table.sort(sorted)

    assert.are.same(names, sorted)
    assert.are.equal(#names, vim.tbl_count(config.defaults.filetypes))
  end)

  it("overriding one keymap keeps the other key defaults", function()
    config.setup({ keys = { new = "<leader>xn" } })

    assert.are.equal(config.options.keys.new, "<leader>xn")
    assert.are.equal(config.options.keys.browse, "<leader>ss")
    assert.are.equal(config.options.keys.run, "<leader>sr")
  end)

  it("filetype_names includes a newly added user filetype", function()
    config.setup({ filetypes = { rust = { ext = "rs", run = "rustc" } } })

    assert.is_true(vim.tbl_contains(config.filetype_names(), "rust"))
  end)

  it("setup is idempotent for the same input", function()
    config.setup({ filetypes = { clojure = { ext = "clj", run = "clj" } } })
    local first = config.ext_for("clojure")
    config.setup({ filetypes = { clojure = { ext = "clj", run = "clj" } } })

    assert.are.equal(config.ext_for("clojure"), first)
  end)
end)

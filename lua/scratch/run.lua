local M = {}

M._term = { win = nil, buf = nil }

-- PURE, testable: build the shell command string from a run cmd and a path.
function M.build_command(run_cmd, path)
  return run_cmd .. " " .. vim.fn.shellescape(path)
end

-- Stop the job of the previous scratch-run terminal buffer if it is still running,
-- so reusing (or replacing) the terminal never leaves an orphaned process behind.
local function stop_previous_job()
  local buf = M._term.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local job_id = vim.b[buf].terminal_job_id
  if not job_id then
    return
  end
  if vim.fn.jobwait({ job_id }, 0)[1] == -1 then
    vim.fn.jobstop(job_id)
  end
end

-- Run the given buffer's file (defaults to current buffer) in a reused terminal.
function M.run(bufnr)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  local path = vim.api.nvim_buf_get_name(bufnr)

  if not require("scratch.storage").is_scratch(path) then
    vim.notify("scratch.run: '" .. path .. "' is not inside the scratch dir", vim.log.levels.ERROR)
    return
  end

  local ft = vim.bo[bufnr].filetype
  local entry = require("scratch.config").get(ft)

  if not entry or not entry.run or entry.run == "" then
    vim.notify("scratch.run: no run command configured for filetype '" .. ft .. "'", vim.log.levels.WARN)
    return
  end

  if vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("write")
    end)
  end

  stop_previous_job()

  local cmd = M.build_command(entry.run, path)

  if M._term.win and vim.api.nvim_win_is_valid(M._term.win) then
    vim.api.nvim_set_current_win(M._term.win)
  else
    vim.cmd("botright split")
    vim.api.nvim_win_set_height(0, 15)
    M._term.win = vim.api.nvim_get_current_win()
  end

  vim.cmd("terminal " .. cmd)
  M._term.buf = vim.api.nvim_get_current_buf()
end

return M

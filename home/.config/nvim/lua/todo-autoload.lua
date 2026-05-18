local M = {}

M.watched_file = vim.fn.expand("~/Documents/TODO.md")
M._timer = nil

-- Trigger a disk-change check for the watched buffer. Notification is handled
-- by the FileChangedShellPost autocmd registered in setup().
function M.check_watched_file()
  local bufnr = vim.fn.bufnr(M.watched_file)
  if bufnr ~= -1 and vim.fn.bufloaded(bufnr) == 1 then
    vim.cmd("checktime " .. bufnr)
  end
end

function M.setup(opts)
  opts = opts or {}
  if opts.file then
    M.watched_file = vim.fn.expand(opts.file)
  end

  vim.o.autoread = true

  -- Stop any previously created timer so setup() is safe to call again.
  if M._timer then
    vim.fn.timer_stop(M._timer)
  end
  M._timer = vim.fn.timer_start(15000, function()
    M.check_watched_file()
  end, { ["repeat"] = -1 })

  vim.api.nvim_create_autocmd("FocusGained", {
    callback = M.check_watched_file,
  })

  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    callback = function(args)
      if vim.fn.expand(args.file) == M.watched_file then
        vim.notify("Reloaded: " .. args.file, vim.log.levels.INFO)
      end
    end,
  })
end

return M

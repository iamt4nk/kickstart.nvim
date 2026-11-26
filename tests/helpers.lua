-- Shared assertion and async helpers for the config test suite.
-- Every test file requires this and calls M.done() as its last statement.
local M = {}

local failures = {}
local checks = 0

---@param msg string
local function fail(msg) table.insert(failures, msg) end

---Assert two values are equal.
function M.eq(a, b, msg)
  checks = checks + 1
  if a ~= b then fail(('%s: expected %s, got %s'):format(msg, vim.inspect(b), vim.inspect(a))) end
end

---Assert a value is truthy.
function M.ok(v, msg)
  checks = checks + 1
  if not v then fail(('%s: expected truthy, got %s'):format(msg, vim.inspect(v))) end
end

---Normalize a keymap lhs the way Neovim stores it.
--- `<leader><S-w>l` is stored as " Wl", so comparing raw strings never matches.
--- Both the expected and actual values go through this.
---@param lhs string
---@return string
function M.normalize_lhs(lhs)
  lhs = lhs:gsub('<[lL]eader>', '<Space>')
  return vim.keycode(lhs)
end

---Assert a keymap exists for the given mode and left-hand side.
function M.has_keymap(mode, lhs)
  checks = checks + 1
  local want = M.normalize_lhs(lhs)
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if M.normalize_lhs(map.lhs) == want then return end
  end
  -- Buffer-local maps are not in nvim_get_keymap; check the current buffer too.
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    if M.normalize_lhs(map.lhs) == want then return end
  end
  fail(('missing keymap %s (normalized %q) in mode %s'):format(lhs, want, mode))
end

---Assert NO keymap exists for the given mode and lhs, or that it is an explicit no-op.
function M.no_keymap(mode, lhs)
  checks = checks + 1
  local want = M.normalize_lhs(lhs)
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if M.normalize_lhs(map.lhs) == want then
      -- An explicit unmap to '' is the intended representation here.
      if map.rhs == nil or map.rhs == '' then return end
      fail(('keymap %s in mode %s should be unmapped, found rhs=%s'):format(lhs, mode, vim.inspect(map.rhs)))
      return
    end
  end
end

---Scratch directory for test fixtures, created on demand.
---
---Deliberately OUTSIDE the config repo. Fixtures are intentionally misformatted
---so the formatter tests have something to change, and anything under the repo
---gets picked up by `stylua` -- including conform's stylua formatter, which
---honours .styluaignore and would then refuse to format the fixture at all.
---@return string
function M.tmpdir()
  local dir = vim.fn.stdpath 'cache' .. '/nvim-config-tests'
  vim.fn.mkdir(dir, 'p')
  return dir
end

---Open a file into the current buffer and fire filetype detection.
---@param path string
---@return integer bufnr
function M.open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.cmd 'filetype detect'
  return vim.api.nvim_get_current_buf()
end

---Block until a named LSP client attaches to a buffer.
---@param name string
---@param bufnr integer
---@param timeout integer? milliseconds, default 30000
---@return boolean attached
function M.wait_for_client(name, bufnr, timeout)
  return vim.wait(timeout or 30000, function() return #vim.lsp.get_clients { name = name, bufnr = bufnr } > 0 end, 250)
end

---Report results and exit with the right code. Must be the last call in a test file.
function M.done()
  if #failures == 0 then
    io.stdout:write(('  PASS (%d checks)\n'):format(checks))
    vim.cmd 'qa!'
  else
    for _, f in ipairs(failures) do
      io.stdout:write('  FAIL ' .. f .. '\n')
    end
    vim.cmd 'cq!'
  end
end

return M

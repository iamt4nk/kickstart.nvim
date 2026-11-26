-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

t.ok(package.loaded['dap'] ~= nil, 'nvim-dap should be loaded')
t.ok(package.loaded['dapui'] ~= nil, 'nvim-dap-ui should be loaded')

-- Guarded: a failed t.ok does not halt the file, so a bare require of an
-- uninstalled plugin would crash the whole test instead of reporting failures.
local has_dap, dap = pcall(require, 'dap')
t.ok(has_dap, 'dap should be requirable')

if has_dap then
  -- Python adapter.
  t.ok(dap.adapters.python ~= nil, 'python adapter')
  if dap.adapters.python then
    t.eq(dap.adapters.python.type, 'executable', 'python adapter type')
    t.eq(vim.inspect(dap.adapters.python.args), vim.inspect { '-m', 'debugpy.adapter' }, 'python adapter args')
    t.ok(vim.fn.executable(dap.adapters.python.command) == 1, 'python adapter command is executable')
  end

  -- Go adapter comes from nvim-dap-go.
  t.ok(dap.adapters.go ~= nil or dap.adapters.delve ~= nil, 'go/delve adapter')
end

-- Keymaps.
for _, k in ipairs { '<F5>', '<F6>', '<F7>', '<F8>', '<F9>' } do
  t.has_keymap('n', k)
end
t.has_keymap('n', '<Leader>b')
t.has_keymap('n', '<Leader>B')
t.has_keymap('n', '<Leader>gb')

-- Signs are defined with literal icons (no LazyVim).
t.ok(#vim.fn.sign_getdefined 'DapBreakpoint' > 0, 'DapBreakpoint sign defined')
t.ok(#vim.fn.sign_getdefined 'DapStopped' > 0, 'DapStopped sign defined')

-- LazyVim must be gone entirely.
t.ok(package.loaded['lazyvim'] == nil, 'lazyvim must not be loaded')
t.ok(package.loaded['lazyvim.util'] == nil, 'lazyvim.util must not be loaded')

t.done()

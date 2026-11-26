-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

-- No LazyVim anywhere.
t.ok(package.loaded['lazyvim'] == nil, 'lazyvim not loaded')
t.ok(vim.g.lazyvim_python_lsp == nil, 'lazyvim_python_lsp global removed')
t.ok(vim.g.lazyvim_python_ruff == nil, 'lazyvim_python_ruff global removed')

-- Old-style LSP keymaps must NOT be aliased back in.
for _, lhs in ipairs { 'gd', 'gI', '<leader>rn', '<leader>ca', '<leader>ds', '<leader>ws', '<leader>D' } do
  t.eq(vim.fn.maparg(t.normalize_lhs(lhs), 'n'), '', 'old keymap must be absent: ' .. lhs)
end

-- New-style LSP keymaps exist after an LSP attaches.
local tmp = t.tmpdir()
local f = tmp .. '/regress.odin'
vim.fn.writefile({ 'package main', '', 'main :: proc() {', '}' }, f)
local buf = t.open(f)
t.ok(t.wait_for_client('ols', buf), 'ols attached for keymap check')
for _, lhs in ipairs { 'grn', 'gra', 'grr', 'gri', 'grd', 'grt' } do
  t.ok(vim.fn.maparg(lhs, 'n', false, true).buffer == 1, 'buffer-local LSP keymap: ' .. lhs)
end

-- ruff log is outside the config directory.
local ruff_cfg = vim.lsp.config['ruff']
t.ok(not ruff_cfg.init_options.settings.logFile:match(vim.fn.stdpath 'config'), 'ruff log must not live in the config dir')

-- No vendored virtualenv.
t.eq(vim.fn.isdirectory(vim.fn.stdpath 'config' .. '/python'), 0, 'no python/ dir in config')

-- Upstream's optional example modules stay on disk but must never be loaded.
t.eq(vim.fn.filereadable(vim.fn.stdpath 'config' .. '/lua/kickstart/plugins/neo-tree.lua'), 1, 'kickstart examples kept on disk')
for _, mod in ipairs {
  'kickstart.plugins.neo-tree',
  'kickstart.plugins.lint',
  'kickstart.plugins.debug',
  'kickstart.plugins.autopairs',
  'kickstart.plugins.indent_line',
} do
  t.ok(package.loaded[mod] == nil, mod .. ' must stay unloaded')
end

-- Our explicit loader replaced upstream's directory globber.
t.eq(vim.fn.isdirectory(vim.fn.stdpath 'config' .. '/lua/custom/plugins'), 0, 'upstream custom/plugins globber removed')

t.done()

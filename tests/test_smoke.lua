-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

-- The custom loader ran and every module in the documented order is loaded.
for _, mod in ipairs { 'options', 'keymaps', 'ui', 'lsp', 'completion', 'format', 'debug', 'treesitter', 'autocmds', 'plugins' } do
  t.ok(package.loaded['custom.' .. mod] ~= nil, 'module custom.' .. mod .. ' should be loaded')
end

t.done()

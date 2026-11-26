-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

-- Colorscheme.
t.eq(vim.g.colors_name, 'cyberdream', 'colorscheme')

-- Plugins are loaded and configured.
t.ok(package.loaded['oil'] ~= nil, 'oil should be loaded')
t.ok(package.loaded['nvim-highlight-colors'] ~= nil, 'nvim-highlight-colors should be loaded')
t.ok(pcall(require, 'dashboard'), 'dashboard should be requirable')

-- oil replaces netrw as the default file explorer.
t.eq(require('oil.config').default_file_explorer, true, 'oil is default file explorer')

-- oil's custom keymap set: use_default_keymaps = false means only ours exist.
local oil_keys = require('oil.config').keymaps
t.ok(oil_keys['-'] ~= nil, 'oil parent-dir keymap')
t.ok(oil_keys['g?'] ~= nil, 'oil help keymap')
t.ok(oil_keys['g\\'] ~= nil, 'oil trash keymap')

-- highlight-colors exposes the format() entry point that lua/custom/completion.lua
-- calls from blink's kind_icon component. Assert the contract, not internal state.
t.eq(type(require('nvim-highlight-colors').format), 'function', 'highlight-colors format()')

t.done()

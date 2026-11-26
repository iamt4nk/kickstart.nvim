-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

-- Window splits.
t.has_keymap('n', '<Leader><S-W>l')
t.has_keymap('n', '<Leader><S-W>j')

-- LSP client inspector.
t.has_keymap('n', '<Leader>lc')

-- Arrow key nags.
for _, k in ipairs { '<Left>', '<Right>', '<Up>', '<Down>' } do
  t.has_keymap('n', k)
end

-- <C-Space> is reserved for tmux and must not be bound in insert or normal mode.
t.no_keymap('i', '<C-Space>')
t.no_keymap('n', '<C-Space>')

-- Upstream LSP defaults must survive; old-style aliases must NOT exist.
t.ok(vim.fn.maparg('gd', 'n') == '', 'gd should not be mapped globally')

t.done()

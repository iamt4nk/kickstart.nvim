-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

t.eq(vim.o.relativenumber, true, 'relativenumber')
t.eq(vim.o.number, true, 'number')
t.eq(vim.o.scrolloff, 10, 'scrolloff')
t.eq(vim.o.undofile, true, 'undofile')
t.eq(vim.o.splitright, true, 'splitright')
t.eq(vim.o.splitbelow, true, 'splitbelow')
t.eq(vim.g.have_nerd_font, true, 'have_nerd_font')

-- Custom listchars: a two-space tab, not upstream's '» '.
t.eq(vim.opt.listchars:get().tab, '  ', 'listchars.tab')
t.eq(vim.opt.listchars:get().trail, '·', 'listchars.trail')
t.eq(vim.opt.listchars:get().nbsp, '␣', 'listchars.nbsp')

-- WSL clipboard provider. Guarded: a failed t.ok does not halt the file, so
-- dereferencing an unset vim.g.clipboard would crash the whole test.
t.ok(vim.g.clipboard ~= nil, 'g.clipboard should be set under WSL')
if vim.g.clipboard then
  t.eq(vim.g.clipboard.name, 'WslClipboard', 'clipboard provider name')
  t.eq(vim.g.clipboard.copy['+'][1], 'win32yank.exe', 'clipboard copy command')
end

t.done()

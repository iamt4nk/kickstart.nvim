-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

t.ok(package.loaded['blink.cmp'] ~= nil, 'blink.cmp should be loaded')

local cfg = require 'blink.cmp.config'

-- <C-space> must be cleared; docs moved to <C-d>.
local keymap = cfg.keymap
t.ok(keymap['<C-space>'] == nil or vim.tbl_isempty(keymap['<C-space>'] or {}), '<C-space> must be cleared in blink')
t.ok(keymap['<C-d>'] ~= nil, '<C-d> should show documentation')

-- Sources.
t.ok(vim.tbl_contains(cfg.sources.default, 'lsp'), 'lsp source')
t.ok(vim.tbl_contains(cfg.sources.default, 'path'), 'path source')
t.ok(vim.tbl_contains(cfg.sources.default, 'snippets'), 'snippets source')

-- nvim-highlight-colors integration is wired into the menu draw.
-- NOTE: blink ships a DEFAULT kind_icon component with text/highlight functions,
-- so merely asserting they exist proves nothing. Drive them with a synthetic LSP
-- colour item and assert the swatch actually comes back.
local kind_icon = cfg.completion.menu.draw.components.kind_icon
t.ok(type(kind_icon) == 'table' and type(kind_icon.text) == 'function', 'kind_icon.text is a function')
t.ok(type(kind_icon.highlight) == 'function', 'kind_icon.highlight is a function')

local color_ctx = {
  kind_icon = 'I',
  icon_gap = '',
  kind = 'Color',
  item = { source_name = 'LSP', documentation = '#ff0000' },
}
local plain_ctx = {
  kind_icon = 'I',
  icon_gap = '',
  kind = 'Color',
  item = { source_name = 'Path', documentation = '#ff0000' },
}
local color_text = kind_icon.text(color_ctx)
local plain_text = kind_icon.text(plain_ctx)
t.eq(plain_text, 'I', 'non-LSP item falls through to the default kind icon')
t.ok(color_text ~= 'I', 'LSP colour item renders a swatch, not the default icon (got ' .. vim.inspect(color_text) .. ')')
t.ok(kind_icon.highlight(color_ctx) ~= 'BlinkCmpKindColor', 'LSP colour item gets a colour highlight group')

-- The global keymap must still be free for tmux.
t.no_keymap('i', '<C-Space>')

t.done()

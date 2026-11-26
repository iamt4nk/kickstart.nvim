-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

local installed = require('nvim-treesitter').get_installed 'parsers'

for _, lang in ipairs { 'odin', 'go', 'gomod', 'gowork', 'gosum', 'python', 'json', 'yaml', 'templ', 'lua', 'bash', 'markdown' } do
  t.ok(vim.tbl_contains(installed, lang), 'parser installed: ' .. lang)
end

-- Dropped languages.
t.ok(not vim.tbl_contains(installed, 'terraform'), 'terraform parser should not be requested')

-- Highlighting actually attaches to an Odin buffer.
local tmp = t.tmpdir()
local f = tmp .. '/ts.odin'
vim.fn.writefile({ 'package main', '', 'main :: proc() {', '}' }, f)
local buf = t.open(f)
vim.wait(5000, function() return vim.treesitter.highlighter.active[buf] ~= nil end, 100)
t.ok(vim.treesitter.highlighter.active[buf] ~= nil, 'treesitter highlighter attached to odin buffer')

t.done()

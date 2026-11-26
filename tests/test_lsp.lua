-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

local tmp = t.tmpdir()

-- Every server we expect must be enabled.
-- NOTE: check vim.lsp.is_enabled, NOT `vim.lsp.config[name] ~= nil` -- the latter
-- is non-nil for every server nvim-lspconfig ships an lsp/*.lua file for, which is
-- essentially all of them, making the assertion vacuous.
for _, name in ipairs { 'gopls', 'pyright', 'ruff', 'lua_ls', 'jsonls', 'html', 'templ', 'tailwindcss', 'htmx', 'ols' } do
  t.ok(vim.lsp.is_enabled(name), 'server enabled: ' .. name)
end

-- Dropped servers must NOT be enabled.
t.ok(not vim.lsp.is_enabled 'terraformls', 'terraformls should not be enabled')

-- tmpl maps to templ.
t.eq(vim.filetype.match { filename = 'x.tmpl' }, 'templ', 'tmpl filetype')

-- Odin is detected natively.
t.eq(vim.filetype.match { filename = 'x.odin' }, 'odin', 'odin filetype')

-- ols actually attaches to an Odin buffer.
local odin = tmp .. '/main.odin'
vim.fn.writefile({ 'package main', '', 'import "core:fmt"', '', 'main :: proc() {', '\tfmt.println("hi")', '}' }, odin)
local buf = t.open(odin)
t.eq(vim.bo[buf].filetype, 'odin', 'odin buffer filetype')
t.ok(t.wait_for_client('ols', buf), 'ols should attach to an .odin buffer')

-- ruff attaches to Python but does not answer hover (pyright does).
local py = tmp .. '/sample.py'
vim.fn.writefile({ 'import os', '', 'def f( x ):', '    return os.path.join(x)' }, py)
local pybuf = t.open(py)
t.ok(t.wait_for_client('ruff', pybuf), 'ruff should attach to a .py buffer')
local ruff = vim.lsp.get_clients({ name = 'ruff', bufnr = pybuf })[1]
t.ok(ruff and not ruff.server_capabilities.hoverProvider, 'ruff hover must be disabled')

t.done()

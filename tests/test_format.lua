-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

local conform = require 'conform'
local tmp = t.tmpdir()

-- Formatter assignments.
t.eq(vim.inspect(conform.formatters_by_ft.odin), vim.inspect { 'odinfmt' }, 'odin formatter')
t.eq(vim.inspect(conform.formatters_by_ft.lua), vim.inspect { 'stylua' }, 'lua formatter')
t.eq(vim.inspect(conform.formatters_by_ft.go), vim.inspect { 'goimports', 'gofumpt' }, 'go formatters')
t.eq(vim.inspect(conform.formatters_by_ft.python), vim.inspect { 'ruff_format' }, 'python formatter')
t.eq(vim.inspect(conform.formatters_by_ft.templ), vim.inspect { 'templ' }, 'templ formatter')

-- Terraform must be gone.
t.ok(conform.formatters_by_ft.terraform == nil, 'terraform formatter should not exist')
t.ok(conform.formatters_by_ft.hcl == nil, 'hcl formatter should not exist')

---Write a deliberately misformatted file, format it, and assert the buffer changed.
local function assert_formats(name, lines)
  local path = tmp .. '/' .. name
  vim.fn.writefile(lines, path)
  local buf = t.open(path)
  local before = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  conform.format { bufnr = buf, async = false, timeout_ms = 15000, lsp_format = 'fallback' }
  local after = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  t.ok(before ~= after, name .. ' should be reformatted (before == after means the formatter did not run)')
end

assert_formats('fmt.odin', { 'package main', '', 'main::proc(){', 'x:=1', '}' })
assert_formats('fmt.lua', { 'local   x =    1', 'print(  x  )' })
assert_formats('fmt.py', { 'def  f( x ):', '    return    x' })

t.done()

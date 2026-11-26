-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

local tmp = t.tmpdir()

-- User commands.
local cmds = vim.api.nvim_get_commands {}
t.ok(cmds['FormatKroger'] ~= nil, 'FormatKroger command')
t.ok(cmds['FormatSamsClub'] ~= nil, 'FormatSamsClub command')

-- Python indentation.
local py = tmp .. '/indent.py'
vim.fn.writefile({ 'x = 1' }, py)
local pybuf = t.open(py)
t.eq(vim.bo[pybuf].shiftwidth, 4, 'python shiftwidth')
t.eq(vim.bo[pybuf].tabstop, 4, 'python tabstop')
t.eq(vim.bo[pybuf].expandtab, true, 'python expandtab')

-- HTML indentation.
local html = tmp .. '/indent.html'
vim.fn.writefile({ '<div></div>' }, html)
local htmlbuf = t.open(html)
t.eq(vim.bo[htmlbuf].shiftwidth, 2, 'html shiftwidth')
t.eq(vim.bo[htmlbuf].expandtab, true, 'html expandtab')

-- .whitesource is json.
local ws = tmp .. '/.whitesource'
vim.fn.writefile({ '{}' }, ws)
local wsbuf = t.open(ws)
t.eq(vim.bo[wsbuf].filetype, 'json', 'whitesource filetype')
t.eq(vim.bo[wsbuf].shiftwidth, 2, 'whitesource shiftwidth')

-- JSON indentation.
local js = tmp .. '/indent.json'
vim.fn.writefile({ '{}' }, js)
local jsbuf = t.open(js)
t.eq(vim.bo[jsbuf].shiftwidth, 2, 'json shiftwidth')

-- Python indentation must NOT have leaked into the json buffer. The old config
-- used `set shiftwidth=4` on BufWinEnter, which is global, not buffer-local.
t.eq(vim.bo[pybuf].shiftwidth, 4, 'python buffer still 4 after opening others')

-- Odin autosave. ols only sees changes that reached disk, so leaving insert
-- mode has to flush the buffer.
local odin = tmp .. '/autosave.odin'
vim.fn.writefile({ 'package main' }, odin)
local odinbuf = t.open(odin)
vim.api.nvim_buf_set_lines(odinbuf, -1, -1, false, { 'x := 1' })
t.eq(vim.bo[odinbuf].modified, true, 'odin buffer dirty before InsertLeave')
vim.api.nvim_exec_autocmds('InsertLeave', { buffer = odinbuf })
t.eq(vim.bo[odinbuf].modified, false, 'odin buffer written on InsertLeave')
t.eq(#vim.fn.readfile(odin), 2, 'odin autosave reached disk')

-- An unnamed buffer must not raise E32 when the autocmd fires.
local scratch = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { 'package main' })
local okay = pcall(vim.api.nvim_exec_autocmds, 'InsertLeave', { buffer = scratch })
t.ok(okay, 'InsertLeave on a nameless buffer does not error')

-- The old config referenced an undefined global here; make sure it is gone.
t.ok(_G.load_launch_json == nil, 'no stray global load_launch_json')

t.done()

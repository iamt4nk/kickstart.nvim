-- Editor options. See lua/custom/init.lua for load-order notes.
-- Upstream init.lua already sets number, mouse, ignorecase, updatetime and friends;
-- only the deltas live here.

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- Render tabs as two spaces rather than upstream's '» '.
vim.opt.listchars = { tab = '  ', trail = '·', nbsp = '␣' }

-- Under WSL, route the system clipboard through win32yank so yanks reach Windows.
-- `--crlf` on copy and `--lf` on paste keep line endings sane across the boundary.
-- The command values are lists, not strings: a string forces a shell round-trip
-- on every yank.
if vim.fn.has 'wsl' == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = { 'win32yank.exe', '-i', '--crlf' },
      ['*'] = { 'win32yank.exe', '-i', '--crlf' },
    },
    paste = {
      ['+'] = { 'win32yank.exe', '-o', '--lf' },
      ['*'] = { 'win32yank.exe', '-o', '--lf' },
    },
    cache_enabled = 0,
  }
end

-- NOTE: loaded via dofile, not require. `require 'tests.helpers'` collides with
-- telescope.nvim, which ships its own lua/tests/helpers.lua on the runtimepath.
local t = dofile(vim.fn.stdpath 'config' .. '/tests/helpers.lua')

-- markdown-preview, with auto-start on (deliberate user choice).
t.eq(vim.g.mkdp_auto_start, 1, 'markdown-preview auto start')
t.eq(vim.g.mkdp_theme, 'dark', 'markdown-preview theme')

-- smm.nvim from GitHub, not the local dev checkout.
local has_smm = pcall(require, 'smm')
t.ok(has_smm, 'smm should be requirable')

-- The config schema must be the current flat form (playback.playback_pos),
-- not the old nested playback.interface.* that nvim-bak used.
if has_smm then
  local smm_config = require 'smm.config'
  local resolved = smm_config.get and smm_config.get() or nil
  if resolved then
    t.eq(resolved.playback.playback_pos, 'BottomRight', 'smm playback position')
    t.eq(resolved.playback.progress_bar_width, 38, 'smm progress bar width')
    t.eq(resolved.icons, true, 'smm icons at top level')
  end
end

-- Dropped plugins must be absent.
for _, mod in ipairs { 'lazyvim', 'lint', 'neotest', 'neo-tree' } do
  t.ok(package.loaded[mod] == nil, mod .. ' must not be loaded')
end

t.done()

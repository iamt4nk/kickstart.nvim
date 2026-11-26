-- Remaining plugins. See lua/custom/init.lua for load-order notes.

local function gh(repo) return 'https://github.com/' .. repo end

-- [[ Markdown preview ]]
-- Must be set before the plugin loads.
vim.g.mkdp_auto_start = 1
vim.g.mkdp_theme = 'dark'

-- markdown-preview ships a Node app that needs installing after download.
-- Under lazy.nvim this was a `build` hook; with vim.pack it is a PackChanged handler.
--
-- This MUST be registered before vim.pack.add: PackChanged fires synchronously
-- during the add, so registering afterwards misses the install event entirely.
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('custom-mkdp-build', { clear = true }),
  callback = function(ev)
    if ev.data.spec.name ~= 'markdown-preview.nvim' then return end
    if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end
    vim.fn['mkdp#util#install']()
  end,
})

vim.pack.add { gh 'iamcco/markdown-preview.nvim' }

-- [[ Spotify ]]
-- Local development happens in ~/.config/nvim_dev, which overrides the source there.
vim.pack.add { gh 'iamt4nk/smm.nvim' }

-- smm.nvim ships plugin/smm.lua, which calls `require('smm').setup()` with NO
-- arguments. Neovim sources plugin/ scripts AFTER init.lua finishes, so that call
-- would clobber the config below with pure defaults. lazy.nvim hid this; vim.pack
-- does not. Claiming the plugin's own guard flag makes plugin/smm.lua return early.
vim.g.loaded_smm = 1

-- NOTE: the config schema here is the current flat form. nvim-bak used an older
-- nested `playback.interface.{playback_pos,...}` layout with `icons` inside it;
-- those keys are silently ignored by the current plugin.
---@type SMM_Config
require('smm').setup {
  premium = true,
  icons = true,

  playback = {
    playback_pos = 'BottomRight',
    playback_width = 45,
    progress_bar_width = 38,
  },

  spotify = {
    auth = {
      client_id = 'c43057d088204249bca8d5bde4e93bd3',
      callback_url = 'http://127.0.0.1',
      callback_port = 8080,
    },
  },
}

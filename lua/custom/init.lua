-- Personal configuration, loaded from the bottom of init.lua.
--
-- The order below is load-bearing in three places:
--   * `ui` installs nvim-highlight-colors, which `completion` draws with
--   * `format` installs conform, whose format-on-save the odin autosave in `autocmds` triggers
--   * `options` runs first so nothing races the editor-level settings
--
-- Several of these modules call `setup()` on a plugin that upstream's init.lua
-- already configured (conform, treesitter). That is intentional and idempotent:
-- the call here supplies the full desired config and wins.
--
-- blink.cmp is the exception. It guards setup with `if has_setup then return end`,
-- so a second call does nothing. `custom.completion` therefore only RETURNS its
-- config and is consumed directly by init.lua's SECTION 8; the require below is
-- a cache hit kept for completeness.
require 'custom.options'
require 'custom.keymaps'
require 'custom.ui'
require 'custom.lsp'
require 'custom.completion'
require 'custom.format'
require 'custom.debug'
require 'custom.treesitter'
require 'custom.autocmds'
require 'custom.plugins'

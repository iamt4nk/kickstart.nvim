-- Completion. See lua/custom/init.lua for load-order notes.
--
-- Unlike the other custom modules, this one RETURNS its config rather than
-- applying it. blink.cmp guards setup with `if has_setup then return end`, so a
-- second setup() call from the custom layer is a silent no-op. init.lua's
-- SECTION 8 therefore does `require('blink.cmp').setup(require 'custom.completion')`
-- and all the actual configuration still lives here.
--
-- The `<C-Space>` tmux reservation is NOT re-asserted here: this module is
-- required early (from SECTION 8), before blink installs its own keymaps.
-- lua/custom/keymaps.lua loads at the very end of init.lua and owns that.

return {
  keymap = {
    preset = 'default',
    -- The default preset binds <C-space> to show-menu/show-docs, but that key is
    -- reserved as the tmux prefix (see lua/custom/keymaps.lua). Clear it and put
    -- documentation on <C-d> instead.
    ['<C-space>'] = {},
    ['<C-d>'] = { 'show_documentation', 'hide_documentation' },
  },

  appearance = {
    -- 'mono' for 'Nerd Font Mono', aligns the icon column.
    nerd_font_variant = 'mono',
  },

  completion = {
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
    menu = {
      draw = {
        components = {
          -- Render a colour swatch instead of the generic kind icon when the
          -- completion item is itself a colour. Recipe from nvim-highlight-colors.
          -- nvim-highlight-colors is required lazily, at draw time, so this module
          -- can safely load before lua/custom/ui.lua installs it.
          kind_icon = {
            text = function(ctx)
              local icon = ctx.kind_icon
              if ctx.item.source_name == 'LSP' then
                local color_item = require('nvim-highlight-colors').format(ctx.item.documentation, { kind = ctx.kind })
                if color_item and color_item.abbr ~= '' then icon = color_item.abbr end
              end
              return icon .. ctx.icon_gap
            end,
            highlight = function(ctx)
              local highlight = 'BlinkCmpKind' .. ctx.kind
              if ctx.item.source_name == 'LSP' then
                local color_item = require('nvim-highlight-colors').format(ctx.item.documentation, { kind = ctx.kind })
                if color_item and color_item.abbr_hl_group then highlight = color_item.abbr_hl_group end
              end
              return highlight
            end,
          },
        },
      },
    },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets' },
  },

  snippets = { preset = 'luasnip' },

  -- Lua matcher: avoids downloading a prebuilt rust binary.
  fuzzy = { implementation = 'lua' },

  -- Signature help while typing arguments.
  signature = { enabled = true },
}

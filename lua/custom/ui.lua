-- Theme, dashboard and file explorer. See lua/custom/init.lua for load-order notes.
-- The colorscheme is applied before dashboard is configured, because the
-- dashboard header override references the tokyonight palette.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'folke/tokyonight.nvim', -- already added by init.lua; listed so this file stands alone
  gh 'nvimdev/dashboard-nvim',
  gh 'stevearc/oil.nvim',
  gh 'brenoprata10/nvim-highlight-colors',
}

-- [[ Colorscheme ]]
-- Tokyo Night (night) to match the desktop rice / kitty theme.conf. This
-- re-runs tokyonight's setup (it is idempotent) with the full desired config,
-- overriding upstream init.lua's.
require('tokyonight').setup {
  style = 'night',
  -- Let kitty's translucency + picom blur show through
  transparent = true,
  terminal_colors = true,
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    sidebars = 'transparent', -- help, qf, etc.
    floats = 'dark', -- #16161e popups, same as the rofi menus
  },
  on_highlights = function(hl, c)
    hl.DashboardHeader = { fg = c.blue, bg = 'NONE' }
    -- Keep line numbers readable on a see-through background
    hl.CursorLineNr = { fg = c.orange, bold = true }
    hl.LineNr = { fg = c.comment }
  end,
}
vim.cmd.colorscheme 'tokyonight-night'

-- [[ Inline colour swatches ]]
require('nvim-highlight-colors').setup {
  ---@usage 'background'|'foreground'|'virtual'
  render = 'virtual',
  virtual_symbol = '■',
  virtual_symbol_prefix = '',
  virtual_symbol_suffix = ' ',
  virtual_symbol_position = 'inline',
  enable_tailwind = true,
}

-- [[ File explorer ]]
-- oil edits directories as buffers. use_default_keymaps = false means the table
-- below is the complete set.
require('oil').setup {
  default_file_explorer = true,
  columns = { 'icon', 'permissions' },
  buf_options = {
    buflisted = true,
    bufhidden = 'hide',
  },
  skip_confirm_for_simple_edits = true,
  cleanup_delay_ms = 2000,
  view_options = {
    show_hidden = true,
    is_always_hidden = function(name, _) return name == '.' or name == '..' end,
    case_insensitive = true,
    sort = {
      { 'type', 'asc' },
      { 'name', 'asc' },
    },
  },
  use_default_keymaps = false,
  keymaps = {
    ['g?'] = { 'actions.show_help', mode = 'n' },
    ['<CR>'] = 'actions.select',
    ['<C-t>'] = { 'actions.select', opts = { tab = true } },
    ['<C-c>'] = { 'actions.close', mode = 'n' },
    ['-'] = { 'actions.parent', mode = 'n' },
    ['_'] = { 'actions.open_cwd', mode = 'n' },
    ['`'] = { 'actions.cd', mode = 'n' },
    ['~'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
    ['gs'] = { 'actions.change_sort', mode = 'n' },
    ['gx'] = 'actions.open_external',
    ['g.'] = { 'actions.toggle_hidden', mode = 'n' },
    ['g\\'] = { 'actions.toggle_trash', mode = 'n' },
  },
}

-- [[ Start screen ]]
local logo = {
  '                                                   ▊                                                                         ',
  '                                                   ▊                                                                         ',
  '                                                   ▊                                                                         ',
  '                                                   ▊          ▎▉▉▊▍                                                          ',
  '                                                   ▉    ▂▅▌▊▊▊▃██▇▂                                                          ',
  '                                                   ▂▏  ▁███▆▆█▇██▂▎▎  ▎▃▆▆▌                                                  ',
  '                                                   █▆▆▃█████████████████▇█▅▄▂▁▁▁  ▏                                          ',
  '                                         ▄▇████▇███████████████▆████▇▆█▅▅▇█▅▆█▅████▇▃▁                                       ',
  '                                         ▌███████████████████████████████████▆███████████████████▇█████████████▆▅▄▄▅███▇█▄▇▅▇',
  '                                          ▅█████████████████████▇███████████████████▇▇▊                                      ',
  '                                                ▄▅▅▅▅▇██████████████████████████▇▆▃▊                                         ',
  '                          ▍▁▃▃▄▄▄▂▂▃▃▅▅▅▅▅▅▅▅▅▅▅▅▅▅▃▁▂▆████████████████████████▇▂▄▃▃▃▉▃▃▋▃▂                                  ',
  '                         ▄████████▆▇█████████████████▇███████████████▇█████████████████████▅█▆▅▄                             ',
  '                         ████████████████████████████▇██████████████████████████████████████████▄▅▅▅▅▅▅▄▁                    ',
  '                         ▅▆▆▆▆▆▆▆▇▇▇▇▇▆▇▇▇▇▇▇▇▆▆▇▇▇▇▇▆▆▆▆▆▆▆▆▆▆▇▆▆▆▆▆▆▆▇▇▇▇▆▇▆▆▆▆▆▆▆▆▆▆▆▇▇▇▇▇▇▇▇▇▇▇▇██████▊                  ',
  '                         ▅██████████████████████████████████████████████████████████████████████████████▆▎                   ',
  '                          ██████████████████████████████████████████████████████████████████████████████▃                    ',
  '                             ███████████████████████████████████████████████████████████████████▆▇█████▆▍                    ',
  '                                ▃████▁▃▃███████████████████████████████████████████████████████▄ ▌▄█▇▄▊▏                     ',
  '                                    ▃▅▆▅▇██████▇  ▇██████▂ ▅██████▅ ▃███████  ▆██████▅▉ ███████▆▆▃▉                          ',
  '                                     ▁▂▅▇████▇▇▆▆▆▇▇▇▇▇▇▇▇▅▇▇▇▇▇▇▇▆▅▇▆▇▇▇▇▇▆▇▆▆▇▇▇▇▇▇▆▅▆▇▇▇▇▇▇█                              ',
}

require('dashboard').setup {
  theme = 'hyper',
  config = {
    header = logo,
    shortcut = {},
    project = {
      enable = true,
      label = 'Recent projects:',
      -- vim.cmd.cd, not vim.cmd('cd ' .. path): the string form breaks on
      -- paths containing spaces.
      action = function(path)
        vim.cmd.cd(path)
        require('oil').open(path)
      end,
    },
  },
}

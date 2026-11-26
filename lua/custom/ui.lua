-- Theme, dashboard and file explorer. See lua/custom/init.lua for load-order notes.
-- The colorscheme is applied before dashboard is configured, because the
-- dashboard header override references cyberdream's palette.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'scottmckendry/cyberdream.nvim',
  gh 'nvimdev/dashboard-nvim',
  gh 'stevearc/oil.nvim',
  gh 'brenoprata10/nvim-highlight-colors',
}

-- [[ Colorscheme ]]
require('cyberdream').setup {
  transparent = true,
  saturation = 0.5,
  terminal_colors = true,
  italic_comments = true,
  borderless_pickers = true,
  overrides = function(colors)
    return {
      DashboardHeader = { fg = colors.green, bg = 'NONE' },
    }
  end,
}
vim.cmd.colorscheme 'cyberdream'

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

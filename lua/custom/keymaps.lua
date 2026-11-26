-- Keymaps. See lua/custom/init.lua for load-order notes.
-- LSP keymaps are upstream's 0.11+ defaults (grn/gra/grr/gri/grd/grt/gO/gW)
-- and are deliberately NOT aliased to the older gd/gr/gI style.

---Prompt for an LSP client name and show its resolved config in a floating window.
local function inspect_lsp_client()
  vim.ui.input({ prompt = 'Enter LSP Client name: ' }, function(client_name)
    if not client_name or client_name == '' then return end

    local clients = vim.lsp.get_clients { name = client_name }
    if #clients == 0 then
      vim.notify('No active LSP clients found with this name: ' .. client_name, vim.log.levels.WARN)
      return
    end

    local lines = {}
    for i, client in ipairs(clients) do
      if i > 1 then table.insert(lines, string.rep('-', 80)) end
      table.insert(lines, 'Client: ' .. client.name)
      table.insert(lines, 'ID: ' .. client.id)
      table.insert(lines, '')
      table.insert(lines, 'Configuration:')
      vim.list_extend(lines, vim.split(vim.inspect(client.config), '\n'))
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = 'lua'
    vim.bo[buf].bufhidden = 'delete'

    vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = math.floor(vim.o.columns * 0.75),
      height = math.floor(vim.o.lines * 0.9),
      col = math.floor(vim.o.columns * 0.125),
      row = math.floor(vim.o.lines * 0.05),
      style = 'minimal',
      border = 'rounded',
      title = ' ' .. client_name:gsub('^%l', string.upper) .. ': LSP Configuration ',
      title_pos = 'center',
    })

    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf, nowait = true, silent = true })
  end)
end

-- Window splits.
vim.keymap.set('n', '<leader><S-w>l', '<cmd>vsplit<CR>', { desc = 'Split window right' })
vim.keymap.set('n', '<leader><S-w>j', '<cmd>split<CR>', { desc = 'Split window below' })
vim.keymap.set('n', '<leader>lc', inspect_lsp_client, { desc = '[L]SP [C]lient config' })

-- Nag on arrow keys in normal mode.
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Reserved as the tmux prefix. blink.cmp's default preset wants this key, so
-- lua/custom/completion.lua clears it there too.
vim.keymap.set({ 'i', 'n' }, '<C-Space>', '')

-- Document the <leader>l chain for which-key (upstream registers the rest).
require('which-key').add { { '<leader>l', group = '[L]SP' } }

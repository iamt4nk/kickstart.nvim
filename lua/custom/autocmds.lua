-- Autocommands and user commands. See lua/custom/init.lua for load-order notes.

local group = vim.api.nvim_create_augroup('custom-autocmds', { clear = true })

-- Per-filetype indentation.
--
-- FileType + buffer-local vim.bo, NOT the old config's BufWinEnter + `set`:
-- `set shiftwidth=4` is global, so entering a Python buffer leaked 4-space
-- indentation into every other buffer in the session.
local indent_by_ft = {
  python = 4,
  html = 2,
  json = 2,
  jsonc = 2,
  yaml = 2,
}

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = vim.tbl_keys(indent_by_ft),
  callback = function(ev)
    local width = indent_by_ft[vim.bo[ev.buf].filetype]
    if not width then return end
    vim.bo[ev.buf].shiftwidth = width
    vim.bo[ev.buf].tabstop = width
    vim.bo[ev.buf].expandtab = true
  end,
})

-- `.whitesource` is JSON without the extension.
vim.filetype.add { filename = { ['.whitesource'] = 'json' } }

-- Remember folds and cursor position in JSON files across sessions.
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  pattern = '*.json',
  callback = function() vim.cmd 'silent! loadview' end,
})

vim.api.nvim_create_autocmd('BufWinLeave', {
  group = group,
  pattern = '*.json',
  callback = function() vim.cmd 'silent! mkview' end,
})

-- Autosave odin buffers so diagnostics stop going stale.
--
-- ols type-checks by shelling out to `odin check`, which reads from disk, so a
-- fixed error keeps its sign until the buffer is written. ols can feed the
-- compiler in-memory buffers instead (enable_checker_on_change), but that needs
-- an `odin` built with `-overlay`, which upstream does not have -- it logs
-- "has no `-workspace` or `-overlay`, so packages are checked one at a time
-- from disk" and silently re-reports the on-disk errors.
--
-- InsertLeave/BufLeave, NOT a typing-pause debounce: odin is in conform's
-- format_on_save path (lua/custom/format.lua), so every write runs odinfmt.
-- Writing mid-keystroke would reindent the line under the cursor.
vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufLeave' }, {
  group = group,
  pattern = '*.odin',
  desc = 'Write odin buffers so ols re-checks them',
  callback = function(ev)
    if not vim.bo[ev.buf].modified or not vim.bo[ev.buf].modifiable then return end
    -- `write` on a nameless or special buffer is an error, not a no-op.
    if vim.bo[ev.buf].buftype ~= '' or vim.api.nvim_buf_get_name(ev.buf) == '' then return end
    vim.api.nvim_buf_call(ev.buf, function() vim.cmd 'silent! write' end)
  end,
})

-- [[ Receipt munging ]]
-- Turn a saved order JSON payload into tab-separated name/price lines.
vim.api.nvim_create_user_command(
  'FormatSamsClub',
  function() vim.cmd [[%!jq -r '.data.order.groups_2101[].items[] | "\(.productInfo.name)\t\(.priceInfo.linePrice.value)"']] end,
  { desc = 'Reduce a Sams Club order payload to name/price lines' }
)

vim.api.nvim_create_user_command(
  'FormatKroger',
  function()
    vim.cmd [[%!jq -r '.data.purchaseHistoryDetails[].items[] | "\(.purchasedData.displayInfo.description)\t\(.purchasedData.pricingInfo.totalPricePaid | split(" ")[1])"']]
  end,
  { desc = 'Reduce a Kroger purchase payload to name/price lines' }
)

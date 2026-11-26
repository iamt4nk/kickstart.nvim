-- Formatting. See lua/custom/init.lua for load-order notes.
--
-- Upstream init.lua already called conform's setup with an opt-in format_on_save.
-- This replaces it with the opt-out policy this config wants: format everything
-- on save except the languages below. Unlike blink.cmp, conform's setup is
-- re-runnable, so calling it again here is enough.

require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    local filetype = vim.bo[bufnr].filetype

    -- No well-standardised style, so leave these alone.
    local disabled = { c = true, cpp = true }
    if disabled[filetype] then return { timeout_ms = 500, lsp_format = 'never' } end

    -- html-lsp's formatter honours the indentation settings in lua/custom/lsp.lua,
    -- so prefer it over any external tool.
    local prefer_lsp = { html = true }
    if prefer_lsp[filetype] then return { timeout_ms = 500, lsp_format = 'prefer' } end

    return { timeout_ms = 500, lsp_format = 'fallback' }
  end,
  formatters_by_ft = {
    go = { 'goimports', 'gofumpt' },
    lua = { 'stylua' },
    python = { 'ruff_format' },
    templ = { 'templ' },
    -- odinfmt ships inside the Mason `ols` package. It reads directives from the
    -- nearest odinfmt.json, searching upward from the file.
    odin = { 'odinfmt' },
  },
}

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, { desc = '[F]ormat buffer' })

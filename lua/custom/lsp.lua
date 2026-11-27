-- Language servers. See lua/custom/init.lua for load-order notes.

-- Ruff and pyright both attach to Python buffers. Pyright owns hover; silencing
-- ruff's avoids two competing popups.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('custom-ruff-no-hover', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == 'ruff' then client.server_capabilities.hoverProvider = false end
  end,
})

---@type table<string, vim.lsp.Config>
local servers = {
  -- Odin. nvim-lspconfig's shipped lsp/ols.lua already resolves the root via
  -- ols.json -> .git -> *.odin and honours ODIN_ROOT, so there is nothing to override.
  -- ols/odinfmt are built from source (~/repos/ols, linked into ~/.local/bin) so they
  -- track the locally built Odin compiler; they are deliberately NOT Mason-managed.
  ols = {},

  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        codelenses = {
          gc_details = false,
          generate = true,
          regenerate_cgo = true,
          run_govulncheck = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        analyses = {
          fieldalignment = true,
          nilness = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
        },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
        semanticTokens = true,
      },
    },
  },

  pyright = {
    settings = {
      python = {
        analysis = {
          diagnosticSeverityOverrides = {
            reportArgumentType = 'none',
          },
        },
      },
    },
  },

  ruff = {
    cmd_env = { RUFF_TRACE = 'messages' },
    init_options = {
      settings = {
        lineLength = 95,
        configurationPreference = 'editorOnly',
        logLevel = 'error',
        -- State dir, not the config dir: logs are not configuration.
        logFile = vim.fn.stdpath 'state' .. '/ruff.log',
      },
    },
  },
}

-- Mason package names, which differ from lspconfig server names.
require('mason-tool-installer').setup {
  ensure_installed = {
    -- REQUIRED by nvim-treesitter `main`, which needs tree-sitter-cli >= 0.26.1 to
    -- build grammars. Ubuntu's apt `tree-sitter` is 0.20.8 and lacks the `build`
    -- subcommand entirely. Mason prepends its bin dir to Neovim's PATH, so the
    -- Mason copy shadows /usr/bin/tree-sitter for nvim only.
    'tree-sitter-cli',
    'gopls',
    'gofumpt',
    'goimports',
    'delve',
    -- No 'debugpy': lua/custom/debug.lua runs the project's own interpreter
    -- (`uv add --dev debugpy`), so Mason's copy would never be used.
    'pyright',
    'ruff',
    'lua-language-server',
    'stylua',
  },
}

-- lua_ls is intentionally absent from `servers`: upstream's init.lua already
-- configures it with the runtime-path and formatting-off settings this config
-- wants, and re-registering here would clobber its on_init.
for name, config in pairs(servers) do
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

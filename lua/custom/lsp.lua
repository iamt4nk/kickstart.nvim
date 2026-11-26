-- Language servers. See lua/custom/init.lua for load-order notes.
-- schemastore lives here (not plugins.lua) because the jsonls config below
-- requires it at setup time.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'b0o/schemastore.nvim' }

-- `.tmpl` files here are Go templates handled by the templ language server.
-- Neovim 0.12 maps .tmpl to the generic `template` filetype by default, so this
-- override is load-bearing.
vim.filetype.add { extension = { tmpl = 'templ' } }

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

  templ = {
    filetypes = { 'html', 'templ' },
  },

  tailwindcss = {
    filetypes = { 'templ', 'html' },
    settings = {
      tailwindCSS = {
        includeLanguages = { templ = 'html' },
      },
    },
  },

  htmx = {
    filetypes = { 'html', 'templ' },
  },

  html = {
    -- snippetSupport is required for html-lsp to offer tag completions.
    capabilities = (function()
      local caps = vim.lsp.protocol.make_client_capabilities()
      caps.textDocument.completion.completionItem.snippetSupport = true
      return caps
    end)(),
    settings = {
      html = {
        format = {
          indentInnerHtml = true,
          wrapLineLength = 120,
          wrapAttributes = 'auto',
          templating = true,
          contentUnformatted = 'pre,code,textarea',
          indentation = { size = 2 },
        },
      },
    },
  },

  jsonls = {
    -- No 'whitesource' entry: there is no such filetype. `.whitesource` files are
    -- mapped to `json` in lua/custom/autocmds.lua, and listing a nonexistent
    -- filetype here makes :checkhealth warn.
    filetypes = { 'json', 'jsonc', 'json5' },
    settings = {
      json = {
        schemas = require('schemastore').json.schemas {
          extra = {
            {
              description = 'Mend Github.com repo integration schemas',
              fileMatch = { '.whitesource' },
              name = '.whitesource',
              url = 'https://raw.githubusercontent.com/mend-toolkit/mend-examples/kyal/add-json-schema/Repo-Integration/Schemas/ghc-integration-schema.json',
            },
          },
        },
        validate = { enable = true },
        format = { enable = true },
      },
    },
  },
}

-- Mason package names, which differ from lspconfig server names.
require('mason-tool-installer').setup {
  ensure_installed = {
    'ols', -- also provides the odinfmt binary
    -- REQUIRED by nvim-treesitter `main`, which needs tree-sitter-cli >= 0.26.1 to
    -- build grammars. Ubuntu's apt `tree-sitter` is 0.20.8 and lacks the `build`
    -- subcommand entirely. Mason prepends its bin dir to Neovim's PATH, so the
    -- Mason copy shadows /usr/bin/tree-sitter for nvim only.
    'tree-sitter-cli',
    'gopls',
    'gofumpt',
    'goimports',
    'delve',
    'debugpy',
    'pyright',
    'ruff',
    'lua-language-server',
    'stylua',
    'json-lsp',
    'html-lsp',
    'templ',
    'tailwindcss-language-server',
    'htmx-lsp',
  },
}

-- lua_ls is intentionally absent from `servers`: upstream's init.lua already
-- configures it with the runtime-path and formatting-off settings this config
-- wants, and re-registering here would clobber its on_init.
for name, config in pairs(servers) do
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

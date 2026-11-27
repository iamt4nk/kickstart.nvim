-- Extra treesitter parsers. See lua/custom/init.lua for load-order notes.
--
-- Upstream init.lua installs the base set and registers the FileType autocmd
-- that attaches and auto-installs on demand. This only widens the preinstalled
-- set so first-open of these filetypes is not a stall.
--
-- Requires tree-sitter-cli >= 0.26.1 to build grammars; see the Mason tool list
-- in lua/custom/lsp.lua for why that is installed rather than used from apt.

require('nvim-treesitter').install {
  -- Odin. Tier 2 grammar from tree-sitter-grammars/tree-sitter-odin.
  'odin',
  -- Go
  'go',
  'gomod',
  'gowork',
  'gosum',
  -- Web
  'css',
  'javascript',
  -- Python
  'python',
  'ninja',
  'rst',
  -- Data
  -- NOTE: no 'jsonc' -- nvim-treesitter `main` has no separate jsonc grammar and
  -- warns on startup if you ask for one. jsonc buffers use the json parser.
  'json',
  'yaml',
  'toml',
}

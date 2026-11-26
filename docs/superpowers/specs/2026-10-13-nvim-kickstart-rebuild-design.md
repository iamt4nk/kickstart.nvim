# Neovim config rebuild on current kickstart.nvim

**Date:** 2026-10-13
**Status:** approved, pending implementation plan

## Problem

`~/.config/nvim-bak` is a kickstart.nvim fork from November 2024 that has drifted.
It is built on lazy.nvim, pulls in LazyVim purely as a utility library, carries
dead configuration that has never executed, and vendors a Python virtualenv inside
the config directory. Upstream kickstart has since been rewritten around Neovim
0.12 primitives, so the fork can no longer take updates.

Separately, Odin files get no language support at all.

## Goals

1. Rebuild `~/.config/nvim` from current upstream kickstart.nvim.
2. Carry forward the customizations that still earn their place.
3. Add Odin: completion, formatting, syntax.
4. Verify the result, and report missing external dependencies.
5. Leave the config organized enough to stay that way.

## Non-goals

- Touching `~/.config/nvim-bak` or `~/.config/nvim_dev`. Both stay exactly as they
  are. `nvim-bak` is the rollback path; `nvim_dev` remains the smm.nvim dev sandbox,
  launchable via `NVIM_APPNAME=nvim_dev`.
- Modifying anything outside `~/.config/nvim` — including the `fd`/`fdfind` symlink,
  which is noted as a recommendation only.

## Baseline

Upstream pinned at `8e35dbedb7966e3a95e1f26f9fc1179ab6c68db4` (2026-10-03).

Four engine changes versus the 2024 fork:

| Concern    | Old (nvim-bak)                | New (upstream)                    |
| ---------- | ----------------------------- | --------------------------------- |
| Plugins    | lazy.nvim                     | `vim.pack` (built into 0.12)      |
| Completion | nvim-cmp                      | blink.cmp                         |
| LSP        | `lspconfig[name].setup()`     | `vim.lsp.config()` / `.enable()`  |
| Treesitter | `master` branch, `opts`       | `main` branch, `.install()`       |

Local Neovim is 0.12.0-dev, so `vim.pack` is available. Verified.

## Architecture

```
~/.config/nvim/
  init.lua                   upstream, three edits only
  lua/custom/
    init.lua                 ordered loader
    options.lua              WSL clipboard, relativenumber, listchars, undofile
    keymaps.lua              split creation, arrow-key nags, <leader>lc inspector
    autocmds.lua             json view persistence, .whitesource, py/html indent,
                             templ format-on-save, FormatKroger/FormatSamsClub
    ui.lua                   cyberdream, dashboard-nvim, oil.nvim, highlight-colors
    lsp.lua                  schemastore + gopls, pyright, ruff, lua_ls, jsonls,
                             templ, tailwindcss, htmx, ols
    completion.lua           blink.cmp overrides
    format.lua               conform.nvim, formatters_by_ft, format-on-save policy
    debug.lua                nvim-dap, dap-ui, dap-go, Python launch.json loader
    treesitter.lua           additional parsers
    plugins.lua              markdown-preview, smm.nvim
  lua/kickstart/plugins/     upstream examples, left unloaded
```

`init.lua` is modified in exactly three places so it stays diffable against
upstream:

- `vim.g.have_nerd_font = true`
- `vim.o.relativenumber = true`
- `require 'custom'` appended at the end

Everything else lives under `lua/custom/`. Each module calls `vim.pack.add` at the
top and `setup()` immediately after.

### Load order

`lua/custom/init.lua` requires modules in an explicit, fixed order rather than
globbing the directory, because four real dependencies exist between them:

```
options  →  keymaps  →  ui  →  lsp  →  completion  →  format  →  debug
         →  treesitter  →  autocmds  →  plugins
```

- `options` sets the leader before any module binds a `<leader>` key
- `ui` installs nvim-highlight-colors, which `completion` references inside blink's
  `kind_icon` draw component
- `lsp` installs schemastore, which its own jsonls config consumes — this is why
  schemastore lives in `lsp.lua` and not `plugins.lua`
- `format` installs conform, which `autocmds` calls for the HTML write hook

Within `ui.lua`, the colorscheme is set before dashboard is configured, since the
dashboard header highlight overrides reference cyberdream's palette.

### Module contracts

Each file is a module returning nothing, with no cross-module dependencies beyond
the load order above. A **plugin** is owned end to end by exactly one module —
install, configure, keymaps — so searching for a plugin name yields one hit.

Note this organizes by concern, not by language: a language like Go or Odin is
necessarily touched in `lsp.lua` (server), `treesitter.lua` (parser) and
`format.lua` (formatter). That is the intended axis — it keeps each plugin's
configuration in one place, at the cost of each language being spread across three.

## Removing LazyVim

The fork used LazyVim for three things:

| Use                                      | Resolution                                            |
| ---------------------------------------- | ----------------------------------------------------- |
| `require('lazyvim.config').icons.dap`    | Replaced — sign icons inlined as literals in `debug.lua` |
| `require('LazyVim').lsp.on_attach(f, n)` | Replaced — `LspAttach` autocmd filtered on `client.name == n`, used for the ruff hover fix |
| `require('lazyvim.util').on_load(...)`   | Moot — its only two callers were the terraform telescope extensions, both dropped. No replacement needed |

`vim.g.lazyvim_python_lsp` and `vim.g.lazyvim_python_ruff` are deleted; they are
inert without LazyVim.

## Dead code

The `servers` table in the old `lsp.lua` carried `setup = {...}` and `keys = {...}`
sub-tables. These are LazyVim conventions. The fork's mason-lspconfig handler passed
the whole table to `lspconfig[name].setup()`, which ignores unknown keys — so none
of it ever ran.

Resolution:

- **Reimplement** — disable ruff's `hoverProvider`. pyright and ruff both answer
  hover; suppressing ruff's is what the original intended and fixes doubled popups.
- **Reimplement** — `tmpl` → `templ` filetype mapping, via `vim.filetype.add`.
  Required for the retained web stack; without it `.tmpl` files get no LSP.
- **Drop** — the gopls semantic-tokens workaround. gopls advertises
  `semanticTokensProvider` natively now; the shim would be a no-op.
- **Drop** — the `<leader>td` terraform-docs keymap, moot now terraform is gone.

## Retained customizations

- **Editor:** WSL clipboard via `win32yank.exe`, relativenumber, `scrolloff = 10`,
  custom listchars, undofile, split-right/below
- **Keymaps:** `<leader><S-w>l` / `<leader><S-w>j` split creation, arrow-key nag
  messages, `<leader>lc` LSP client config inspector (floating window)
- **`<C-Space>` stays unmapped** in insert and normal mode for the tmux leader
- **UI:** cyberdream (transparent, `saturation = 0.5`), dashboard-nvim with the
  custom logo and oil-based project picker, oil.nvim as file explorer with the
  custom keymap set, nvim-highlight-colors in virtual mode
- **Languages:** Go (full gopls settings, gofumpt + goimports), templ, tailwindcss,
  htmx, html; Python (pyright + ruff, `lineLength = 95`, ruff_format); Lua
  (lua_ls with formatting off, stylua); JSON (schemastore + the `.whitesource`
  Mend schema)
- **Debug:** nvim-dap, dap-ui, dap-virtual-text, dap-go, and the Python adapter
  with project-root discovery (`.git` / `pyproject.toml` / `setup.py` /
  `requirements.txt`), venv-over-pyenv-shim resolution, and `.vscode/launch.json`
  merging. Keymaps `<F5>`–`<F9>`, `<leader>b`, `<leader>B`, `<leader>gb`,
  `<leader>[`
- **Autocmds:** json `mkview`/`loadview` persistence, `.whitesource` as json,
  Python 4-space, HTML 2-space, templ format-on-save via `templ format`
- **User commands:** `FormatKroger`, `FormatSamsClub`
- **Plugins:** markdown-preview (auto-start retained, per explicit choice),
  schemastore (in `lsp.lua`, see load order), smm.nvim from `iamt4nk/smm.nvim`

## Dropped

| Dropped                               | Reason                                      |
| ------------------------------------- | ------------------------------------------- |
| Terraform stack                       | No longer used. terraformls, tflint, telescope-terraform-doc, telescope-terraform, terraform_fmt, packer_fmt/hcl, `.tf` autocmds, terraform + hcl parsers |
| nvim-lint                             | Configured for markdown only; markdownlint not installed, so it was inert |
| neotest + neotest-golang              | Marked `optional = true` with nothing requiring it — never loaded |
| LazyVim                               | Replaced, see above                         |
| `python/venv/` and `python/ruff/`     | A virtualenv vendored inside the config dir |
| gopls semantic-tokens shim            | Obsolete                                    |

`ruff.log` moves to `stdpath('state')`.

The old fork never loaded `lua/kickstart/plugins/*` — its lazy spec imported only
`custom.plugins`. So autopairs, indent_line, lint, neo-tree, the kickstart debug
module and the kickstart gitsigns module were all inert. Upstream's copies are kept
on disk, unloaded, exactly as upstream ships them.

## LSP keymaps

Adopting Neovim 0.11+ / upstream defaults wholesale: `grn` rename, `gra` code
action, `grr` references, `gri` implementation, `grd` definition, `grt` type
definition, `gO` document symbols, `gW` workspace symbols.

The old `gd` / `gr` / `gI` / `<leader>rn` / `<leader>ca` / `<leader>ds` /
`<leader>ws` / `<leader>D` bindings are removed, not aliased. `gr` in particular
cannot coexist — it is the new prefix.

## Completion

blink.cmp with the `default` preset, `fuzzy.implementation = 'lua'`, luasnip as
snippet engine, sources `lsp` / `path` / `snippets`.

Two overrides:

1. **`<C-space>` cleared.** The default preset binds it to show-menu/show-docs,
   which collides with the reserved tmux leader. Documentation moves to `<C-d>`.
2. **nvim-highlight-colors integration** via `completion.menu.draw.components.kind_icon`,
   using the upstream-documented blink recipe — this replaces the old nvim-cmp
   `formatting.format` hook, which has no blink equivalent.

## Odin

No filetype detection needed: Neovim 0.12 already maps `.odin` → `odin`. Verified
with `vim.filetype.match`.

| Layer      | Implementation                                                   |
| ---------- | ---------------------------------------------------------------- |
| LSP        | `ols`, installed by Mason, configured via `vim.lsp.config('ols', …)`, root markers `ols.json` then `.git` |
| Formatting | conform's built-in `odinfmt`; the binary ships inside the Mason `ols` package as its `fmt_bin` |
| Syntax     | nvim-treesitter `odin` parser (tier 2; highlights, indents, folds, injections, locals) |
| Completion | blink's `lsp` source, no extra work                               |

Format-on-save is enabled for Odin, consistent with the other retained languages.

## Formatting policy

conform.nvim, carrying the old fork's behavior forward: format on save for all
filetypes except `c` and `cpp`, `lsp_format = 'fallback'`, 500ms timeout, `html`
prefers LSP formatting. `<leader>f` formats manually.

Per-filetype formatters: go → goimports + gofumpt; lua → stylua; python →
ruff_format; templ → templ; odin → odinfmt.

## Verification

Two passes, because they answer different questions.

**Pass 1 — clean slate, scratch `XDG_DATA_HOME`.** Proves the config bootstraps
from nothing, the way it would on a new machine. Nothing here touches
`~/.local/share/nvim`.

1. `stylua --check` across the config
2. Headless startup, asserting clean exit and that every plugin cloned
3. `:checkhealth` headless, output scanned for errors

**Pass 2 — the real `~/.local/share/nvim`.** This is the one that leaves a working
editor behind.

4. Mason installs driven to completion, each tool verified present on disk under
   `~/.local/share/nvim/mason/bin`
5. Treesitter parsers installed, `odin` among them, verified via `get_installed`
6. Per-language smoke tests: write a real `.odin`, `.go`, `.py`, `.lua`, `.templ`
   and `.json` file; open each headless; assert the expected client attaches and
   that `conform.format()` mutates a deliberately misformatted buffer
7. Report every missing external dependency

A test passes only if it asserts the outcome. "nvim started without crashing" is
not evidence that the Odin LSP attached.

## Dependencies

**Present and verified:** nvim 0.12.0-dev, git 2.43, make, gcc, ripgrep, fzf,
unzip, node 22.14, npm, python3 (pyenv), go, odin dev-2026-10-nightly, templ, jq,
gopls, win32yank.exe, fd 9.0.0

**Mason installs, implementation verifies:** ols (+ odinfmt), stylua, delve,
debugpy, gofumpt, goimports, pyright, ruff, lua-language-server, templ-lsp,
tailwindcss-language-server, htmx-lsp

**Note, not an action item:** `fd-find` installs its binary as `/usr/bin/fdfind`
on Debian/Ubuntu. Telescope handles this (its chain is `rg` → `fd` → `fdfind` →
`find`, and `rg` wins first anyway), but plugins that hardcode `fd` will silently
fail. A `~/.local/bin/fd` symlink would fix that. Out of scope — user's call.

## Risks

- **Slower startup.** `vim.pack` has no lazy-loading. Expect roughly 150–400ms
  against the current ~50ms. Inherent to the choice; the tradeoff is a config with
  no plugin-manager dependency.
- **`vim.pack` is young.** Fewer escape hatches than lazy.nvim. It does have a
  lockfile (`nvim-pack-lock.json`, see `:help vim.pack-lockfile`); upstream
  gitignores it only to avoid merge conflicts in the public repo and recommends
  forks track it, so this config un-ignores and commits it. `nvim-bak` is the
  rollback.
- **nvim-treesitter `main` is a breaking rewrite.** Tier-2 parsers like `odin` are
  less battle-tested than tier 1.
- **Keymap relearning.** `gd` → `grd` and friends will cost a few days of muscle
  memory.

## Rollback

`~/.config/nvim-bak` is untouched. Reverting is `mv ~/.config/nvim ~/.config/nvim-new
&& cp -r ~/.config/nvim-bak ~/.config/nvim`, plus clearing `~/.local/share/nvim`.

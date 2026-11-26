# nvim

Personal Neovim configuration, forked from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
at `8e35dbe` (2026-10-03).

`init.lua` is upstream kickstart with four edits — nerd font on, relative line
numbers on, blink.cmp's config sourced from `lua/custom/completion.lua`, and
`require 'custom'` at the bottom. Everything else personal lives in
`lua/custom/`. Keeping it that way means `git diff upstream/master -- init.lua`
stays readable and kickstart updates can be merged.

## Layout

| File | Responsibility |
| --- | --- |
| `lua/custom/init.lua` | Ordered module loader |
| `lua/custom/options.lua` | WSL clipboard, relativenumber, listchars, scrolloff |
| `lua/custom/keymaps.lua` | Splits, arrow-key nags, `<leader>lc` LSP inspector |
| `lua/custom/ui.lua` | cyberdream, dashboard, oil, colour swatches |
| `lua/custom/lsp.lua` | Language servers, Mason tool list |
| `lua/custom/completion.lua` | blink.cmp (returns opts, see below) |
| `lua/custom/format.lua` | conform.nvim |
| `lua/custom/debug.lua` | nvim-dap, Python + Go |
| `lua/custom/treesitter.lua` | Extra parsers |
| `lua/custom/autocmds.lua` | Filetype indentation, user commands |
| `lua/custom/plugins.lua` | markdown-preview, smm.nvim |

Load order matters in four places; see the comment at the top of
`lua/custom/init.lua`.

`lua/kickstart/plugins/` holds upstream's optional examples. They are kept on
disk, unloaded, exactly as upstream ships them.

## Gotchas worth knowing

These are vim.pack behaviours that lazy.nvim used to paper over. Each one cost
real debugging time; they are documented inline where they bite.

- **blink.cmp guards its own setup** with `if has_setup then return end`, so
  configuring it from `lua/custom/` is a silent no-op. `completion.lua` therefore
  *returns* its opts table and `init.lua` SECTION 8 applies it.
- **`plugin/` scripts run after `init.lua`.** smm.nvim's `plugin/smm.lua` calls
  `setup()` with no arguments, which clobbered our config with defaults. We claim
  `vim.g.loaded_smm` to make it return early.
- **`PackChanged` fires during `vim.pack.add`**, so build hooks must be
  registered *before* the add, not after.
- **mason-nvim-dap registers its own python adapter** pointing at Mason's
  interpreter. It must be set up *before* ours, so ours wins.
- **nvim-treesitter `main` needs tree-sitter-cli >= 0.26.1.** Ubuntu's apt
  `tree-sitter` is 0.20.8 and has no `build` subcommand, which fails every parser
  build. Mason's copy is installed and shadows it for Neovim only.

## Plugins

Managed by `vim.pack`, built into Neovim 0.12 — there is no plugin manager
dependency. `nvim-pack-lock.json` is tracked in git.

- Inspect: `:lua vim.pack.update(nil, { offline = true })`
- Update: `:lua vim.pack.update()`

## Tests

```sh
./tests/run.sh           # against the real data dir
CLEAN=1 ./tests/run.sh   # bootstrap from an empty data dir
```

Every module has a `tests/test_*.lua`. Tests assert real outcomes — that `ols`
attaches to an `.odin` buffer, that `conform` actually changes a misformatted
file — not just that config tables have the right shape.

`CLEAN=1` proves the config bootstraps from nothing. In that mode the Mason
tools are absent, so the formatter and `ruff` assertions fail by design; what
matters is that no Lua errors occur.

Fixtures are written to `~/.cache/nvim/nvim-config-tests/`, deliberately outside
this repo: several are intentionally misformatted, and anything under the repo
gets picked up by `stylua` — including conform's stylua formatter, which honours
`.styluaignore` and would then refuse to format the fixture the test depends on.

## Languages

Go (gopls, gofumpt, goimports, delve), Python (pyright + ruff, debugpy),
Odin (ols, odinfmt), Lua (lua_ls, stylua), templ/HTML/Tailwind/htmx, JSON
(schemastore).

Formatting is opt-out: everything formats on save except `c` and `cpp`. HTML
prefers the language server; everything else prefers the external formatter and
falls back to the LSP.

## Dependencies

External: `git`, `make`, `gcc`, `ripgrep`, `fzf`, `unzip`, `node`, `go`, `odin`,
`templ`, `jq`. Under WSL, `win32yank.exe` for clipboard.

Everything else is installed by Mason on first launch.

> On Debian/Ubuntu, `fd-find` installs as `fdfind`. Telescope handles this, but
> plugins that hardcode `fd` will not. `ln -s /usr/bin/fdfind ~/.local/bin/fd` if
> that ever bites.

## Keymaps worth knowing

LSP uses Neovim 0.11+ defaults: `grn` rename, `gra` code action, `grr`
references, `gri` implementation, `grd` definition, `grt` type definition, `gO`
document symbols, `gW` workspace symbols.

`<C-Space>` is deliberately unmapped — it is the tmux prefix. blink.cmp's
documentation popup lives on `<C-d>` instead.

Debugging: `<F5>` continue, `<F6>` step over, `<F7>` step into, `<F8>` step out,
`<F9>` toggle UI, `<leader>b` breakpoint, `<leader>B` conditional breakpoint,
`<leader>gb` run to cursor.

## Rollback

`~/.config/nvim-bak` is the previous lazy.nvim config, untouched.

```sh
mv ~/.config/nvim ~/.config/nvim-new
cp -r ~/.config/nvim-bak ~/.config/nvim
rm -rf ~/.local/share/nvim
```

`~/.config/nvim_dev` is a separate sandbox for developing smm.nvim, run with
`NVIM_APPNAME=nvim_dev nvim`.

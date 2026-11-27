-- Debugging. See lua/custom/init.lua for load-order notes.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'nvim-neotest/nvim-nio',
  gh 'rcarriga/nvim-dap-ui',
  gh 'theHamsta/nvim-dap-virtual-text',
  gh 'leoluz/nvim-dap-go',
  gh 'jay-babu/mason-nvim-dap.nvim',
}

---Walk up from the current file looking for a project marker.
---@return string?
local function find_project_root()
  local markers = { '.git', 'pyproject.toml', 'setup.py', 'requirements.txt' }
  local current_dir = vim.fn.expand '%:p:h'
  while current_dir ~= '/' and current_dir ~= '' do
    for _, marker in ipairs(markers) do
      local candidate = current_dir .. '/' .. marker
      if vim.fn.filereadable(candidate) == 1 or vim.fn.isdirectory(candidate) == 1 then return current_dir end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end
end

---Resolve the Python interpreter to debug with: the project venv (uv's `.venv`,
---or a plain `venv`), then whatever uv resolves for the project, then system python.
---@return string
local function get_python_path()
  local project_root = find_project_root()

  if project_root then
    for _, dir in ipairs { '.venv', 'venv' } do
      -- Not resolved: following the venv's python symlink would escape the venv.
      local venv_python = project_root .. '/' .. dir .. '/bin/python'
      if vim.fn.executable(venv_python) == 1 then return venv_python end
    end
  end

  -- No venv: uv honours .python-version / requires-python and finds
  -- uv-managed interpreters (`uv python install ...`).
  if vim.fn.executable 'uv' == 1 then
    local result = vim.system({ 'uv', 'python', 'find' }, { cwd = project_root, text = true }):wait()
    local uv_python = (result.stdout or ''):gsub('[\n\r]', '')
    if result.code == 0 and uv_python ~= '' then return uv_python end
  end

  local fallback = vim.fn.exepath 'python3'
  if fallback == '' then fallback = vim.fn.exepath 'python' end
  return fallback
end

local dap = require 'dap'
local dapui = require 'dapui'
local python_path = get_python_path()

-- mason-nvim-dap registers its own adapters for every installed debugger, and
-- its python adapter hardcodes Mason's `debugpy-adapter` wrapper (and therefore
-- Mason's interpreter). That would silently defeat get_python_path(). Set it up
-- FIRST so the project-aware adapter defined below overwrites it, not vice versa.
require('mason-nvim-dap').setup {
  automatic_installation = false,
  handlers = {},
  ensure_installed = {},
}

-- [[ Python ]]
local default_python_config = {
  type = 'python',
  request = 'launch',
  pythonPath = python_path,
  console = 'integratedTerminal',
  justMyCode = false,
  env = {
    PYTHONPATH = vim.fn.getcwd(),
  },
}

-- If the interpreter lives in a venv (<venv>/bin/python), activate that venv.
local venv_dir = vim.fn.fnamemodify(python_path, ':h:h')
if vim.fn.filereadable(venv_dir .. '/pyvenv.cfg') == 1 then
  default_python_config.env.VIRTUAL_ENV = venv_dir
  default_python_config.env.PATH = venv_dir .. '/bin:' .. vim.env.PATH
end

---Overlay a user configuration on the defaults, without letting it clobber the
---interpreter or the three environment variables we control.
local function merge_config(user_config)
  if user_config.type ~= 'python' then return user_config end

  local config = vim.deepcopy(default_python_config)
  for k, v in pairs(user_config) do
    if k ~= 'pythonPath' and k ~= 'env' then config[k] = v end
  end

  if user_config.env then
    for k, v in pairs(user_config.env) do
      if k ~= 'PYTHONPATH' and k ~= 'VIRTUAL_ENV' and k ~= 'PATH' then config.env[k] = v end
    end
  end

  return config
end

dap.adapters.python = {
  type = 'executable',
  command = python_path,
  args = { '-m', 'debugpy.adapter' },
}

---Load .vscode/launch.json for this buffer, or fall back to a plain launch config.
local function load_launch_json(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.b[bufnr].dap_configs_loaded then return end

  local launch_json = vim.fn.getcwd() .. '/.vscode/launch.json'
  if vim.fn.filereadable(launch_json) == 1 then
    -- pcall: the old config used vim.fn.json_decode bare, so a malformed
    -- launch.json threw on every buffer enter.
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(launch_json), '\n'))
    if ok and decoded and decoded.configurations then dap.configurations.python = vim.tbl_map(merge_config, decoded.configurations) end
  else
    dap.configurations.python = {
      merge_config {
        type = 'python',
        name = 'Launch file',
        program = '${file}',
        cwd = '${workspaceFolder}',
      },
    }
  end

  vim.b[bufnr].dap_configs_loaded = true
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-dap-python', { clear = true }),
  pattern = 'python',
  callback = function(ev) load_launch_json(ev.buf) end,
})

-- Apply the same merge to configurations started programmatically.
local original_run = dap.run
dap.run = function(config, opts) return original_run(config.type == 'python' and merge_config(config) or config, opts) end

-- [[ Go ]]
require('dap-go').setup {}

-- [[ Signs ]]
-- Icons were previously pulled from LazyVim; they are literals now.
vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
for name, sign in pairs {
  Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
  Breakpoint = { ' ', 'DiagnosticInfo' },
  BreakpointCondition = { ' ', 'DiagnosticInfo' },
  BreakpointRejected = { ' ', 'DiagnosticError' },
  LogPoint = { '.>', 'DiagnosticInfo' },
} do
  vim.fn.sign_define('Dap' .. name, {
    text = sign[1],
    texthl = sign[2] or 'DiagnosticInfo',
    linehl = sign[3],
    numhl = sign[3],
  })
end

-- [[ UI ]]
dapui.setup {
  controls = {
    icons = {
      disconnect = '',
      pause = '',
      play = '',
      run_last = '',
      step_back = '',
      step_into = '',
      step_out = '',
      step_over = '',
      terminate = '',
    },
  },
  icons = {
    expanded = '▾',
    collapsed = '▸',
    current_frame = '*',
  },
}

require('nvim-dap-virtual-text').setup {}

dap.listeners.after.event_initialized['dapui_config'] = dapui.open
dap.listeners.before.event_terminated['dapui_config'] = dapui.close
dap.listeners.before.event_exited['dapui_config'] = dapui.close
dap.listeners.before['terminate']['custom'] = function() vim.fn.system 'pkill -f debugpy' end

-- [[ Keymaps ]]
vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<F6>', dap.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F7>', dap.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F8>', dap.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<F9>', dapui.toggle, { desc = 'Debug: Toggle UI' })
vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>B', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, { desc = 'Debug: Conditional Breakpoint' })
vim.keymap.set('n', '<leader>gb', dap.run_to_cursor, { desc = 'Debug: Run to cursor' })
vim.keymap.set('n', '<leader>[', function() dapui.eval(nil, { enter = true }) end, { desc = 'Debug: Evaluate under cursor' })

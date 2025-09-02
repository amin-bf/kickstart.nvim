-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    -- 'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'js-debug-adapter',
      },
    }

    dap.set_log_level 'TRACE'

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        enabled = true,
        element = 'repl',
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      mappings = {
        expand = { '<CR>', '<2-LeftMouse>' },
        open = 'o',
        remove = 'd',
        edit = 'e',
        repl = 'r',
        toggle = 't',
      },
      element_mappings = {},
      expand_lines = true,
      force_buffers = true,
      layouts = {
        {
          position = 'left',
          size = 40,
          elements = {
            { id = 'scopes', size = 0.45 },
            { id = 'breakpoints', size = 0.15 },
            { id = 'stacks', size = 0.2 },
            { id = 'watches', size = 0.2 },
          },
        },
        {
          position = 'bottom',
          size = 10,
          elements = { 'repl', 'console' },
        },
      },
      ---@diagnostic disable-next-line: missing-fields
      render = { max_type_length = nil, max_value_lines = 100 },
    }

    require('nvim-dap-virtual-text').setup()

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    local LOCAL_ROOT = vim.fn.getcwd()
    local REMOTE_ROOT = '/usr/src/api' -- must match your Docker working directory
    local WEB_ROOT = LOCAL_ROOT -- root of your frontend project
    local DEV_URL = 'https://localhost:9000' -- adjust for Quasar/Vite (e.g. 9000/5173)

    -- Shared skip patterns
    local SKIP = { '<node_internals>/**', '**/node_modules/**', '**/__vite/**' }

    dap.adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'js-debug-adapter',
        args = { '${port}' },
      },
    }
    dap.adapters['pwa-chrome'] = dap.adapters['pwa-node']

    -- Node: attach to Docker (9229)
    local node_attach_docker = {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach: Node in Docker (9229)',
      address = '127.0.0.1',
      port = 9229,
      cwd = LOCAL_ROOT,
      localRoot = LOCAL_ROOT,
      remoteRoot = REMOTE_ROOT,
      protocol = 'inspector',
      restart = true,
      sourceMaps = true,
      skipFiles = SKIP,
      processId = require('dap.utils').processId,
      -- If you build TS -> dist, uncomment:
      -- outFiles = { "${workspaceFolder}/dist/**/*.js" },
    }

    local node_attach_docker_worker = {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach: Node in Docker Worker (9228)',
      address = '127.0.0.1',
      port = 9228,
      cwd = LOCAL_ROOT,
      localRoot = LOCAL_ROOT,
      remoteRoot = REMOTE_ROOT,
      protocol = 'inspector',
      restart = true,
      sourceMaps = true,
      skipFiles = SKIP,
      processId = require('dap.utils').processId,
      -- If you build TS -> dist, uncomment:
      -- outFiles = { "${workspaceFolder}/dist/**/*.js" },
    }

    -- Node: launch on host (not Docker)
    local node_launch_host = {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch: Node (host)',
      program = '${workspaceFolder}/server.js', -- or dist/main.js
      cwd = '${workspaceFolder}',
      runtimeExecutable = 'node',
      console = 'integratedTerminal',
      sourceMaps = true,
      skipFiles = SKIP,
    }

    -- Chrome: launch to your dev server
    local chrome_launch = {
      type = 'pwa-chrome',
      request = 'launch',
      name = 'UI: Launch Chrome',
      url = DEV_URL,
      webRoot = WEB_ROOT,
      userDataDir = true,
      sourceMaps = true,
      skipFiles = SKIP,
      -- If you need a specific Chrome binary:
      -- runtimeExecutable = "/usr/bin/google-chrome",
    }

    -- Chrome: attach to an existing Chrome (9222)
    local chrome_attach = {
      type = 'pwa-chrome',
      request = 'attach',
      name = 'UI: Attach Chrome (9222)',
      port = 9222,
      webRoot = WEB_ROOT,
      urlFilter = DEV_URL .. '/*',
      sourceMaps = true,
      skipFiles = SKIP,
    }

    -- Register configs for JS/TS (+ Vue so :DapContinue works in .vue buffers)
    local fts = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' }
    for _, ft in ipairs(fts) do
      dap.configurations[ft] = dap.configurations[ft] or {}
      table.insert(dap.configurations[ft], node_attach_docker)
      table.insert(dap.configurations[ft], node_attach_docker_worker)
      table.insert(dap.configurations[ft], node_launch_host)
      table.insert(dap.configurations[ft], chrome_launch)
      table.insert(dap.configurations[ft], chrome_attach)
    end

    -- Install golang specific config
    -- require('dap-go').setup {
    --   delve = {
    --     -- On Windows delve must be run attached or it crashes.
    --     -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
    --     detached = vim.fn.has 'win32' == 0,
    --   },
    -- }
  end,
}

return {
  'nvim-neotest/neotest-jest',
  {
    'nvim-neotest/neotest',
    commit = '52fca6717ef9',
    dependencies = { 'nvim-neotest/nvim-nio', 'nvim-lua/plenary.nvim', 'antoinemadec/FixCursorHold.nvim', 'nvim-treesitter/nvim-treesitter' },
    opts = {
      -- Can be a list of adapters like what neotest expects,
      -- or a list of adapter names,
      -- or a table of adapter names, mapped to adapter configs.
      -- The adapter will then be automatically loaded with the config.
      adapters = {
        ['neotest-jest'] = {
          -- Use your runner. If you use pnpm/yarn, change accordingly.
          jestCommand = 'npx jest',
          -- Point to your actual config file (ts/js). Adjust the name/path.
          jestConfigFile = 'jest.config.ts',
          -- Make runs happen from the project/package root that has jest config.
          cwd = function(path)
            local u = require 'lspconfig.util'
            return u.root_pattern('jest.config.ts', 'jest.config.js', 'package.json', 'pnpm-workspace.yaml', 'yarn.lock')(path) or vim.fn.getcwd()
          end,
          -- If you’re ESM/ts-jest with useESM, this helps in many setups:
          env = { CI = '1', NODE_OPTIONS = '--experimental-vm-modules' },
        },
      },
      -- Example for loading neotest-golang with a custom config
      -- adapters = {
      --   ["neotest-golang"] = {
      --     go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
      --     dap_go_enabled = true,
      --   },
      -- },
      log_level = vim.log.levels.DEBUG,
      status = { virtual_text = true },
      output = {
        -- highlights in the output panel
        enabled = true, -- default: true
        open_on_run = true, -- auto-open on failure
      },
      output_panel = {
        enabled = true,
        open = 'botright split | resize 15',
      },
      highlights = {
        passed = 'NeotestPassed', -- green
        failed = 'NeotestFailed', -- red
        skipped = 'NeotestSkipped', -- yellow
      },
      quickfix = {
        open = function()
          vim.cmd 'copen'
        end,
      },
    },
    config = function(_, opts)
      local neotest_ns = vim.api.nvim_create_namespace 'neotest'
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            -- Replace newline and tab characters with space for more compact diagnostics
            local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
            return message
          end,
        },
      }, neotest_ns)

      if opts.adapters then
        local adapters = {}
        for name, config in pairs(opts.adapters or {}) do
          if type(name) == 'number' then
            if type(config) == 'string' then
              config = require(config)
            end
            adapters[#adapters + 1] = config
          elseif config ~= false then
            local adapter = require(name)
            if type(config) == 'table' and not vim.tbl_isempty(config) then
              local meta = getmetatable(adapter)
              if adapter.setup then
                adapter.setup(config)
              elseif adapter.adapter then
                adapter.adapter(config)
                adapter = adapter.adapter
              elseif meta and meta.__call then
                adapter = adapter(config)
              else
                error('Adapter ' .. name .. ' does not support setup')
              end
            end
            adapters[#adapters + 1] = adapter
          end
        end
        opts.adapters = adapters
      end

      require('neotest').setup(opts)
    end,
    -- stylua: ignore
    keys = {
      {"<leader>t", "", desc = "+test"},
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File (Neotest)" },
      { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files (Neotest)" },
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest (Neotest)" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last (Neotest)" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary (Neotest)" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel (Neotest)" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop (Neotest)" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch (Neotest)" },
    },
  },
  {
    'mfussenegger/nvim-dap',
    optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest" },
    },
  },
}

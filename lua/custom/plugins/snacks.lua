---@type LazyPluginSpec[]
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      {
        '<leader>n',
        function()
          if Snacks.config.picker and Snacks.config.picker.enabled then
            Snacks.picker.notifications()
          else
            Snacks.notifier.show_history()
          end
        end,
        desc = 'Notification History',
      },
      {
        '<leader>un',
        function()
          Snacks.notifier.hide()
        end,
        desc = 'Dismiss All Notifications',
      },
    },
  },
  {
    'gbprod/yanky.nvim',
    event = 'bufreadpost',
    opts = {},
    dependencies = { 'folke/snacks.nvim' },
    keys = {
      {
        '<leader>p',
        function()
          Snacks.picker.yanky()
        end,
        mode = { 'n', 'x' },
        desc = 'Open Yank History',
      },
    },
  },
}

vim.loader.enable()

require('basic_options')

require('ui_config')

require('neodev').setup()

require('lsp_config')

require('completion_config')

require('telescope_config')

require('file_navigation_config')

require('vcs_config')

-- vim-slime setup, default to tmux, using the pane in the bottom right
vim.g.slime_target = 'tmux'
vim.g.slime_default_config = {
  socket_name = vim.split(os.getenv('TMUX') or '', ',')[1],
  target_pane = '{bottom-right}',
}

-- From kicksart.nvim, see: https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

require('todo-comments').setup()

-- TODO: setup obsidian on linux
if (vim.loop.os_uname().sysname == 'Darwin') then
  require('obsidian').setup({
    workspaces = {
      {
        name = 'obsidian-vault',
        path = '/Users/debling/Library/CloudStorage/GoogleDrive-d.ebling8@gmail.com/My Drive/obsidian-vault',
      },
    },
  })
end

vim.cmd.colorscheme('base16-gruvbox-dark-hard')

vim.cmd.hi('Normal ctermbg=none guibg=none')

-- Show lsp sever status/progress in the botton right corner
require('fidget').setup({
  notification = {
    window = {
      winblend = 0,
    },
  },
})

require('todo-comments').setup()

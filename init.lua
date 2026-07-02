
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = '80,88'
vim.opt.ruler = true
vim.opt.smarttab = true
vim.opt.showmatch = true
vim.opt.cursorline = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = false
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.history = 250
vim.opt.encoding = 'utf-8'
vim.opt.background = 'dark'
vim.opt.clipboard = "unnamedplus"

vim.pack.add{
  { src = 'https://github.com/neovim/nvim-lspconfig' },
}

vim.cmd('colorscheme habamax')

local agent = require("agent")
agent.setup({
  model = "glm-5.2:cloud",
})

vim.keymap.set("n", "<leader>a", agent.assist, { desc = "Ollama agent assist" })
vim.keymap.set("n", "<leader>f", agent.assist_file, { desc = "Ollama agent assist (file)" })
vim.api.nvim_create_user_command("AgentAssist", agent.assist, {})
vim.api.nvim_create_user_command("AgentAssistFile", agent.assist_file, {})

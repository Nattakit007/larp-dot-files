-- Neovim Lite for Nobara / Embedded C & C++
-- Requires Neovim >= 0.11, git, clangd, and a Nerd Font.
-- Everything lives in this one file. No LazyVim distribution.

-- Disable netrw before nvim-tree loads.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Editor defaults
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.termguicolors = true
opt.signcolumn = 'yes'
opt.cursorline = true
opt.scrolloff = 6
opt.sidescrolloff = 6
opt.wrap = false
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.completeopt = { 'menuone', 'noselect' }
opt.showtabline = 2
opt.clipboard = 'unnamedplus' -- On Wayland: install wl-clipboard.

-- Treat Arduino sketches as C++ for clangd and highlighting.
vim.filetype.add({ extension = { ino = 'cpp' } })

-- Everyday keymaps
local map = vim.keymap.set
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save file' })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Close window' })
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })
map('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Close buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Built-in diagnostics UI
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = '●' },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
})
map('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = 'Previous diagnostic' })
map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Next diagnostic' })

-- Bootstrap lazy.nvim (this is only a plugin manager, NOT LazyVim).
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local output = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Unable to install lazy.nvim:\n', 'ErrorMsg' },
      { output, 'WarningMsg' },
    }, true, {})
    return
  end
end
opt.rtp:prepend(lazypath)

require('lazy').setup({
  -- 1. Colorscheme
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = function()
      require('gruvbox').setup({ contrast = 'hard' })
      vim.cmd.colorscheme('gruvbox')
    end,
  },

  -- 2. Nerd Font file icons
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- 3. VS Code-like side tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup({
        view = { width = 32, side = 'left' },
        renderer = { group_empty = true, indent_markers = { enable = true } },
        update_focused_file = { enable = true },
        filters = { dotfiles = false },
      })
      map('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'Toggle file tree' })
      map('n', '<leader>ef', '<cmd>NvimTreeFindFile<cr>', { desc = 'Reveal file in tree' })
    end,
  },

  -- 4. Small modules from one repo: completion, pairs, comments, tabs, status.
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.completion').setup({
        window = {
          info = { border = 'rounded' },
          signature = { border = 'rounded' },
        },
      })
      require('mini.pairs').setup()
      require('mini.comment').setup()
      require('mini.statusline').setup({ use_icons = true })
      require('mini.tabline').setup({ show_icons = true })
    end,
  },

  -- 5. Git changed-line indicators
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = false,
    },
  },
}, {
  install = { colorscheme = { 'habamax' } },
  checker = { enabled = false }, -- No automatic plugin update checks
  change_detection = { notify = false },
})

-- Insert-mode completion: arrows / Ctrl-N / Ctrl-P, Enter to accept.
map('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true, desc = 'Accept completion or insert newline' })
map('i', '<Tab>', function()
  return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>'
end, { expr = true, desc = 'Next suggestion or Tab' })
map('i', '<S-Tab>', function()
  return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
end, { expr = true, desc = 'Previous suggestion or Shift-Tab' })

-- Neovim 0.11+ native LSP: no nvim-lspconfig or Mason required.
vim.lsp.config('clangd', {
  cmd = {
    'clangd',
    '--background-index',
    '--clang-tidy',
    '--completion-style=detailed',
    '--offset-encoding=utf-8',
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.git' },
})

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Embedded C/C++ LSP keymaps',
  callback = function(event)
    local bopts = { buffer = event.buf }
    map('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', bopts, { desc = 'Go to definition' }))
    map('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', bopts, { desc = 'Go to declaration' }))
    map('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', bopts, { desc = 'Find references' }))
    map('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', bopts, { desc = 'Hover documentation' }))
    map('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', bopts, { desc = 'Rename symbol' }))
    map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action,
      vim.tbl_extend('force', bopts, { desc = 'Code action' }))
    map('n', '<leader>cf', function() vim.lsp.buf.format({ async = true }) end,
      vim.tbl_extend('force', bopts, { desc = 'Format file' }))
  end,
})

-- Enable clangd only after the LspAttach mappings are registered.
vim.lsp.enable('clangd')

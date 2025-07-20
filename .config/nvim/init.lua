-- init.lua - Merged configuration for Windows Neovim
-- Combines settings from both init.vim and init.lua
-- # Run this to install vim-plug
-- iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
--    ni "$($env:LOCALAPPDATA)/nvim-data/site/autoload/plug.vim" -Force


local opt = vim.opt
local g = vim.g
local keymap = vim.keymap

-- Basic Editor Settings
opt.encoding = "utf-8"
opt.number = true
opt.relativenumber = true
opt.showmatch = true          -- Show matching brackets
opt.smarttab = true
opt.autoindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true          -- Convert tabs to spaces
opt.wildmode = {"longest", "list"}  -- Bash-like tab completion
opt.mouse = "a"
opt.colorcolumn = "120"       -- Visual guide at column 120
opt.cursorline = true         -- Highlight current line
opt.ttyfast = true            -- Speed up scrolling
opt.wrap = true               -- Enable line wrapping
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.ignorecase = true         -- Case insensitive search
opt.smartcase = true          -- Case sensitive when uppercase used
opt.hlsearch = false          -- Don't highlight search results
opt.incsearch = true          -- Incremental search
opt.termguicolors = true      -- Enable 24-bit colors
opt.scrolloff = 8             -- Keep 8 lines visible when scrolling
opt.updatetime = 300          -- Faster completion

-- Enable syntax highlighting
vim.cmd('syntax on')

-- Windows-specific shell settings
if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    opt.shell = 'powershell'
    opt.shellcmdflag = '-Command'
    opt.shellquote = '"'
    opt.shellxquote = ''
end

-- Plugin configuration variables
g.NERDTreeDirArrowExpandable = "+"
g.NERDTreeDirArrowCollapsible = "~"
g.python_highlight_all = 1
g.coc_snippet_next = '<Tab>'
g.coc_snippet_prev = '<S-Tab>'

-- Leader key
g.mapleader = " "

-- Key mappings
-- NERDTree mappings
keymap.set('n', '<C-f>', ':NERDTreeFocus<CR>', {noremap = true, silent = true})
keymap.set('n', '<C-n>', ':NERDTree<CR>', {noremap = true, silent = true})
keymap.set('n', '<C-t>', ':NERDTreeToggle<CR>', {noremap = true, silent = true})

-- Other file explorer mappings
keymap.set('n', '<C-b>', ':NvimTreeToggle<CR>', {noremap = true, silent = true})

-- Utility mappings
keymap.set('n', '<C-l>', ':UndotreeToggle<CR>', {noremap = true, silent = true})
keymap.set('n', '<C-g>', ':Files<CR>', {noremap = true, silent = true})
keymap.set('n', '<C-r>', ':Rg<CR>', {noremap = true, silent = true})
keymap.set('n', '<F6>', ':TagbarToggle<CR>', {noremap = true, silent = true})

-- Terminal mappings
keymap.set('n', '<C-x>', ':FloatermToggle<CR>', {noremap = true, silent = true})
keymap.set('t', '<C-x>', '<C-\\><C-n>:FloatermToggle<CR>', {noremap = true, silent = true})

-- Autocompletion navigation
keymap.set('i', '<Tab>', 'pumvisible() ? "\\<C-n>" : "\\<Tab>"', {expr = true, noremap = true})
keymap.set('i', '<S-Tab>', 'pumvisible() ? "\\<C-p>" : "\\<S-Tab>"', {expr = true, noremap = true})

-- Visual mode indentation
keymap.set('v', '<Tab>', '>gv', {noremap = true, silent = true})
keymap.set('v', '<S-Tab>', '<gv', {noremap = true, silent = true})

-- Plugin Manager Setup (vim-plug)
local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin', 'C:/Users/mauli/.config/nvim/plugged')

-- Completion and LSP
Plug('neoclide/coc.nvim', {branch = 'release'})
Plug('hrsh7th/nvim-cmp')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-nvim-lsp')
Plug('hrsh7th/cmp-nvim-lua')
Plug('saadparwaiz1/cmp_luasnip')
Plug('L3MON4D3/LuaSnip')

-- File Explorer
Plug('nvim-tree/nvim-tree.lua')
Plug('nvim-tree/nvim-web-devicons')  -- File icons
Plug('preservim/nerdtree')

-- Text Editing
Plug('tpope/vim-surround')           -- Surrounding text objects
Plug('tpope/vim-commentary')         -- Commenting with gcc & gc
Plug('terryma/vim-multiple-cursors') -- Multiple cursors with Ctrl+N
Plug('matze/vim-move')               -- Move lines/selections
Plug('alvan/vim-closetag')           -- Auto-close HTML tags

-- UI and Appearance
Plug('vim-airline/vim-airline')       -- Status bar
Plug('vim-airline/vim-airline-themes')
Plug('ryanoasis/vim-devicons')       -- Developer icons

-- Navigation and Search
Plug('preservim/tagbar')             -- Code navigation
Plug('junegunn/fzf')                 -- Fuzzy finder
Plug('junegunn/fzf.vim')
Plug('mbbill/undotree')              -- Undo history visualizer

-- Themes
Plug('navarasu/onedark.nvim')
Plug('morhetz/gruvbox')

-- Terminal
Plug('voldikss/vim-floaterm')

-- Git Integration
Plug('tpope/vim-fugitive')

-- Language Support
Plug('vim-python/python-syntax')
Plug('lepture/vim-jinja')

vim.call('plug#end')

-- Theme setup (uncomment your preferred theme)
-- vim.cmd('colorscheme gruvbox')
-- vim.cmd('colorscheme onedark')

-- Auto-commands for specific file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"python", "lua", "vim"},
  callback = function()
    opt.tabstop = 4
    opt.shiftwidth = 4
    opt.expandtab = true
  end,
})

-- Font settings for GUI (Neovide, etc.)
if vim.g.neovide then
    opt.guifont = "CascadiaCode Nerd Font:h12"
end

-- CoC extensions auto-install (optional)
g.coc_global_extensions = {
    'coc-json',
    'coc-git',
    'coc-html',
    'coc-css',
    'coc-python',
    'coc-snippets'
}
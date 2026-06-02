
:set showmatch      " show matching
:set number         " add line number
:set relativenumber " add relative number
:set smarttab       " smart tab
:set autoindent     " indent a new line the same amount as the line just typed
:set tabstop=4      " 
:set wildmode=longest,list " set bash-like tab-completion
:set shiftwidth=4
:set softtabstop=4
:set mouse=a
:set cc=120        " For good coding style
:syntax on          " syntax highlight
:set clipboard=unnamedplus  " using system clipboard

" WSL: clip.exe is write-only and nvim's auto-detect is unreliable here
if has('wsl') && executable('win32yank.exe')
  let g:clipboard = {
    \   'name': 'win32yank',
    \   'copy':  { '+': 'win32yank.exe -i --crlf', '*': 'win32yank.exe -i --crlf' },
    \   'paste': { '+': 'win32yank.exe -o --lf',  '*': 'win32yank.exe -o --lf'  },
    \ }
" Remote SSH (bare Linux, no DISPLAY): use OSC 52 so yanks reach the
" local terminal's clipboard. Most terminals only implement OSC 52 copy,
" not paste — so pasting INTO vim usually still needs terminal paste
" (Ctrl-Shift-V) or a register that has the data already.
elseif !empty($SSH_TTY) && has('nvim-0.10')
  let g:clipboard = {
    \ 'name': 'OSC 52',
    \ 'copy': {
    \   '+': v:lua.require('vim.ui.clipboard.osc52').copy('+'),
    \   '*': v:lua.require('vim.ui.clipboard.osc52').copy('*'),
    \ },
    \ 'paste': {
    \   '+': v:lua.require('vim.ui.clipboard.osc52').paste('+'),
    \   '*': v:lua.require('vim.ui.clipboard.osc52').paste('*'),
    \ },
  \ }
endif
:set cursorline   " highlight current cursorline
:set ttyfast      " seepd up scrorring in Vim
	

let g:NERDTreeDirArrowExpandable="+"
let g:NERDTreeDirArrowCollapsible="~"
let g:python_highlight_all = 1

nnoremap <C-f> :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-l> :UndotreeToggle<CR>
nnoremap <C-g> :Files<CR>
nnoremap <C-r> :Rg<CR>
nnoremap <C-b> :NvimTreeToggle<CR>

" Terminal mapping
nnoremap <C-x> :FlotermToggle<CR>
tnoremap <C-x> <C-\><C-n>:FlotermToggle<CR>


" Use <Tab> for autocompletion navigation
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" <CR> confirm is handled by nvim-cmp mapping below (asyncomplete is not installed)

" Use <Tab> to indent selected lines in visual mode
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" coc.nvim disabled in favor of nvim-cmp + nvim-lspconfig
" let g:coc_snippet_next = '<Tab>'
" let g:coc_snippet_prev = '<S-Tab>'

nmap <F6> :TagbarToggle<CR>

call plug#begin('~/.config/nvim/plugged')

" Add your plugins here
" coc.nvim disabled; using nvim-cmp + nvim-lspconfig instead.
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lua'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip'

" LSP server config + AI completion via local OpenAI-compatible endpoint
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/plenary.nvim'
Plug 'milanglacier/minuet-ai.nvim'

Plug 'http://github.com/tpope/vim-surround' " Surrounding ysw)
Plug 'https://github.com/tpope/vim-commentary' " For Commenting gcc & gc
Plug 'https://github.com/preservim/nerdtree' ", {'on': 'NERDTreeToggle'}
Plug 'https://github.com/vim-airline/vim-airline' " Status bar
Plug 'https://github.com/ryanoasis/vim-devicons' " Developer Icons
Plug 'https://github.com/preservim/tagbar', {'on': 'TagbarToggle'} " Tagbar for code navigation
Plug 'https://github.com/junegunn/fzf.vim' " Fuzzy Finder, Needs Silversearcher-ag for :Ag
Plug 'https://github.com/preservim/nerdtree'
Plug 'https://github.com/junegunn/fzf'
Plug 'https://github.com/navarasu/onedark.nvim'
Plug 'https://github.com/morhetz/gruvbox'
Plug 'https://github.com/vim-airline/vim-airline-themes'
Plug 'https://github.com/mbbill/undotree'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'https://github.com/lepture/vim-jinja'
Plug 'https://github.com/tpope/vim-fugitive'
Plug 'https://github.com/terryma/vim-multiple-cursors'  " CTRL + N for multiple corsors
Plug 'https://github.com/matze/vim-move'
Plug 'voldikss/vim-floaterm'
Plug 'vim-python/python-syntax'
Plug 'alvan/vim-closetag'
call plug#end()

" ============================================================
" LSP + AI completion (nvim-cmp + nvim-lspconfig + minuet-ai)
" ============================================================
lua << EOF
local ok_cmp, cmp           = pcall(require, 'cmp')
local ok_lsp, lspconfig     = pcall(require, 'lspconfig')
local ok_minuet, minuet     = pcall(require, 'minuet')
local ok_cmplsp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')

if not (ok_cmp and ok_lsp and ok_minuet and ok_cmplsp) then
  vim.schedule(function()
    vim.notify('AI/LSP plugins missing — run :PlugInstall and restart nvim',
               vim.log.levels.WARN)
  end)
  return
end

-- Local vLLM @ :8000, OpenAI-compatible chat/completions.
-- Set $MINUET_MODEL to your served model name (find it via
--   curl http://localhost:8000/v1/models | jq '.data[].id'
-- ). vLLM does not enforce the bearer token by default, so any
-- value for $MINUET_API_KEY works; we name the env var to keep
-- the literal out of this file.
minuet.setup({
  provider = 'openai_compatible',
  provider_options = {
    openai_compatible = {
      end_point = 'http://localhost:8000/v1/chat/completions',
      api_key   = 'MINUET_API_KEY',
      model     = vim.env.MINUET_MODEL or 'YOUR_MODEL_NAME',
      name      = 'local-vllm',
      stream    = true,
      optional  = { max_tokens = 256, top_p = 0.9 },
    },
  },
  virtualtext = { auto_trigger_ft = {} },
  cmp         = { enable_auto_complete = true },
})

local luasnip = require('luasnip')
cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>']      = cmp.mapping.confirm({ select = false }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.abort(),
  }),
  -- LSP first (high priority), local vLLM second, then snippets/buffer/path.
  sources = cmp.config.sources({
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'minuet',   priority = 100, max_item_count = 3 },
    { name = 'luasnip',  priority = 50  },
  }, {
    { name = 'buffer' },
    { name = 'path'   },
  }),
  -- minuet streams; raise fetch timeout so partial completions arrive
  performance = { fetching_timeout = 2000 },
})

lspconfig.pylsp.setup({
  capabilities = cmp_nvim_lsp.default_capabilities(),
})
EOF


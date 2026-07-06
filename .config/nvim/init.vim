
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
:set undofile     " persistent undo across sessions (pairs with Ctrl-l Undotree)
	

let g:NERDTreeDirArrowExpandable="+"
let g:NERDTreeDirArrowCollapsible="~"

nnoremap <C-f> :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-l> :UndotreeToggle<CR>
nnoremap <C-g> :Files<CR>
" Ctrl-p (not Ctrl-r, which stays vim's redo) for project-wide ripgrep search
nnoremap <C-p> :Rg<CR>

" Terminal mapping — works from normal, insert and terminal mode (like
" VS Code's Ctrl+`). Insert-mode Ctrl-x normally prefixes vim's built-in
" completion submode, which nvim-cmp makes redundant.
nnoremap <C-x> :FloatermToggle<CR>
inoremap <C-x> <Esc>:FloatermToggle<CR>
tnoremap <C-x> <C-\><C-n>:FloatermToggle<CR>


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

nmap <F6> :AerialToggle<CR>

call plug#begin('~/.config/nvim/plugged')

" Add your plugins here
" coc.nvim disabled; using nvim-cmp + nvim-lspconfig instead.
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
" Snippets in LSP completions expand via nvim 0.10+'s built-in vim.snippet —
" no snippet-engine plugin needed.

" LSP server config
Plug 'neovim/nvim-lspconfig'

" (vim-commentary removed: gcc/gc commenting is built into nvim 0.10+)
Plug 'http://github.com/tpope/vim-surround' " Surrounding ysw)
Plug 'https://github.com/preservim/nerdtree' ", {'on': 'NERDTreeToggle'}
Plug 'https://github.com/vim-airline/vim-airline' " Status bar
Plug 'https://github.com/ryanoasis/vim-devicons' " Developer Icons
" nvim-0.11 branch: aerial's master requires nvim 0.12+
Plug 'stevearc/aerial.nvim', {'branch': 'nvim-0.11'} " Code outline from LSP/treesitter (no ctags needed)
Plug 'https://github.com/junegunn/fzf.vim' " Fuzzy Finder; :Rg needs ripgrep (installed by setup)
Plug 'https://github.com/junegunn/fzf'
Plug 'https://github.com/navarasu/onedark.nvim'
Plug 'https://github.com/vim-airline/vim-airline-themes'
Plug 'https://github.com/mbbill/undotree'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'https://github.com/lepture/vim-jinja'
Plug 'https://github.com/tpope/vim-fugitive'
Plug 'lewis6991/gitsigns.nvim' " Git change markers in the gutter
Plug 'windwp/nvim-autopairs'   " Auto-close brackets/quotes
" vim-multiple-cursors is archived upstream; vim-visual-multi is its
" successor with the same Ctrl-N workflow.
Plug 'https://github.com/mg979/vim-visual-multi'  " CTRL + N for multiple cursors
Plug 'https://github.com/matze/vim-move'
Plug 'voldikss/vim-floaterm'
" master branch: frozen but stable; the rewritten main branch needs the
" tree-sitter CLI installed, which we don't ship.
Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'master', 'do': ':TSUpdate'} " Parser-based highlighting
Plug 'alvan/vim-closetag'
call plug#end()

" silent! — first launch before :PlugInstall must not error
silent! colorscheme onedark

" ============================================================
" LSP completion (nvim-cmp + nvim-lspconfig)
" ============================================================
lua << EOF
local ok_cmp, cmp           = pcall(require, 'cmp')
local ok_cmplsp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
-- nvim-lspconfig is required only as a *source of default server configs*
-- (it ships `lsp/<server>.lua` files picked up by nvim 0.11's vim.lsp.config).
-- We don't call into its deprecated framework API. Presence-check via rtp:
local lspconfig_present = #vim.api.nvim_get_runtime_file('lsp/basedpyright.lua', false) > 0

if not (ok_cmp and ok_cmplsp and lspconfig_present) then
  vim.schedule(function()
    vim.notify('LSP plugins missing — run :PlugInstall and restart nvim',
               vim.log.levels.WARN)
  end)
  return
end

cmp.setup({
  snippet = {
    expand = function(args) vim.snippet.expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>']      = cmp.mapping.confirm({ select = false }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.abort(),
  }),
  -- LSP first (high priority), then snippets/buffer/path.
  sources = cmp.config.sources({
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'nvim_lsp_signature_help' },  -- param hints while typing, like VS Code
  }, {
    { name = 'buffer' },
    { name = 'path'   },
  }),
  -- Inline preview of the selected completion, like VS Code's ghost text.
  experimental = { ghost_text = true },
})

-- Python LSP, VS Code-style: basedpyright (open-source Pylance equivalent —
-- typed completions, auto-imports, hover) + ruff (lint + format, same tool
-- as the VS Code ruff extension). nvim 0.11+ API: vim.lsp.config merges over
-- nvim-lspconfig's lsp/<server>.lua defaults; vim.lsp.enable starts them.
local caps = cmp_nvim_lsp.default_capabilities()
vim.lsp.config('basedpyright', { capabilities = caps })
vim.lsp.config('ruff',         { capabilities = caps })
vim.lsp.enable({ 'basedpyright', 'ruff' })

-- ruff also answers hover requests; keep hover exclusively on basedpyright.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end
  end,
})

-- Format Python on save with ruff (mirrors VS Code editor.formatOnSave).
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*.py',
  callback = function(ev)
    if #vim.lsp.get_clients({ bufnr = ev.buf, name = 'ruff' }) > 0 then
      vim.lsp.buf.format({ bufnr = ev.buf, name = 'ruff', timeout_ms = 2000 })
    end
  end,
})

-- Code outline on F6 (replaces tagbar; reads LSP/treesitter, no ctags binary).
local ok_aerial, aerial = pcall(require, 'aerial')
if ok_aerial then aerial.setup({}) end

-- Show diagnostic messages inline, VS Code-style (nvim 0.11 turned
-- virtual-text diagnostics off by default — only underlines/signs remain).
vim.diagnostic.config({ virtual_text = true })

-- Auto-close brackets/quotes; the cmp hook appends () and places the cursor
-- inside when a function/method completion is accepted (Pylance behaviour).
local ok_pairs, npairs = pcall(require, 'nvim-autopairs')
if ok_pairs then
  npairs.setup({})
  local ok_cmp_pairs, cmp_autopairs = pcall(require, 'nvim-autopairs.completion.cmp')
  if ok_cmp_pairs then
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  end
end

-- Git change markers in the gutter. Deliberately NO keymaps — operations are
-- available as commands when needed (:Gitsigns blame_line, :Gitsigns
-- preview_hunk, :Gitsigns reset_hunk).
local ok_gs, gitsigns = pcall(require, 'gitsigns')
if ok_gs then gitsigns.setup({}) end

-- Reopen a file at the last cursor position (VS Code does this by default).
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Treesitter highlighting. Handles both nvim-treesitter APIs: the frozen
-- `master` branch (configs.setup) and the rewritten `main` branch
-- (install + vim.treesitter.start via autocmd).
local ts_langs = { 'python', 'bash', 'lua', 'vim', 'json', 'yaml', 'markdown' }
local ok_ts_configs, ts_configs = pcall(require, 'nvim-treesitter.configs')
if ok_ts_configs and ts_configs.setup then
  ts_configs.setup({ ensure_installed = ts_langs, highlight = { enable = true } })
elseif pcall(require, 'nvim-treesitter') then
  require('nvim-treesitter').install(ts_langs)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = ts_langs,
    callback = function() pcall(vim.treesitter.start) end,
  })
end
EOF


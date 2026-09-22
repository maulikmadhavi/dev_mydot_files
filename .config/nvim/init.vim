" ============================================================
" [OPTIONS]
" ============================================================
set encoding=utf-8

" Whitespace / indentation
set wrap
set textwidth=79
set formatoptions=tcqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set noshiftround
set smarttab
set autoindent

" Display
set showmatch
set number
set relativenumber
set wildmode=longest,list
set mouse=a
set cc=120
set cursorline
set ttyfast           " speed up scrolling in Vim
set undofile          " persistent undo across sessions (pairs with <leader>u Undotree)

syntax on
set clipboard=unnamedplus

" ============================================================
" [CLIPBOARD] — WSL / SSH clipboard
" ============================================================
" WSL: clip.exe is write-only and nvim's auto-detect is unreliable here.
" Copies go through jobstart (fire-and-forget) so every y/dd/x does not
" block ~80ms on the Windows process; paste stays synchronous.
if has('wsl') && executable('win32yank.exe')
  let s:win32yank = exepath('win32yank.exe')
  let s:clip_job = -1
  function! s:ClipCopy(lines, regtype) abort
    " Serialize: a still-running previous write must land first, or two
    " rapid yanks can reach the Windows clipboard out of order.
    if s:clip_job > 0
      call jobwait([s:clip_job], 1000)
    endif
    let s:clip_job = jobstart([s:win32yank, '-i', '--crlf'])
    call chansend(s:clip_job, a:lines)
    call chanclose(s:clip_job, 'stdin')
  endfunction
  " nvim kills jobstart'd jobs on exit, so a yank right before :wq never
  " reached Windows. Wait (bounded) for the last copy before leaving.
  augroup ClipFlush
    autocmd!
    autocmd VimLeavePre * if s:clip_job > 0 | call jobwait([s:clip_job], 1000) | endif
  augroup END
  let g:clipboard = {
    \   'name': 'win32yank-async',
    \   'copy':  { '+': function('s:ClipCopy'), '*': function('s:ClipCopy') },
    \   'paste': { '+': s:win32yank . ' -o --lf', '*': s:win32yank . ' -o --lf' },
    \ }
" Remote SSH (bare Linux, no DISPLAY): OSC 52 copy so yanks reach the
" local clipboard. Paste is deliberately NOT OSC 52: Windows Terminal and
" VS Code never answer the OSC 52 paste query, so nvim froze for seconds
" on every p / getreg('+'). Reading + now falls back to the unnamed
" register; paste from the local machine with terminal paste (Ctrl-Shift-V).
elseif !empty($SSH_TTY) && has('nvim-0.10')
  function! s:ClipPasteFallback() abort
    return [getreg('"', 1, 1), getregtype('"')]
  endfunction
  let g:clipboard = {
    \ 'name': 'OSC 52 copy-only',
    \ 'copy': {
    \   '+': v:lua.require('vim.ui.clipboard.osc52').copy('+'),
    \   '*': v:lua.require('vim.ui.clipboard.osc52').copy('*'),
    \ },
    \ 'paste': {
    \   '+': function('s:ClipPasteFallback'),
    \   '*': function('s:ClipPasteFallback'),
    \ },
  \ }
endif

" ============================================================
" [PLUGINS]
" ============================================================
" Plugin variable defaults (must be set before plug#end)
let g:move_map_keys = 0           " vim-move: disable default Alt-j/k; remapped to <leader>J/K below
let g:NERDTreeDirArrowExpandable  = "+"
let g:NERDTreeDirArrowCollapsible = "~"

call plug#begin('~/.config/nvim/plugged')

" Completion engine
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
" Snippets expand via nvim 0.10+'s built-in vim.snippet — no extra plugin needed.

" LSP server config
Plug 'neovim/nvim-lspconfig'

" AI ghost-text completion (Copilot-style) from a local OpenAI-compatible server
Plug 'nvim-lua/plenary.nvim'          " required by minuet
Plug 'milanglacier/minuet-ai.nvim'

" Editing utilities
Plug 'http://github.com/tpope/vim-surround'           " Surrounding ysw)
Plug 'https://github.com/mg979/vim-visual-multi'       " CTRL+N multiple cursors
Plug 'https://github.com/matze/vim-move'               " Move lines/blocks
Plug 'windwp/nvim-autopairs'                           " Auto-close brackets/quotes

" File / search
Plug 'https://github.com/preservim/nerdtree'           " File explorer
Plug 'https://github.com/junegunn/fzf'
Plug 'https://github.com/junegunn/fzf.vim'             " :Files :Rg (ripgrep required)

" UI / appearance
Plug 'https://github.com/vim-airline/vim-airline'      " Status bar
Plug 'https://github.com/vim-airline/vim-airline-themes'
Plug 'https://github.com/ryanoasis/vim-devicons'       " Developer icons
Plug 'https://github.com/navarasu/onedark.nvim'        " Colorscheme

" Code intelligence
Plug 'stevearc/aerial.nvim', {'branch': 'nvim-0.11'}  " Code outline (LSP/treesitter)
Plug 'https://github.com/mbbill/undotree'              " Visual undo history
Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'master', 'do': ':TSUpdate'}

" Git
Plug 'https://github.com/tpope/vim-fugitive'
Plug 'lewis6991/gitsigns.nvim'

" Language support
Plug 'https://github.com/lepture/vim-jinja'
Plug 'alvan/vim-closetag'

call plug#end()

" ============================================================
" [APPEARANCE]
" ============================================================
silent! colorscheme onedark

" ============================================================
" [KEYBINDINGS]
" ============================================================
" Policy: identical behaviour on Windows PowerShell, WSL, and bare Linux —
" including over SSH, tmux and screen.
"
"   Use:    <leader> (Space) + letter, and plain Ctrl+letter.
"   Avoid:  Alt/Meta      — gnome-terminal steals Alt-f/e/v/s/t/h for its
"                           menus, and over SSH/tmux Alt is sent as an ESC
"                           prefix that races with a real <Esc>.
"           <C-Space>     — sends NUL; IBus on Ubuntu grabs it by default.
"           <C-v>, <C-c>  — Windows Terminal binds both to paste/copy, so
"                           they never reach nvim.
"           <C-s>, <C-q>  — terminal flow control (XON/XOFF).
let mapleader = " "
nnoremap <Space> <Nop>

" --- File / search ---
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>r :Rg<CR>
" Ctrl-p as a second binding for :Rg (shadows `k` synonym, which is fine)
nnoremap <C-p> :Rg<CR>

" --- Panels / toggles ---
nnoremap <leader>u :UndotreeToggle<CR>
nnoremap <leader>t :FloatermToggle<CR>
nnoremap <leader>o :AerialToggle<CR>
" F-key aliases work where function keys survive (screen/tmux/SSH)
nnoremap <F6> :AerialToggle<CR>
nnoremap <F7> :FloatermToggle<CR>
inoremap <F7> <Esc>:FloatermToggle<CR>
tnoremap <F7> <C-\><C-n>:FloatermToggle<CR>

" --- Editing ---
" Blockwise-visual: Windows Terminal binds <C-v> to paste, so use <leader>v
nnoremap <leader>v <C-v>
" Indent/unindent selection, keeping the visual range
vnoremap <Tab>   >gv
vnoremap <S-Tab> <gv
" Move lines/blocks (uppercase avoids conflict with j/k cursor motion)
nmap <leader>J <Plug>MoveLineDown
nmap <leader>K <Plug>MoveLineUp
vmap <leader>J <Plug>MoveBlockDown
vmap <leader>K <Plug>MoveBlockUp

" --- Window navigation ---
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" --- Quality of life ---
nnoremap <leader>w :w<CR>
nnoremap <leader>h :nohlsearch<CR>

" ============================================================
" [LUA CONFIG]
" ============================================================
lua << EOF

-- ── LSP + nvim-cmp ──────────────────────────────────────────────────────────
local ok_cmp,    cmp          = pcall(require, 'cmp')
local ok_cmplsp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
-- nvim-lspconfig is used as a source of default server configs (lsp/*.lua).
-- Presence-check via runtime path:
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
    -- <C-l> portable trigger; <C-Space> kept for muscle memory (unreliable on Ubuntu)
    ['<C-l>']     = cmp.mapping.complete(),
    ['<C-Space>'] = cmp.mapping.complete(),
    -- Accept: AI ghost text > selected completion > literal key
    ['<C-y>'] = cmp.mapping(function(fallback)
      local ok_vt, vt = pcall(require, 'minuet.virtualtext')
      if ok_vt and vt.action.is_visible() then
        vt.action.accept()
      elseif cmp.visible() then
        cmp.confirm({ select = true })
      else
        fallback()
      end
    end, { 'i' }),
    -- Dismiss: AI ghost text > completion popup > literal key
    ['<C-e>'] = cmp.mapping(function(fallback)
      local ok_vt, vt = pcall(require, 'minuet.virtualtext')
      if ok_vt and vt.action.is_visible() and vt.action.dismiss then
        vt.action.dismiss()
      elseif cmp.visible() then
        cmp.abort()
      else
        fallback()
      end
    end, { 'i' }),
    -- Smart Tab: accept AI ghost text > navigate completion menu > literal tab
    ['<Tab>'] = cmp.mapping(function(fallback)
      local ok_vt, vt = pcall(require, 'minuet.virtualtext')
      if ok_vt and vt.action.is_visible() then
        vt.action.accept()
      elseif cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item() else fallback() end
    end, { 'i' }),
  }),
  -- LSP first (high priority), then buffer/path.
  sources = cmp.config.sources({
    { name = 'nvim_lsp',                  priority = 1000 },
    { name = 'nvim_lsp_signature_help' },  -- param hints while typing
  }, {
    { name = 'buffer' },
    { name = 'path'   },
  }),
  experimental = { ghost_text = true },  -- inline preview like VS Code
})

-- ── LSP servers ─────────────────────────────────────────────────────────────
-- Python: basedpyright (open-source Pylance) + ruff (lint + format).
-- nvim 0.11+ API: vim.lsp.config merges over nvim-lspconfig defaults.
local caps = cmp_nvim_lsp.default_capabilities()
vim.lsp.config('basedpyright', { capabilities = caps })
vim.lsp.config('ruff',         { capabilities = caps })
vim.lsp.enable({ 'basedpyright', 'ruff' })

-- ruff also answers hover; keep hover exclusively on basedpyright.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end

    -- LSP keybindings — scoped to the buffer that just attached an LSP client
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set('n', 'gd',         vim.lsp.buf.definition,   opts)
    vim.keymap.set('n', 'gr',         vim.lsp.buf.references,   opts)
    vim.keymap.set('n', 'K',          vim.lsp.buf.hover,        opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,  opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,       opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
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

-- Show diagnostic messages inline (nvim 0.11 turned virtual_text off by default).
vim.diagnostic.config({ virtual_text = true })

-- ── Code outline ─────────────────────────────────────────────────────────────
-- Aerial: replaces tagbar; reads LSP/treesitter, no ctags binary required.
local ok_aerial, aerial = pcall(require, 'aerial')
if ok_aerial then aerial.setup({}) end

-- ── Autopairs ────────────────────────────────────────────────────────────────
-- Auto-close brackets/quotes; cmp hook appends () on function completions.
local ok_pairs, npairs = pcall(require, 'nvim-autopairs')
if ok_pairs then
  npairs.setup({})
  local ok_cmp_pairs, cmp_autopairs = pcall(require, 'nvim-autopairs.completion.cmp')
  if ok_cmp_pairs then
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  end
end

-- ── Gitsigns ─────────────────────────────────────────────────────────────────
-- Git change markers in the gutter + hunk navigation.
local ok_gs, gitsigns = pcall(require, 'gitsigns')
if ok_gs then
  gitsigns.setup({
    on_attach = function(bufnr)
      local gs   = package.loaded.gitsigns
      local opts = { buffer = bufnr, silent = true }
      vim.keymap.set('n', ']c', gs.next_hunk, opts)
      vim.keymap.set('n', '[c', gs.prev_hunk, opts)
    end,
  })
end

-- ── Treesitter ───────────────────────────────────────────────────────────────
-- Handles both nvim-treesitter APIs: frozen `master` branch (configs.setup)
-- and the rewritten `main` branch (install + vim.treesitter.start via autocmd).
local ts_langs = { 'python', 'bash', 'lua', 'vim', 'json', 'yaml', 'markdown' }
local ok_ts_configs, ts_configs = pcall(require, 'nvim-treesitter.configs')
if ok_ts_configs and ts_configs.setup then
  ts_configs.setup({ ensure_installed = ts_langs, highlight = { enable = true } })
elseif pcall(require, 'nvim-treesitter') then
  require('nvim-treesitter').install(ts_langs)
  vim.api.nvim_create_autocmd('FileType', {
    pattern  = ts_langs,
    callback = function() pcall(vim.treesitter.start) end,
  })
end

-- ── AI ghost-text (minuet-ai) ────────────────────────────────────────────────
-- Copilot-style inline suggestions from a local OpenAI-compatible server
-- (vLLM, llama.cpp, LM Studio, Ollama…).
--
-- Zero config: the served model is auto-discovered from GET /v1/models.
-- If the server is unreachable, AI completion silently stays off.
--
-- Optional env overrides:
--   MINUET_ENDPOINT  base URL   (default http://localhost:8000/v1)
--   MINUET_MODEL     model id   (default: first model the server lists)
--   MINUET_API_KEY   bearer     (default "dummy"; vLLM ignores it)
--
-- Keys while a grey suggestion is visible: Tab or Ctrl-y accept, Ctrl-e dismiss
-- (all defined in cmp.setup's mapping table above).
local ok_minuet, minuet = pcall(require, 'minuet')
if ok_minuet then
  local base = (vim.env.MINUET_ENDPOINT or 'http://localhost:8000/v1'):gsub('/+$', '')
  vim.env.MINUET_API_KEY = vim.env.MINUET_API_KEY or 'dummy'

  local function setup_minuet(model)
    minuet.setup({
      provider = 'openai_compatible',
      provider_options = {
        openai_compatible = {
          end_point = base .. '/chat/completions',
          api_key   = 'MINUET_API_KEY',  -- env var NAME, keeps the literal out of git
          model     = model,
          name      = 'local-llm',
          stream    = true,
          optional  = { max_tokens = 256, top_p = 0.9 },
        },
      },
      virtualtext = {
        auto_trigger_ft = { '*' },
        -- Accept/dismiss handled by <Tab>/<C-y>/<C-e> in cmp.setup above.
        keymap = {
          accept  = '<Plug>(minuet-accept-unused)',
          dismiss = '<Plug>(minuet-dismiss-unused)',
        },
      },
      notify = 'error',  -- quiet unless something is actually broken
    })
    -- setup runs async (after model discovery), which is later than the
    -- FileType event for buffers opened at launch — flip the per-buffer flag.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
        vim.b[buf].minuet_virtual_text_auto_trigger = true
      end
    end
  end

  if vim.env.MINUET_MODEL then
    setup_minuet(vim.env.MINUET_MODEL)
  else
    -- Async probe; nvim startup is never blocked by a missing server.
    vim.system({ 'curl', '-fsS', '-m', '2', base .. '/models' }, { text = true }, function(out)
      if out.code == 0 and out.stdout then
        local ok_json, decoded = pcall(vim.json.decode, out.stdout)
        local model = ok_json and decoded.data and decoded.data[1] and decoded.data[1].id
        if model then
          vim.schedule(function() setup_minuet(model) end)
        end
      end
    end)
  end
end

-- ── Utilities ────────────────────────────────────────────────────────────────
-- Reopen a file at the last cursor position (VS Code does this by default).
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

EOF

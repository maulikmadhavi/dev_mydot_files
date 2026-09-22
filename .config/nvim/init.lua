-- ============================================================
-- Options
-- ============================================================
local opt = vim.opt
opt.showmatch      = true               -- show matching bracket
opt.number         = true               -- line numbers
opt.relativenumber = true               -- relative line numbers
opt.smarttab       = true
opt.autoindent     = true               -- indent a new line like the one above
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.softtabstop    = 4
opt.wildmode       = 'longest,list'     -- bash-like tab-completion
opt.mouse          = 'a'
opt.colorcolumn    = '120'              -- for good coding style
opt.clipboard      = 'unnamedplus'      -- use the system clipboard
opt.cursorline     = true               -- highlight the current line
opt.undofile       = true               -- persistent undo (pairs with <leader>u Undotree)
vim.cmd('syntax on')

-- ============================================================
-- Clipboard providers
-- ============================================================
-- WSL: clip.exe is write-only and nvim's auto-detect is unreliable here.
-- Copies go through jobstart (fire-and-forget) so every y/dd/x does not
-- block ~80ms on the Windows process; paste stays synchronous.
if vim.fn.has('wsl') == 1 and vim.fn.executable('win32yank.exe') == 1 then
  local win32yank = vim.fn.exepath('win32yank.exe')
  local clip_job = -1
  local function clip_copy(lines, _regtype)
    -- Serialize: a still-running previous write must land first, or two
    -- rapid yanks can reach the Windows clipboard out of order.
    if clip_job > 0 then vim.fn.jobwait({ clip_job }, 1000) end
    clip_job = vim.fn.jobstart({ win32yank, '-i', '--crlf' })
    vim.fn.chansend(clip_job, lines)
    vim.fn.chanclose(clip_job, 'stdin')
  end
  -- nvim kills jobstart'd jobs on exit, so a yank right before :wq never
  -- reached Windows. Wait (bounded) for the last copy before leaving.
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('ClipFlush', { clear = true }),
    callback = function()
      if clip_job > 0 then vim.fn.jobwait({ clip_job }, 1000) end
    end,
  })
  vim.g.clipboard = {
    name  = 'win32yank-async',
    copy  = { ['+'] = clip_copy, ['*'] = clip_copy },
    paste = { ['+'] = { win32yank, '-o', '--lf' }, ['*'] = { win32yank, '-o', '--lf' } },
  }
-- Remote SSH (bare Linux, no DISPLAY): OSC 52 copy so yanks reach the
-- local clipboard. Paste is deliberately NOT OSC 52: Windows Terminal and
-- VS Code never answer the OSC 52 paste query, so nvim froze for seconds
-- on every p / getreg('+'). Reading + now falls back to the unnamed
-- register; paste from the local machine with terminal paste (Ctrl-Shift-V).
elseif (vim.env.SSH_TTY or '') ~= '' and vim.fn.has('nvim-0.10') == 1 then
  local osc52 = require('vim.ui.clipboard.osc52')
  local function paste_fallback()
    return { vim.fn.getreg('"', 1, 1), vim.fn.getregtype('"') }
  end
  vim.g.clipboard = {
    name  = 'OSC 52 copy-only',
    copy  = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
    paste = { ['+'] = paste_fallback, ['*'] = paste_fallback },
  }
end

-- ============================================================
-- Keybinding policy: identical behaviour on Windows PowerShell,
-- WSL, and bare Linux — including over SSH, tmux and screen.
--
--   Use:    <leader> (Space) + letter, and plain Ctrl+letter.
--   Avoid:  Alt/Meta      — gnome-terminal steals Alt-f/e/v/s/t/h for its
--                           menus, and over SSH/tmux Alt is sent as an ESC
--                           prefix that races with a real <Esc>.
--           <C-Space>     — sends NUL; IBus on Ubuntu grabs it by default.
--           <C-v>, <C-c>  — Windows Terminal binds both to paste/copy, so
--                           they never reach nvim.
--           <C-s>, <C-q>  — terminal flow control (XON/XOFF).
-- ============================================================
vim.g.mapleader = ' '
local map = vim.keymap.set   -- noremap by default
map('n', '<Space>', '<Nop>')

-- vim-move defaults to Alt-h/j/k/l; remapped to <leader>j/k after plug#end().
vim.g.move_map_keys = 0

vim.g.NERDTreeDirArrowExpandable  = '+'
vim.g.NERDTreeDirArrowCollapsible = '~'

map('n', '<leader>e', ':NERDTreeToggle<CR>')
map('n', '<leader>f', ':Files<CR>')
map('n', '<leader>r', ':Rg<CR>')
map('n', '<leader>u', ':UndotreeToggle<CR>')
-- Blockwise-visual (multiline column edit). Windows Terminal binds ctrl+v to
-- paste, so plain <C-v> never reaches nvim there — and VS Code's terminal and
-- most SSH clients have the same habit. <leader>v always gets through.
map('n', '<leader>v', '<C-v>')
-- Panel toggles also have F-key bindings below; these leader aliases work even
-- where function keys are mangled (screen/tmux without matching terminfo).
map('n', '<leader>t', ':FloatermToggle<CR>')
map('n', '<leader>o', ':AerialToggle<CR>')
-- Ctrl-p kept as a second binding for :Rg — in normal mode it is just a
-- synonym for `k`, so it shadows nothing worth keeping. (Ctrl-r is
-- deliberately left alone: it is vim's redo.)
map('n', '<C-p>', ':Rg<CR>')

-- NERDTree used to own Ctrl-n as well, but vim-visual-multi defaults to
-- Ctrl-n and its plugin file is sourced at plug#end() — i.e. after this
-- point — so that mapping was being silently overwritten anyway.
-- Multi-cursor keeps Ctrl-n; the file explorer is <leader>e.

-- Floating terminal on F7 (pairs with F6 Aerial). It has to work from insert
-- and terminal mode too, where <leader> cannot reach, so it gets an F-key
-- instead of a leader mapping.
map('n', '<F7>', ':FloatermToggle<CR>')
map('i', '<F7>', '<Esc>:FloatermToggle<CR>')
map('t', '<F7>', '<C-\\><C-n>:FloatermToggle<CR>')
map('n', '<F6>', ':AerialToggle<CR>')

-- Insert-mode <Tab>/<S-Tab> are smart mappings defined in cmp.setup below:
-- accept AI ghost text > navigate completion menu > literal tab.
-- <CR> confirm is handled by nvim-cmp mapping below.

-- <Tab> indents selected lines in Visual mode. 'x', not 'v': 'v' also covers
-- Select mode, where nvim's snippet placeholders need <Tab> to jump.
map('x', '<Tab>', '>gv')
map('x', '<S-Tab>', '<gv')

-- ============================================================
-- Plugins (vim-plug)
-- ============================================================
if #vim.api.nvim_get_runtime_file('autoload/plug.vim', false) == 0 then
  vim.schedule(function()
    vim.notify('vim-plug missing — re-run setup to install plug.vim', vim.log.levels.WARN)
  end)
  return
end

local Plug = vim.fn['plug#']
vim.call('plug#begin', '~/.config/nvim/plugged')

Plug('hrsh7th/nvim-cmp')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-nvim-lsp')
Plug('hrsh7th/cmp-nvim-lsp-signature-help')
-- Snippets in LSP completions expand via nvim 0.10+'s built-in vim.snippet —
-- no snippet-engine plugin needed.

-- LSP server config
Plug('neovim/nvim-lspconfig')

-- AI ghost-text completion (Copilot-style) from a local OpenAI-compatible server
Plug('nvim-lua/plenary.nvim')          -- required by minuet
Plug('milanglacier/minuet-ai.nvim')

-- (vim-commentary removed: gcc/gc commenting is built into nvim 0.10+)
Plug('http://github.com/tpope/vim-surround')           -- Surrounding ysw)
Plug('https://github.com/preservim/nerdtree')
Plug('https://github.com/vim-airline/vim-airline')     -- Status bar
Plug('https://github.com/ryanoasis/vim-devicons')      -- Developer Icons
-- nvim-0.11 branch: aerial's master requires nvim 0.12+
Plug('stevearc/aerial.nvim', { branch = 'nvim-0.11' }) -- Code outline from LSP/treesitter (no ctags needed)
Plug('https://github.com/junegunn/fzf.vim')            -- Fuzzy Finder; :Rg needs ripgrep (installed by setup)
Plug('https://github.com/junegunn/fzf')
Plug('https://github.com/navarasu/onedark.nvim')
Plug('https://github.com/vim-airline/vim-airline-themes')
Plug('https://github.com/mbbill/undotree')
Plug('https://github.com/lepture/vim-jinja')
Plug('https://github.com/tpope/vim-fugitive')
Plug('lewis6991/gitsigns.nvim')   -- Git change markers in the gutter
Plug('windwp/nvim-autopairs')     -- Auto-close brackets/quotes
-- vim-multiple-cursors is archived upstream; vim-visual-multi is its
-- successor with the same Ctrl-N workflow.
Plug('https://github.com/mg979/vim-visual-multi')      -- CTRL + N for multiple cursors
Plug('https://github.com/matze/vim-move')
Plug('voldikss/vim-floaterm')
-- master branch: frozen but stable; the rewritten main branch needs the
-- tree-sitter CLI installed, which we don't ship.
Plug('nvim-treesitter/nvim-treesitter', { branch = 'master', ['do'] = ':TSUpdate' }) -- Parser-based highlighting
Plug('alvan/vim-closetag')

vim.call('plug#end')

-- pcall — first launch before :PlugInstall must not error
pcall(vim.cmd.colorscheme, 'onedark')

-- vim-move on <leader>j/k instead of its default Alt-j/Alt-k (see the
-- keybinding policy at the top). <Plug> targets need remap.
map('n', '<leader>j', '<Plug>MoveLineDown', { remap = true })
map('n', '<leader>k', '<Plug>MoveLineUp', { remap = true })
map('x', '<leader>j', '<Plug>MoveBlockDown', { remap = true })
map('x', '<leader>k', '<Plug>MoveBlockUp', { remap = true })

-- ============================================================
-- LSP completion (nvim-cmp + nvim-lspconfig)
-- ============================================================
local ok_cmp, cmp             = pcall(require, 'cmp')
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
    -- <C-l> is the portable trigger; <C-Space> kept for muscle memory but it
    -- is unreliable (NUL byte, and IBus grabs it on Ubuntu).
    ['<C-l>']     = cmp.mapping.complete(),
    ['<C-Space>'] = cmp.mapping.complete(),
    -- Accept: AI ghost text > selected completion > literal key. Replaces the
    -- old Alt-a, which gnome-terminal and SSH sessions both mangle.
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
    -- Dismiss: AI ghost text > completion popup > literal key (was Alt-e,
    -- which collides with gnome-terminal's Edit menu).
    ['<C-e>'] = cmp.mapping(function(fallback)
      local ok_vt, vt = pcall(require, 'minuet.virtualtext')
      -- Guarded: if minuet ever renames action.dismiss, fall through to cmp
      -- rather than throwing on every Ctrl-e.
      if ok_vt and vt.action.is_visible() and vt.action.dismiss then
        vt.action.dismiss()
      elseif cmp.visible() then
        cmp.abort()
      else
        fallback()
      end
    end, { 'i' }),
    -- Smart Tab (Copilot/VS Code feel): accept grey AI ghost text if visible,
    -- else navigate the completion menu, else insert a literal tab.
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

-- ============================================================
-- AI ghost-text completion (minuet-ai) — Copilot-style inline
-- suggestions from a local OpenAI-compatible server (vLLM,
-- llama.cpp, LM Studio, Ollama...).
--
--   Zero config: the served model is auto-discovered from GET /v1/models.
--   If the server is unreachable, AI completion silently stays off.
--
--   Optional env overrides:
--     MINUET_ENDPOINT  base URL   (default http://localhost:8000/v1)
--     MINUET_MODEL     model id   (default: first model the server lists)
--     MINUET_API_KEY   bearer     (default "dummy"; vLLM ignores it)
--
--   Keys while a grey suggestion is visible:  Tab or Ctrl-y accept,
--   Ctrl-e dismiss (all defined in cmp.setup's mapping table above).
-- ============================================================
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
        -- Accept/dismiss are handled by the <Tab>/<C-y>/<C-e> chains in
        -- cmp.setup above, so minuet's own keymaps are pointed at unreachable
        -- <Plug> pseudo-keys. (Its defaults were Alt-a / Alt-e, which do not
        -- survive gnome-terminal, tmux, or SSH reliably.)
        keymap = {
          accept  = '<Plug>(minuet-accept-unused)',
          dismiss = '<Plug>(minuet-dismiss-unused)',
        },
      },
      notify = 'error',  -- quiet unless something is actually broken
    })
    -- setup runs async (after model discovery), which is later than the
    -- FileType event of buffers opened at launch — minuet's auto-trigger
    -- autocmd missed them, so flip its per-buffer flag here directly.
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

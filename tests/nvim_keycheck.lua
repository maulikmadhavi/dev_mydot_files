-- ============================================================
-- Does THIS terminal deliver the keys the config relies on?
--
--   nvim --clean -S tests/nvim_keycheck.lua
--
-- Run it in the terminal where a key "does nothing" (Windows Terminal,
-- VS Code, tmux, screen, an SSH session...). For each key it asks you to
-- press it and records what nvim actually received. If nothing seems to
-- happen, press Esc to mark that key as not received and move on.
--
-- tests/nvim_keymaps.lua proves the mappings work once nvim gets the key;
-- this script finds the keys a terminal or multiplexer swallows first.
-- ============================================================

-- { key, label, what it does in this config, hint when it fails }
local KEYS = {
  { '<Space>',   'Space',      'leader for every Space mapping' },
  { '<C-p>',     'Ctrl-p',     ':Rg search',                  'VS Code terminal grabs it for Quick Open — set "terminal.integrated.sendKeybindingsToShell": true, or use Space r' },
  { '<C-n>',     'Ctrl-n',     'multi-cursor',                'VS Code terminal grabs it (New File) — sendKeybindingsToShell, see above' },
  { '<C-v>',     'Ctrl-v',     'blockwise visual (built-in)', 'Windows Terminal / VS Code bind it to paste — use Space v, or delete the ctrl+v binding in Windows Terminal settings.json' },
  { '<F6>',      'F6',         'code outline',                'function key mangled (TERM/terminfo mismatch in tmux/screen, or laptop Fn-lock) — use Space o; in tmux: set -g default-terminal tmux-256color' },
  { '<F7>',      'F7',         'floating terminal',           'function key mangled — use Space t (inside the terminal press Ctrl-\\ Ctrl-n first)' },
  { '<Tab>',     'Tab',        'indent / completion / accept AI' },
  { '<S-Tab>',   'Shift-Tab',  'dedent / previous completion', 'terminal sends plain Tab for Shift-Tab — check its keybindings' },
  { '<C-y>',     'Ctrl-y',     'accept completion / AI' },
  { '<C-e>',     'Ctrl-e',     'dismiss completion / AI',     'VS Code terminal grabs it (Quick Open) — sendKeybindingsToShell' },
  { '<C-l>',     'Ctrl-l',     'open completion menu (insert)' },
  { '<C-Space>', 'Ctrl-Space', 'open completion menu (alt.)', 'expected on many setups (NUL byte; IBus grabs it on Ubuntu) — use Ctrl-l' },
  { '<C-s>',     'Ctrl-s',     'signature help (insert)',     'flow control: run `stty -ixon` (the repo .zshrc does) — or the terminal binds it' },
  { '<C-]>',     'Ctrl-]',     'go to definition',            'not typeable on some keyboard layouts (e.g. German) — use :lua vim.lsp.buf.definition()' },
  { '<C-t>',     'Ctrl-t',     'jump back' },
  { '<C-r>',     'Ctrl-r',     'redo' },
  { '<C-w>',     'Ctrl-w',     'window prefix',               'browser-based / VS Code terminals may close the tab — sendKeybindingsToShell' },
  { '*',         '*',          'search word under cursor',    'VS Code WSL terminal turns Shift-8 into 8 — see README troubleshooting' },
  { '%',         '%',          'jump to matching bracket',    'VS Code WSL terminal turns Shift-5 into 5 — see README troubleshooting' },
}
-- Different notations nvim may report for the same key.
local ALIASES = { ['<C-Space>'] = { '<C-@>', '<Nul>' } }

local function norm(k) return vim.fn.keytrans(vim.keycode(k)) end

local function matches(spec, got)
  if norm(spec) == got then return true end
  for _, a in ipairs(ALIASES[spec] or {}) do
    if norm(a) == got then return true end
  end
  return false
end

local function env_summary()
  local e, parts = vim.env, {}
  if e.WT_SESSION then parts[#parts + 1] = 'Windows Terminal' end
  if e.TERM_PROGRAM then parts[#parts + 1] = e.TERM_PROGRAM end
  if e.TMUX then parts[#parts + 1] = 'tmux' end
  if e.STY then parts[#parts + 1] = 'screen' end
  if e.SSH_TTY then parts[#parts + 1] = 'SSH' end
  if vim.fn.has('wsl') == 1 then parts[#parts + 1] = 'WSL' end
  parts[#parts + 1] = 'TERM=' .. (e.TERM or '?')
  return table.concat(parts, ', ')
end

local results = {}
for i, k in ipairs(KEYS) do
  vim.api.nvim_echo({
    { ('[%d/%d] Press  '):format(i, #KEYS), 'Normal' },
    { k[2], 'Question' },
    { '   (' .. k[3] .. ')   — Esc if nothing happens', 'Comment' },
  }, false, {})
  vim.cmd.redraw()
  local got = vim.fn.keytrans(vim.fn.getcharstr())
  -- An unrecognised escape sequence arrives as Esc + bytes: collect the rest.
  vim.wait(80)
  local extra = ''
  while vim.fn.getchar(1) ~= 0 do extra = extra .. vim.fn.keytrans(vim.fn.getcharstr()) end

  local status, note
  if matches(k[1], got) and extra == '' then
    status, note = 'PASS', 'received ' .. got
  elseif got == '<Esc>' and extra == '' then
    status, note = 'FAIL', 'never reached nvim'
  else
    status, note = 'FAIL', 'nvim received ' .. got .. extra .. ' instead'
  end
  results[#results + 1] = { status = status, key = k, note = note }
end

local lines = { 'Key check — ' .. env_summary(), '' }
local failed = 0
for _, r in ipairs(results) do
  lines[#lines + 1] = ('%s  %-11s %-32s %s'):format(r.status, r.key[2], r.key[3], r.note)
  if r.status == 'FAIL' then
    failed = failed + 1
    lines[#lines + 1] = '      → ' .. (r.key[4] or 'something between keyboard and nvim ate it: terminal or multiplexer keybinding, OS shortcut, or input method')
  end
end
lines[#lines + 1] = ''
lines[#lines + 1] = failed == 0 and 'All keys arrive. If a mapping still misbehaves, run: nvim -l tests/nvim_keymaps.lua'
  or (failed .. ' key(s) never arrive intact — fix the terminal (hints above) or use the Space-leader alternative.')
lines[#lines + 1] = 'Close with :q!'

vim.cmd.enew()
vim.bo.buftype = 'nofile'
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.cmd('echo ""')

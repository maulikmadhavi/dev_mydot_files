-- ============================================================
-- End-to-end tests for every keybinding in cheatsheet.md.
--
--   nvim -l tests/nvim_keymaps.lua          run all tests (~1 min)
--   nvim -l tests/nvim_keymaps.lua lsp      only tests whose group/key/name
--                                           contains "lsp" (case-insensitive)
--
-- Each test starts a fresh `nvim --embed --headless` that loads your real
-- config (whatever a plain `nvim` loads), types the keys through
-- nvim_input() exactly as if they were pressed, and checks the result.
--
-- A PASS proves the config side works. If a key still does nothing when you
-- press it, the terminal is eating it before nvim sees it — run
--   nvim --clean -S tests/nvim_keycheck.lua
-- in that terminal to find out which keys never arrive.
-- ============================================================

local script = vim.fs.normalize(vim.fn.fnamemodify(arg[0], ':p'))
local repo   = vim.fs.dirname(vim.fs.dirname(script))
local filter = (arg[1] or ''):lower()
local is_win = vim.fn.has('win32') == 1

-- ------------------------------------------------------------
-- Fixture project the child nvim runs in (:Files, :Rg, LSP)
-- ------------------------------------------------------------
local fixture = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(fixture, 'p')
local function fixture_file(name, lines) vim.fn.writefile(lines, fixture .. '/' .. name) end
fixture_file('sample.py', {
  'def greet(name: str) -> str:',      -- 1
  '    return "hi " + name',           -- 2
  '',                                  -- 3
  '',                                  -- 4
  'greet("x")',                        -- 5
  'result = greet("y")',               -- 6
  'undefined_thing',                   -- 7  <- diagnostic for [d / ]d
  '# end',                             -- 8
})
fixture_file('fmt.py', { 'x=1' })
-- A project root: outside one, basedpyright on nvim 0.11 publishes no
-- diagnostics at all (nvim 0.12 pulls them instead).
fixture_file('pyproject.toml', { '[project]', 'name = "fixture"' })
fixture_file('sample.lua', { 'local function alpha() end', 'local function beta() end' })
fixture_file('notes.txt', { 'hello_world' })

-- ------------------------------------------------------------
-- Child nvim driven over RPC
-- ------------------------------------------------------------
-- Helpers installed into the child as the global `T`.
local HELPERS = [[
vim.o.more = false   -- a --more-- prompt would block the RPC channel
_G.T = {}
function T.set(lines, row, col)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { row or 1, col or 0 })
end
function T.lines() return vim.api.nvim_buf_get_lines(0, 0, -1, false) end
function T.line() return vim.api.nvim_get_current_line() end
function T.row() return vim.api.nvim_win_get_cursor(0)[1] end
function T.mode() return vim.api.nvim_get_mode().mode end
function T.win_ft(ft)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == ft then return true end
  end
  return false
end
function T.buf_text(ft)   -- non-blank lines of every buffer with this filetype
  local out = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == ft then
      for _, l in ipairs(vim.api.nvim_buf_get_lines(b, 0, -1, false)) do
        l = l:gsub('\226[\128-\191][\128-\191]', '')   -- drop box-drawing borders
        if l:find('%S') then out[#out + 1] = vim.trim(l) end
      end
    end
  end
  return table.concat(out, ' / ')
end
function T.buf_has(ft, text) return T.buf_text(ft):find(text, 1, true) ~= nil end
function T.lsp(name)
  local c = vim.lsp.get_clients({ bufnr = 0, name = name })[1]
  return c ~= nil and c.initialized == true
end
function T.diags_from(source)   -- has this server finished analysing?
  for _, d in ipairs(vim.diagnostic.get(0)) do
    if (d.source or ''):lower():find(source, 1, true) then return true end
  end
  return false
end
function T.lsp_float()
  local w = vim.b.lsp_floating_preview
  return w ~= nil and vim.api.nvim_win_is_valid(w)
end
function T.close_floats()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= '' then pcall(vim.api.nvim_win_close, w, true) end
  end
end
function T.cmp_visible() local ok, cmp = pcall(require, 'cmp'); return ok and cmp.visible() end
function T.cmp_selected()
  local ok, cmp = pcall(require, 'cmp'); return ok and cmp.get_selected_entry() ~= nil
end
function T.ghost_visible()
  local ok, vt = pcall(require, 'minuet.virtualtext'); return ok and vt.action.is_visible()
end
]]

local Child = {}
Child.__index = Child

function Child.new(extra_args)
  local cmd = { vim.v.progpath, '--embed', '--headless', '-i', 'NONE', '-n' }
  vim.list_extend(cmd, extra_args or {})
  local chan = vim.fn.jobstart(cmd, { rpc = true, cwd = fixture })
  assert(chan > 0, 'could not start ' .. vim.v.progpath)
  local c = setmetatable({ chan = chan, pid = vim.fn.jobpid(chan), dog = vim.uv.new_timer() }, Child)
  c:wait('vim.v.vim_did_enter == 1', 10000)
  c:lua(HELPERS)
  return c
end

-- nvim_get_mode is a "fast" API call: answered even while nvim is blocked.
function Child:mode() return vim.rpcrequest(self.chan, 'nvim_get_mode') end

-- Run Lua in the child. While nvim sits at a hit-enter / --more-- prompt it
-- defers every non-fast request, so dismiss those first; any other blocking
-- state (input(), getchar()) is reported instead of hanging. A watchdog
-- kills a child that stops answering, so one bad test cannot stall the run.
function Child:lua(code, ...)
  if self.dead then error({ fail = 'nvim stopped responding and was killed' }, 0) end
  for _ = 1, 10 do
    local m = self:mode()
    if not m.blocking then break end
    if m.mode:sub(1, 1) ~= 'r' then error({ fail = 'nvim is waiting for input (mode ' .. m.mode .. ')' }, 0) end
    vim.rpcrequest(self.chan, 'nvim_input', '<CR>')
    vim.uv.sleep(20)
  end
  local fired = false
  self.dog:start(20000, 0, function() fired = true; vim.uv.kill(self.pid, 'sigkill') end)
  local ok, res = pcall(vim.rpcrequest, self.chan, 'nvim_exec_lua', code, { ... })
  self.dog:stop()
  if fired or not ok then
    self.dead = true
    error({ fail = fired and 'nvim stopped responding for 20 s (killed)' or tostring(res) }, 0)
  end
  if res == vim.NIL then return nil end
  return res
end

function Child:cmd(ex) return self:lua('vim.cmd(...)', ex) end

-- Type keys one at a time. After each, a non-fast request waits until nvim
-- has consumed the key and run what it scheduled — the pause a human leaves
-- between keys. (Sent in one burst, Ctrl-l raced nvim-cmp's InsertEnter
-- setup and fell through to the built-in key.)
function Child:keys(keys)
  local i = 1
  while i <= #keys do
    local tok = keys:match('^<[^<>%s]+>', i) or keys:sub(i, i)
    i = i + #tok
    vim.rpcrequest(self.chan, 'nvim_input', tok)
    if not self:mode().blocking then pcall(self.lua, self, 'return 1') end
  end
end

-- Poll a Lua expression in the child until it is truthy (or time runs out).
function Child:wait(expr, ms, ...)
  local code = 'return ' .. expr
  local deadline = vim.uv.hrtime() + (ms or 3000) * 1e6
  repeat
    local ok, v = pcall(self.lua, self, code, ...)
    if ok and v then return v end
    if self.dead then return false end
    vim.uv.sleep(25)
  until vim.uv.hrtime() > deadline
  return false
end

function Child:stop()
  self.dog:close()
  if self.dead then return end
  pcall(vim.rpcrequest, self.chan, 'nvim_input', [[<C-\><C-n>]])
  pcall(vim.rpcnotify, self.chan, 'nvim_command', 'qa!')
  if vim.fn.jobwait({ self.chan }, 5000)[1] == -1 then vim.fn.jobstop(self.chan) end
end

-- ------------------------------------------------------------
-- Test registry
-- ------------------------------------------------------------
local tests, group_name = {}, ''
local function group(name) group_name = name end

-- opts: needs   = { executables }        -> SKIP when missing
--       session = name in `sessions`      -> share one child (slow setup)
--       hint    = what to do on FAIL
local function test(key, what, fn, opts)
  opts = opts or {}
  tests[#tests + 1] = { group = group_name, key = key, what = what, fn = fn,
                        needs = opts.needs, session = opts.session, hint = opts.hint }
end

local function expect(cond, msg) if not cond then error({ fail = msg }, 0) end end
local function skip(msg) error({ skip = msg }, 0) end

local KEYCHECK = 'if it works here but not when you press it, run tests/nvim_keycheck.lua'

-- ------------------------------------------------------------
-- Environment
-- ------------------------------------------------------------
group('Environment')

test('', 'nvim is 0.11 or newer', function(c)
  local v = c:lua('return tostring(vim.version())')
  expect(c:lua('return vim.fn.has("nvim-0.11") == 1'), 'nvim ' .. v .. ' — init.lua needs vim.lsp.config/enable (0.11+)')
end, { hint = 'upgrade nvim: pixi global install nvim (Linux) / winget upgrade Neovim.Neovim (Windows)' })

test('', "nvim loads this repo's init.lua", function(c)
  local rc = c:lua('return vim.env.MYVIMRC')
  expect(rc and rc ~= '', 'no $MYVIMRC — nvim found no init file')
  local want = repo .. '/.config/nvim/init.lua'
  local function norm(p)
    p = vim.fs.normalize(vim.fn.resolve(p))
    return is_win and p:lower() or p
  end
  if norm(rc) == norm(want) then return end
  -- Windows: a one-line stub that dofile()s the repo file.
  local stub = table.concat(vim.fn.readfile(rc), '\n')
  local target = stub:match('dofile%(%[%[(.-)%]%]%)')
  expect(target and norm(target) == norm(want), 'nvim loads ' .. rc .. ', not ' .. want)
end, { hint = 're-run setup.sh / setup_powershell_omp.ps1 (stow symlink or Windows stub)' })

test('', 'startup has no errors or warnings', function(c)
  vim.uv.sleep(300)   -- let scheduled notifications land
  local msgs = c:lua('return vim.fn.execute("messages")')
  local bad = {}
  for line in msgs:gmatch('[^\n]+') do
    if line:match('E%d+:') or line:match('[Ee]rror') or line:match('missing') then bad[#bad + 1] = line end
  end
  expect(#bad == 0, table.concat(bad, ' | '))
end, { hint = 'open nvim and read :messages; "plugins missing" means run :PlugInstall' })

test('', 'all vim-plug plugins are installed', function(c)
  local missing = c:lua([[
    local out = {}
    for name, spec in pairs(vim.g.plugs or {}) do
      if vim.fn.isdirectory(spec.dir) == 0 then out[#out + 1] = name end
    end
    return out
  ]])
  expect(c:lua('return vim.g.plugs ~= nil'), 'vim-plug did not load')
  expect(#missing == 0, 'not installed: ' .. table.concat(missing, ', '))
end, { hint = 'run :PlugInstall in nvim, then restart it' })

for _, dep in ipairs({
  { 'rg',                      'Space r / Ctrl-p (:Rg)',   'pixi global install ripgrep' },
  { 'fzf',                     'Space f / Space r',        'pixi global install fzf' },
  { 'git',                     'fugitive / gitsigns',      'pixi global install git (Linux) / winget install Git.Git' },
  { 'curl',                    'AI model auto-discovery',  'install curl' },
  { 'basedpyright-langserver', 'Python LSP keys',          'pixi global install basedpyright' },
  { 'ruff',                    'lint + format on save',    'pixi global install ruff' },
}) do
  test('', 'executable: ' .. dep[1] .. '  (' .. dep[2] .. ')', function()
    expect(vim.fn.executable(dep[1]) == 1, dep[1] .. ' is not on PATH')
  end, { hint = dep[3] })
end

test('', 'system clipboard provider (y / p reach the OS clipboard)', function(c)
  local name = c:lua([[
    if type(vim.g.clipboard) == 'table' then return vim.g.clipboard.name or 'custom' end
    local ok, exe = pcall(vim.fn['provider#clipboard#Executable'])
    return ok and exe or ''
  ]])
  expect(name ~= '', 'no clipboard provider found')
end, { hint = 'WSL: put win32yank.exe on PATH · X11: xclip · Wayland: wl-clipboard · SSH: nvim ≥ 0.10 (OSC 52)' })

test('', 'built-in Ctrl keys are not remapped', function(c)
  local keys = { '<C-f>', '<C-b>', '<C-u>', '<C-d>', '<C-x>', '<C-a>', '<C-t>', '<C-g>',
                 '<C-r>', '<C-w>', '<C-l>', '<C-o>', '<C-]>', '<C-v>' }
  local code = [[
    local out = {}
    for _, k in ipairs(...) do out[k] = vim.fn.maparg(k, 'n') end
    return out
  ]]
  local clean = Child.new({ '--clean' })
  local want = clean:lua(code, keys)
  clean:stop()
  local got, bad = c:lua(code, keys), {}
  for _, k in ipairs(keys) do
    if got[k] ~= want[k] then bad[#bad + 1] = k .. ' → ' .. got[k] end
  end
  expect(#bad == 0, 'shadowed: ' .. table.concat(bad, ', '))
end, { hint = 'find the culprit with  :verbose nmap <C-x>  and remove that mapping' })

-- ------------------------------------------------------------
-- Leader (Space) panels and pickers
-- ------------------------------------------------------------
group('Leader panels & pickers')

test('<Space>e', 'NERDTree opens, second press closes it', function(c)
  c:keys('<Space>e')
  expect(c:wait('T.win_ft("nerdtree")'), 'no NERDTree window opened')
  c:keys('<Space>e')
  expect(c:wait('not T.win_ft("nerdtree")'), 'second <Space>e did not close it')
end)

-- fzf runs in a terminal buffer: wait for `text` to show up in it.
local function fzf_lists(c, keys, text)
  c:keys(keys)
  expect(c:wait('T.win_ft("fzf")', 5000), 'no fzf window opened')
  expect(c:wait('T.buf_has("fzf", ...)', 8000, text),
         'fzf never listed ' .. text .. ' — it shows: ' .. c:lua('return T.buf_text("fzf")'):sub(1, 200))
end

test('<Space>f', 'fzf :Files lists project files', function(c)
  fzf_lists(c, '<Space>f', 'sample.py')
end, { needs = { 'fzf' } })

test('<Space>r', 'fzf :Rg searches file contents', function(c)
  fzf_lists(c, '<Space>r', 'sample.py:')   -- file:line: = rg output
end, { needs = { 'fzf', 'rg' } })

test('<C-p>', 'same as Space r (:Rg)', function(c)
  fzf_lists(c, '<C-p>', 'sample.py:')
end, { needs = { 'fzf', 'rg' }, hint = KEYCHECK })

test('<Space>u', 'Undotree opens, second press closes it', function(c)
  c:keys('<Space>u')
  expect(c:wait('T.win_ft("undotree")'), 'no undotree window opened')
  c:keys('<Space>u')
  expect(c:wait('not T.win_ft("undotree")'), 'second <Space>u did not close it')
end)

test('<Space>o', 'Aerial outline opens (Lua file, treesitter symbols)', function(c)
  c:cmd('edit sample.lua')
  c:keys('<Space>o')
  expect(c:wait('T.win_ft("aerial")', 5000), 'no aerial window opened')
  expect(c:wait('T.buf_has("aerial", "alpha")', 5000), 'aerial opened but shows no symbols')
end)

test('<F6>', 'Aerial outline opens', function(c)
  c:cmd('edit sample.lua')
  c:keys('<F6>')
  expect(c:wait('T.win_ft("aerial")', 5000), 'no aerial window opened')
end, { hint = KEYCHECK .. ' — F-keys are often mangled; Space o does the same' })

test('<Space>t', 'floating terminal opens', function(c)
  c:keys('<Space>t')
  expect(c:wait('T.win_ft("floaterm")', 5000), 'no floaterm window opened')
end)

test('<F7>', 'floating terminal opens (normal mode)', function(c)
  c:keys('<F7>')
  expect(c:wait('T.win_ft("floaterm")', 5000), 'no floaterm window opened')
end, { hint = KEYCHECK })

test('<F7>', 'floating terminal opens from insert mode', function(c)
  c:keys('i<F7>')
  expect(c:wait('T.win_ft("floaterm")', 5000), 'no floaterm window opened')
end, { hint = KEYCHECK })

test('<F7>', 'floating terminal hides from inside the terminal', function(c)
  c:keys('<Space>t')
  expect(c:wait('T.win_ft("floaterm")', 5000), 'floaterm did not open')
  expect(c:wait('T.mode() == "t"', 3000), 'floaterm opened but not in terminal mode')
  c:keys('<F7>')
  expect(c:wait('not T.win_ft("floaterm")', 3000), '<F7> in terminal mode did not hide it')
end, { hint = KEYCHECK })

-- ------------------------------------------------------------
-- Editing
-- ------------------------------------------------------------
group('Editing')

test('<Space>v', 'blockwise visual (Ctrl-v substitute): delete a column', function(c)
  c:lua('T.set({ "abc", "def", "ghi" })')
  c:keys('<Space>vjd')
  expect(vim.deep_equal(c:lua('return T.lines()'), { 'bc', 'ef', 'ghi' }), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end)

test('<Space>j', 'move line down (normal)', function(c)
  c:lua('T.set({ "one", "two", "three" }, 1)')
  c:keys('<Space>j')
  expect(c:wait('vim.deep_equal(T.lines(), { "two", "one", "three" })'), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end)

test('<Space>k', 'move line up (normal)', function(c)
  c:lua('T.set({ "one", "two", "three" }, 2)')
  c:keys('<Space>k')
  expect(c:wait('vim.deep_equal(T.lines(), { "two", "one", "three" })'), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end)

test('<Space>j', 'move selection down (visual)', function(c)
  c:lua('T.set({ "a", "b", "c", "d" }, 1)')
  c:keys('Vj<Space>j')
  expect(c:wait('vim.deep_equal(T.lines(), { "c", "a", "b", "d" })'), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end)

test('<Space>k', 'move selection up (visual)', function(c)
  c:lua('T.set({ "a", "b", "c", "d" }, 3)')
  c:keys('Vj<Space>k')
  expect(c:wait('vim.deep_equal(T.lines(), { "a", "c", "d", "b" })'), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end)

test('<Tab>', 'indent selection, keep it selected (visual)', function(c)
  c:lua('T.set({ "x", "y" })')
  c:keys('Vj<Tab>')
  expect(vim.deep_equal(c:lua('return T.lines()'), { '\tx', '\ty' }), 'got ' .. vim.inspect(c:lua('return T.lines()')))
  expect(c:lua('return T.mode()') == 'V', 'selection was lost')
end)

test('<S-Tab>', 'dedent selection (visual)', function(c)
  c:lua('T.set({ "\\tx", "\\ty" })')
  c:keys('Vj<S-Tab>')
  expect(vim.deep_equal(c:lua('return T.lines()'), { 'x', 'y' }), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end, { hint = KEYCHECK })

test('* cgn .', 'rename every match one at a time', function(c)
  c:lua('T.set({ "foo foo foo" })')
  c:keys('*cgnbar<Esc>..')
  expect(c:wait('T.line() == "bar bar bar"'), 'got ' .. c:lua('return T.line()'))
end)

test('<C-n>', 'multi-cursor: select word, add next, change both', function(c)
  c:lua('T.set({ "foo bar foo" })')
  c:keys('<C-n>')
  expect(c:wait('vim.b.visual_multi ~= nil'), 'vim-visual-multi did not start')
  c:keys('<C-n>')
  expect(c:wait('vim.fn.eval("len(b:VM_Selection.Regions)") == 2'), 'second <C-n> did not add the next match')
  c:keys('cbaz<Esc><Esc>')
  expect(c:wait('T.line() == "baz bar baz"'), 'got ' .. c:lua('return T.line()'))
end, { hint = KEYCHECK })

test('ysiw)', 'surround word with ()', function(c)
  c:lua('T.set({ "word" })')
  c:keys('ysiw)')
  expect(c:wait('T.line() == "(word)"'), 'got ' .. c:lua('return T.line()'))
end)

test([[cs"']], [[change surrounding " to ']], function(c)
  c:lua([[T.set({ 'say "hi"' }, 1, 5)]])
  c:keys([[cs"']])
  expect(c:wait([[T.line() == "say 'hi'"]]), 'got ' .. c:lua('return T.line()'))
end)

test('ds"', 'delete surrounding "', function(c)
  c:lua([[T.set({ 'say "hi"' }, 1, 5)]])
  c:keys('ds"')
  expect(c:wait('T.line() == "say hi"'), 'got ' .. c:lua('return T.line()'))
end)

test('gcc', 'toggle line comment', function(c)
  c:lua('vim.bo.filetype = "lua"; T.set({ "x = 1" })')
  c:keys('gcc')
  expect(c:wait('T.line() == "-- x = 1"'), 'got ' .. c:lua('return T.line()'))
  c:keys('gcc')
  expect(c:wait('T.line() == "x = 1"'), 'second gcc did not uncomment')
end)

-- ------------------------------------------------------------
-- Insert mode: completion (nvim-cmp)
-- ------------------------------------------------------------
group('Insert-mode completion')

-- "he" is below cmp-buffer's 3-char auto-trigger, so only a manual
-- trigger (Ctrl-l) opens the menu — that is what these tests rely on.
local function open_menu(c)
  c:lua('T.set({ "hello_world", "" }, 2)')
  c:keys('ihe<C-l>')
  expect(c:wait('T.cmp_visible()'), 'Ctrl-l did not open the completion menu')
end

test('<C-l>', 'open the completion menu manually', open_menu, { hint = KEYCHECK })

test('<C-y>', 'accept the first completion', function(c)
  open_menu(c)
  c:keys('<C-y>')
  expect(c:wait('T.lines()[2] == "hello_world"'), 'line is ' .. vim.inspect(c:lua('return T.lines()[2]')))
end, { hint = KEYCHECK })

test('<Tab>', 'select the next completion item', function(c)
  open_menu(c)
  c:keys('<Tab>')
  expect(c:wait('T.cmp_selected()'), 'no item selected after <Tab>')
end, { hint = KEYCHECK })

test('<S-Tab>', 'select the previous completion item', function(c)
  open_menu(c)
  c:keys('<S-Tab>')
  expect(c:wait('T.cmp_selected()'), 'no item selected after <S-Tab>')
end, { hint = KEYCHECK })

test('<CR>', 'confirm the selected item (no newline)', function(c)
  open_menu(c)
  c:keys('<Tab><CR>')
  expect(c:wait('vim.deep_equal(T.lines(), { "hello_world", "hello_world" })'), 'got ' .. vim.inspect(c:lua('return T.lines()')))
end)

test('<C-e>', 'close the menu, keep what was typed', function(c)
  open_menu(c)
  c:keys('<C-e>')
  expect(c:wait('not T.cmp_visible()'), 'menu still open')
  expect(c:lua('return T.lines()[2]') == 'he', 'line changed to ' .. vim.inspect(c:lua('return T.lines()[2]')))
end, { hint = KEYCHECK })

test('<Tab>', 'insert a literal tab when no menu is open', function(c)
  c:keys('i<Tab>')
  expect(c:wait('T.line() == "\\t"'), 'got ' .. vim.inspect(c:lua('return T.line()')))
end)

-- ------------------------------------------------------------
-- Python LSP (basedpyright + ruff) — one shared nvim, slow start
-- ------------------------------------------------------------
group('LSP (Python)')

local sessions = {}
sessions.lsp = function(c)
  c:cmd('edit sample.py')
  if not c:wait('T.lsp("basedpyright") and T.lsp("ruff")', 30000) then
    return 'basedpyright/ruff did not attach to sample.py within 30 s (see :checkhealth vim.lsp)'
  end
  -- ruff answers instantly; basedpyright's own diagnostics mean it has
  -- analysed the file and will answer definition/references requests.
  if not c:wait('T.diags_from("basedpyright")', 45000) then
    return 'basedpyright attached but never analysed sample.py (45 s)'
  end
end
local LSP = { session = 'lsp', needs = { 'basedpyright-langserver', 'ruff' } }
local function at(c, row, col) c:lua('vim.cmd("stopinsert"); T.close_floats(); vim.api.nvim_win_set_cursor(0, { ... })', row, col) end

test('', 'basedpyright + ruff attach and report diagnostics', function() end, LSP)

test('K', 'hover docs float', function(c)
  at(c, 5, 0)
  c:keys('K')
  expect(c:wait('T.lsp_float()', 5000), 'no hover window')
end, LSP)

test('<C-]>', 'go to definition', function(c)
  at(c, 5, 0)
  c:keys('<C-]>')
  expect(c:wait('T.row() == 1', 5000), 'cursor stayed on line ' .. c:lua('return T.row()'))
end, vim.tbl_extend('force', LSP, { hint = KEYCHECK .. ' — Ctrl-] is untypeable on some keyboard layouts' }))

test('<C-t>', 'jump back after go-to-definition', function(c)
  at(c, 5, 0)
  c:keys('<C-]>')
  if not c:wait('T.row() == 1', 5000) then skip('Ctrl-] did not jump, nothing to come back from') end
  c:keys('<C-t>')
  expect(c:wait('T.row() == 5'), 'cursor is on line ' .. c:lua('return T.row()'))
end, LSP)

test('grr', 'references → quickfix list', function(c)
  at(c, 1, 4)
  c:keys('grr')
  expect(c:wait('#vim.fn.getqflist() >= 3', 5000), 'quickfix has ' .. c:lua('return #vim.fn.getqflist()') .. ' entries, want ≥ 3')
  c:cmd('cclose')
end, LSP)

test('gO', 'document symbols → location list', function(c)
  at(c, 1, 0)
  c:keys('gO')
  expect(c:wait('#vim.fn.getloclist(0) > 0', 5000), 'location list stayed empty')
  c:cmd('lclose')
end, LSP)

test(']d', 'next diagnostic', function(c)
  at(c, 1, 0)
  c:keys(']d')
  expect(c:wait('T.row() > 1 and #vim.diagnostic.get(0, { lnum = T.row() - 1 }) > 0'), 'cursor on line ' .. c:lua('return T.row()'))
end, LSP)

test('[d', 'previous diagnostic', function(c)
  at(c, 8, 0)
  c:keys('[d')
  expect(c:wait('T.row() < 8 and #vim.diagnostic.get(0, { lnum = T.row() - 1 }) > 0'), 'cursor on line ' .. c:lua('return T.row()'))
end, LSP)

test('gra', 'code actions menu', function(c)
  at(c, 7, 0)
  c:lua('_G.T.actions = nil; vim.ui.select = function(items, _, cb) T.actions = #items; cb(nil) end')
  c:keys('gra')
  expect(c:wait('T.actions', 5000), 'no code-action menu (no actions offered?)')
end, LSP)

test('gri', 'mapped to LSP implementation (needs server support)', function(c)
  expect(c:lua([[return vim.fn.maparg('gri', 'n') ~= '']]), 'gri is not mapped')
end, LSP)

test('<C-s>', 'signature help (insert mode)', function(c)
  at(c, 5, 6)
  c:keys('i<C-s>')
  expect(c:wait('T.lsp_float()', 5000), 'no signature window')
  c:keys('<Esc>')
end, vim.tbl_extend('force', LSP, { hint = KEYCHECK .. ' — or run `stty -ixon` (flow control)' }))

test('grn', 'rename symbol', function(c)
  at(c, 1, 4)
  c:keys('grn')
  local deadline = vim.uv.hrtime() + 5e9
  while c:mode().mode ~= 'c' and vim.uv.hrtime() < deadline do vim.uv.sleep(25) end
  expect(c:mode().mode == 'c', 'no rename prompt')
  c:keys('<C-u>salute<CR>')
  expect(c:wait('T.lines()[1]:find("def salute") and T.lines()[5] == [[salute("x")]]', 5000),
         'buffer not renamed: ' .. vim.inspect(c:lua('return T.lines()[1]')))
end, LSP)

test(':w', 'ruff formats *.py on save', function(c)
  c:cmd('edit fmt.py')
  expect(c:wait('T.lsp("ruff")', 15000), 'ruff did not attach to fmt.py')
  c:lua('vim.bo.undofile = false')
  c:cmd('write')
  expect(c:wait('T.line() == "x = 1"', 5000), 'got ' .. vim.inspect(c:lua('return T.line()')))
end, LSP)

-- ------------------------------------------------------------
-- AI ghost text (minuet)
-- ------------------------------------------------------------
group('AI ghost text (minuet)')

-- The keys run against a stand-in for minuet's ghost text, so they need no
-- server: what they check is init.lua's priority chain (ghost text >
-- completion menu > literal key), not the model.
local function fake_ghost(c)
  c:lua([[
    local vt = require('minuet.virtualtext')
    T.ghost, T.ai = true, nil
    vt.action.is_visible = function() return T.ghost end
    vt.action.accept     = function() T.ai, T.ghost = 'accepted', false end
    vt.action.dismiss    = function() T.ai, T.ghost = 'dismissed', false end
  ]])
  c:keys('i')
end

test('<Tab>', 'accepts visible ghost text (instead of a tab)', function(c)
  fake_ghost(c)
  c:keys('<Tab>')
  expect(c:wait('T.ai == "accepted"'), 'ghost text was not accepted')
  expect(c:lua('return T.line()') == '', 'a literal tab was inserted too')
end, { hint = KEYCHECK })

test('<C-y>', 'accepts visible ghost text', function(c)
  fake_ghost(c)
  c:keys('<C-y>')
  expect(c:wait('T.ai == "accepted"'), 'ghost text was not accepted')
end, { hint = KEYCHECK })

test('<C-e>', 'dismisses visible ghost text', function(c)
  fake_ghost(c)
  c:keys('<C-e>')
  expect(c:wait('T.ai == "dismissed"'), 'ghost text was not dismissed')
end, { hint = KEYCHECK })

test('', 'AI server produces a suggestion (end to end)', function(c)
  local base = c:lua([[
    local base = (vim.env.MINUET_ENDPOINT or 'http://localhost:8000/v1'):gsub('/+$', '')
    local r = vim.system({ 'curl', '-fsS', '-m', '2', base .. '/models' }):wait()
    return (r.code == 0 and 'up ' or 'down ') .. base
  ]])
  if base:find('^down') then
    skip('no AI server at ' .. base:sub(6) .. ' (optional) — start it, or set MINUET_ENDPOINT in ~/.zshrc.local')
  end
  local model = c:wait([[require('minuet').config.provider == 'openai_compatible'
                         and require('minuet').config.provider_options.openai_compatible.model]], 5000)
  expect(model, 'server is up but minuet was never configured (model discovery failed?)')
  c:cmd('edit ai_scratch.py')
  c:lua('T.set({ "def add(a, b):", "    " }, 2, 4)')
  c:keys('A')
  c:lua([[require('minuet.virtualtext').action.next()]])
  expect(c:wait('T.ghost_visible()', 20000), 'model ' .. model .. ' answered but no suggestion appeared in 20 s')
end, { needs = { 'curl' },
       hint = 'reasoning models (qwen3, gpt-oss, deepseek-r1) spend the budget thinking and tiny ones ignore '
           .. "minuet's prompt — pick a non-reasoning code model: export MINUET_MODEL=<id from /v1/models>" })

-- ------------------------------------------------------------
-- Runner
-- ------------------------------------------------------------
local function out(s) io.stdout:write(s .. '\n') end
local function exe_missing(needs)
  for _, x in ipairs(needs or {}) do
    if vim.fn.executable(x) == 0 then return x end
  end
end

local live, setup_err = {}, {}
local counts = { PASS = 0, FAIL = 0, SKIP = 0 }
local failed = {}

out(('nvim keymap tests — %s, nvim %s'):format(is_win and 'Windows' or (vim.fn.has('wsl') == 1 and 'WSL' or 'Linux'), tostring(vim.version())))
out('fixture: ' .. fixture)

local shown_group
for _, t in ipairs(tests) do
  local label = (t.group .. ' ' .. t.key .. ' ' .. t.what):lower()
  if filter == '' or label:find(filter, 1, true) then
    if t.group ~= shown_group then
      shown_group = t.group
      out('\n' .. t.group)
    end

    local status, detail
    local missing = exe_missing(t.needs)
    if missing then
      status, detail = 'SKIP', 'needs ' .. missing
    elseif t.session and setup_err[t.session] then
      -- setup already failed and was reported by the session's first test
      status, detail = 'SKIP', setup_err[t.session].skip and setup_err[t.session].msg or 'setup failed (see above)'
    else
      local c = t.session and live[t.session]
      local new_session = t.session and not c
      if not c then c = Child.new() end
      if new_session then
        live[t.session] = c
        local err = sessions[t.session](c)
        if err then
          setup_err[t.session] = type(err) == 'table' and { skip = true, msg = err.skip } or { msg = err }
        end
      end
      if t.session and setup_err[t.session] then
        status = setup_err[t.session].skip and 'SKIP' or 'FAIL'
        detail = setup_err[t.session].msg
      else
        pcall(c.lua, c, 'vim.v.errmsg = ""')
        local ok, err = pcall(t.fn, c)
        if ok then
          status = 'PASS'
        elseif type(err) == 'table' and err.skip then
          status, detail = 'SKIP', err.skip
        else
          status = 'FAIL'
          detail = type(err) == 'table' and err.fail or tostring(err)
          local errmsg = select(2, pcall(c.lua, c, 'return vim.v.errmsg'))
          if type(errmsg) == 'string' and errmsg ~= '' then detail = detail .. '  [v:errmsg: ' .. errmsg .. ']' end
        end
      end
      if not t.session then
        c:stop()
      elseif c.dead then   -- next test of this session starts (and sets up) a new nvim
        c:stop()
        live[t.session] = nil
      end
    end

    counts[status] = counts[status] + 1
    out(('  %s  %-10s %s'):format(status, t.key, t.what))
    if detail then out('              ' .. detail) end
    if status == 'FAIL' then
      if t.hint then out('              → ' .. t.hint) end
      failed[#failed + 1] = (t.key ~= '' and t.key .. ' ' or '') .. t.what
    end
  end
end
for _, c in pairs(live) do c:stop() end
vim.fn.delete(fixture, 'rf')

out(('\n%d passed, %d failed, %d skipped'):format(counts.PASS, counts.FAIL, counts.SKIP))
if #failed > 0 then
  out('Failed: ' .. table.concat(failed, ' · '))
  out('Config-side failures are listed above with a fix. If everything passes here but a key')
  out('still does nothing when you press it, run:  nvim --clean -S tests/nvim_keycheck.lua')
end
os.exit(counts.FAIL > 0 and 1 or 0)

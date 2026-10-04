# Cheatsheet

Quick reference for the tools this repo configures. Start with the decision
trees, then look up details below. Coming from VS Code? Start with
[the shortcut translation](#coming-from-vs-code). Something not working? Jump to
[Keys not working?](#keys-not-working).

[Which tool when](#which-tool-when) · [From VS Code](#coming-from-vs-code) · [Neovim](#neovim) · [Keys not working?](#keys-not-working) · [Search from the shell](#search-from-the-shell) · [Shell](#shell-zsh--fzf) · [tmux / screen](#tmux--screen) · [Small tools](#small-tools)

---

## Which tool when

```
Find…
├─ a file by NAME
│  ├─ anywhere under ~, instantly ........ plocate name           index refreshes daily
│  ├─ in this project, in nvim ........... Space f                fuzzy
│  └─ in this project, at the prompt ..... Ctrl-t                 fzf, pastes the path
├─ TEXT inside files
│  ├─ in nvim, live as you type .......... Space r  or  Ctrl-p
│  ├─ at the prompt ...................... rg text                -i  -t py  -l  -C 3
│  └─ word under the cursor, this file ... *   then n / N
├─ a DIRECTORY you have visited .......... z part-of-name
└─ a COMMAND you ran before .............. Ctrl-r                 fzf history
```

```
Change many places…
├─ every match, no review ................ :%s/old/new/g          add c to confirm each
├─ every match, reviewing each ........... *  cgn new Esc  . . .  n n skips one
├─ a column of consecutive lines ......... Space v  j j  I/A/c/d … Esc
└─ scattered words at once ............... Ctrl-n Ctrl-n …  c … Esc Esc
```

```
Understand code…
├─ what is this? ......................... K                      hover docs
├─ where is it defined? .................. Ctrl-]                 back: Ctrl-t
├─ who uses it? .......................... grr                    quickfix list
├─ what is in this file? ................. Space o                outline panel (gO = list)
├─ what is wrong? ........................ ]d  /  [d              next / prev diagnostic
└─ rename it / fix it .................... grn  /  gra
```

```
Run things…
├─ a quick command, without leaving nvim . Space t  (or F7)       floating terminal
├─ a shell in a pane beside the code ..... :sp | term             Ctrl-\ Ctrl-n leaves it
├─ several shells in one window .......... tmux  Ctrl-b %  /  Ctrl-b "
└─ survive an SSH drop / closed terminal . tmux new -s work  →  tmux a -t work
                                           (screen -S / -r where tmux is missing)
```

---

## Coming from VS Code

Start in the project folder with plain `nvim`; `nvim .` opens the file tree
full-screen instead of as a sidebar. Press `i` to type and `Esc` when done.
Every key below is pressed after `Esc` (normal mode), and `:` commands end with
`Enter`.

| VS Code | nvim | VS Code | nvim |
|---|---|---|---|
| Explorer `Ctrl+Shift+E` | `Space e` | Quick Open `Ctrl+P` | `Space f` |
| Search in files `Ctrl+Shift+F` | `Space r` or `Ctrl-p` | Find / replace in file | `/text` · `:%s/old/new/gc` |
| Next / prev tab `Ctrl+PgDn` / `PgUp` | `L` / `H` | Close tab `Ctrl+W` | `Space x` |
| Split editor `Ctrl+\` | `:vsp` | Focus other side `Ctrl+1` / `2` | `Ctrl-w h` / `l`, or click |
| Save `Ctrl+S` | `:w` | Undo / redo | `u` / `Ctrl-r` |
| Add next match `Ctrl+D` | `Ctrl-n` | Toggle comment `Ctrl+/` | `gcc` · `gc` on a selection |
| Move line `Alt+↑` / `↓` | `Space k` / `Space j` | Column select `Shift+Alt+drag` | `Space v` |
| Hover | `K` | Go to definition `F12` | `Ctrl-]` |
| Go back `Alt+←` | `Ctrl-o` | Find references `Shift+F12` | `grr` |
| Rename `F2` | `grn` | Quick fix `Ctrl+.` | `gra` |
| Next problem `F8` | `]d` / `[d` | Outline `Ctrl+Shift+O` | `Space o` or `F6` |
| Terminal `` Ctrl+` `` | `Space t` or `F7` | Source Control | `:Git`, then `s` stage · `u` unstage · `cc` commit |
| Blame / diff | `:Git blame` / `:Gdiffsplit` | Save all and quit | `:wqa` (`:qa!` discards changes) |

In Windows Terminal:

- `Ctrl+V` is the terminal's paste and never reaches nvim. Column-select with
  `Space v`; paste with `p`.
- The mouse works inside nvim: click panes and files, scroll, drag a border to
  resize. Hold `Shift` while dragging to select text for the terminal's own
  copy (`Ctrl+C`).
- `Ctrl+Shift+T` opens a Windows Terminal tab: a separate full-size shell,
  outside nvim.

---

## Neovim

### Your keys — Space is the leader

```
Space ┬ e ...... file tree ........ NERDTree
      ├ f ...... find file ........ fzf :Files
      ├ r ...... search text ...... fzf :Rg         also Ctrl-p
      ├ o ...... code outline ..... Aerial          also F6
      ├ t ...... terminal ......... Floaterm        also F7 (works in insert + terminal mode)
      ├ u ...... undo history ..... Undotree
      ├ v ...... block select ..... = Ctrl-v, which Windows Terminal steals
      ├ x ...... close file tab ... keeps the pane (:bd closes it too)
      └ j / k .. move line down/up  in visual mode: moves the selection

H / L ...... previous / next file tab
```

Pressing a panel key again closes the panel. In visual mode, `Tab` / `Shift-Tab`
indent / dedent and keep the selection. A block edit (`Space v` … `I`) shows on
one line only until you press `Esc`; then it is applied to every line.

### Insert mode — completion and AI ghost text

```
Tab ──► grey AI text showing? ──yes──► accept it
             │ no
             ▼
        menu open? ──────────yes──► select next item     Shift-Tab = previous
             │ no                                         Enter     = confirm selected
             ▼
        insert a tab

Ctrl-y  same chain, but confirms the first menu item
Ctrl-e  same chain, but dismisses (AI text, then menu)
Ctrl-l  open the completion menu by hand            (Ctrl-Space too, but unreliable)
```

AI suggestions come from a local OpenAI-compatible server. The default is
`http://localhost:8000/v1`, and the first model it lists is used. You can override
three settings: `MINUET_ENDPOINT` (URL), `MINUET_MODEL` (the model to use) and
`MINUET_API_KEY`. Toggle suggestions with `:Minuet virtualtext toggle`.

### Code — LSP: basedpyright + ruff (Python)

| Key | Action | Key | Action |
|---|---|---|---|
| `K` | hover docs | `grn` | rename symbol |
| `Ctrl-]` | go to definition | `gra` | code action |
| `Ctrl-t` | jump back | `gri` | go to implementation |
| `grr` | references → quickfix | `gO` | document symbols |
| `]d` / `[d` | next / prev diagnostic | `Ctrl-s` (insert) | signature help |

Saving a `*.py` file formats it with ruff. **Not `gd`:** in nvim 0.11 `gd` is the
old buffer-local search; the LSP jump is `Ctrl-]`.

### Vim essentials

| Key | Action | Key | Action |
|---|---|---|---|
| `i` `a` / `I` `A` | insert before/after · line start/end | `o` / `O` | new line below / above |
| `v` / `V` / `Space v` | visual char / line / block | `Esc` / `Ctrl-[` | back to normal |
| `w` `b` `e` | word fwd / back / end | `0` `^` `$` | line start / first char / end |
| `gg` / `G` | top / bottom | `{` / `}` | prev / next paragraph |
| `Ctrl-u` / `Ctrl-d` | half page up / down | `%` | matching bracket |
| `*` / `#` | search word fwd / back | `n` / `N` | next / prev match |
| `x` / `dd` / `D` | delete char / line / to end | `yy` / `p` / `P` | yank line · paste after / before |
| `u` / `Ctrl-r` | undo / redo | `.` | repeat last change |
| `ci"` / `ca"` | change inside / around `"` | `r<c>` | replace one char |
| `>>` / `<<` / `==` | indent / dedent / auto-indent | `gcc` / `gc{motion}` | toggle comment |
| `:e file` / `:w` / `:q!` | open / save / quit without saving | `:bn` `:bp` `:bd` | next / prev / close buffer |

### File tabs, panes and the built-in terminal

`Ctrl-w` is two steps: press it, let go, then press the next key. The mouse
works too: click a pane to focus it, drag a border to resize.

| Key | Action | Key | Action |
|---|---|---|---|
| `H` / `L` | previous / next file tab | `Space x` | close file tab, keep the pane |
| `:sp` / `:vsp` (`Ctrl-w s` / `v`) | split stacked / side by side | `:sp file` / `:vsp file` | split with another file |
| `Ctrl-w h/j/k/l` | pane left / below / above / right | `Ctrl-w w` / `p` | next pane / last-used pane |
| `Ctrl-w =` | equalize sizes | `Ctrl-w _` / `\|` | maximize height / width |
| `10 Ctrl-w >` `<` `+` `-` | resize by 10 | `Ctrl-w q` / `o` | close pane / close all others |
| `:tabnew` / `:tabe file` | new tab | `Ctrl-w T` | move pane to a new tab |
| `gt` / `gT` / `3gt` | next / prev / tab 3 | `g<Tab>` | last-used tab |
| `:tabclose` / `:tabonly` | close tab / all others | `:ls` · `:b name` | list buffers · switch by name |
| `:sp \| term` / `:vsp \| term` | terminal in a new pane | `:tab term` | terminal in a new tab |
| `Ctrl-\ Ctrl-n` | leave terminal mode (pane keys work again) | `i` | type in the shell again |
| `:bd!` | close terminal and kill its shell | `exit` | same, from inside the shell |

The bar along the top lists open files, like VS Code's tabs. Close them with
`Space x`, not `:bd`, which also closes the pane the file was in. A Vim tab
(`gt`) is something else: a whole layout of panes. While more than one is open,
the bar lists those instead. Don't close a terminal with `:q`: the shell keeps
running hidden and `:qa` later fails with *job still running*. A bare `:term`
replaces the current pane; `:sp | term` keeps it.

### Plugins at a glance

| Plugin | Use it as |
|---|---|
| NERDTree | `Space e` toggle · `Enter` open · `s` / `i` open in split · `t` in tab · `go` preview · `u` up · `C` set root · `I` hidden files · `m` add/rename/delete · `?` help · `:NERDTreeFind` reveal current file |
| vim-surround | `ysiw)` wrap word · `cs"'` change `"`→`'` · `ds"` delete `"` |
| vim-visual-multi | `Ctrl-n` select word / add next · `q` skip · `Q` drop · `Esc` exit |
| vim-fugitive | `:Git` · `:Git blame` · `:Gdiffsplit` · `:Git log` |
| gitsigns | gutter marks automatically · `:Gitsigns blame_line` / `preview_hunk` / `reset_hunk` |
| nvim-autopairs · vim-closetag | close brackets, quotes and HTML tags as you type |

### Clipboard

`clipboard=unnamedplus`: plain `y` / `p` / `dd` already use the OS clipboard.
`"0p` pastes the last yank and skips deletes. Over SSH, yanks reach your laptop
via OSC 52; to paste *into* remote nvim, use the terminal's paste (`Ctrl-Shift-V`).

### Why no Alt / Ctrl-Space / Ctrl-v / Ctrl-s keys

| Avoided | Breaks where |
|---|---|
| `Alt-*` | gnome-terminal menus eat `Alt-f/e/v/…`; over SSH and tmux it races with `Esc` |
| `Ctrl-Space` | sends a NUL byte; IBus on Ubuntu grabs it |
| `Ctrl-v` / `Ctrl-c` | Windows Terminal and VS Code bind them to paste / copy |
| `Ctrl-s` / `Ctrl-q` | terminal flow control (`.zshrc` runs `stty -ixon`) |

### Where the config lives

The config is one file: [`.config/nvim/init.lua`](.config/nvim/init.lua) (vim-plug).
On Linux and WSL a stow symlink points to it. On Windows,
`%LOCALAPPDATA%\nvim\init.lua` is a one-line stub that `dofile`s it. Check
which file nvim actually loads with `:echo $MYVIMRC`.

---

## Keys not working?

A key can fail at two layers: the terminal never hands it to nvim, or nvim
receives it but the config or a plugin doesn't respond. Test them in this order,
from the repo directory:

```
a key does nothing
      │
      ▼
nvim -l tests/nvim_keymaps.lua            ← automated: ~60 tests, real nvim, your config (~1 min)
      │                                      nvim -l tests/nvim_keymaps.lua lsp   runs one group
      ├── FAIL ─► config / plugin / missing tool. The → line under the FAIL says what to run.
      │
      └── PASS ─► nvim is fine. The terminal is eating the key:
                  nvim --clean -S tests/nvim_keycheck.lua     ← press each key, see what arrives
                        │
                        └── FAIL ─► apply its hint, or use the Space-key alternative
```

Each automated test starts a fresh nvim with your real config. It types the
keys exactly as if pressed and checks the result: did the panel open, did the
line move, did the cursor land on the definition? Groups: environment ·
Space panels · editing · completion · LSP · AI.

Inside nvim: `:verbose nmap <Space>e` shows what a key does and which file defined
it · `:messages` · `:checkhealth` · `:checkhealth vim.lsp` · `:PlugStatus`.

| Symptom | Cause | Fix |
|---|---|---|
| `Ctrl-v` pastes | Windows Terminal / VS Code bind it | `Space v`, or delete `ctrl+v` from Windows Terminal `settings.json` |
| `F6` / `F7` do nothing | tmux/screen terminfo mangles F-keys | `Space o` / `Space t`; tmux: `set -g default-terminal tmux-256color` |
| `Ctrl-p` / `Ctrl-n` / `Ctrl-e` trigger VS Code | VS Code terminal grabs them | `"terminal.integrated.sendKeybindingsToShell": true` |
| `*` types `8`, `%` types `5` | VS Code WSL terminal | see README → Troubleshooting |
| `Space f` / `Space r`: *Failed to run "fzf --version"* | Windows nvim started from Git Bash got bash as `shell` | fixed in `init.lua` (pins `cmd.exe`); pull the repo |
| `Tab` never accepts AI text | no ghost text appears: the model is a reasoning or tiny model | `export MINUET_MODEL=<id from /v1/models>` |
| only ruff errors, no type errors | basedpyright + nvim 0.11 on a file outside any project | open it inside a project (`.git` / `pyproject.toml`), or `pixi global update nvim` (0.12) |
| `Ctrl-]` → *E426 tag not found* | LSP not attached / still analysing | wait a second; `:checkhealth vim.lsp` |
| `^M` at every pasted line end | `Ctrl-Shift-V` in insert mode keeps CRLF | paste with `p` or `Ctrl-R +`; clean up with `:%s/\r$//` |
| *E353: Nothing in register 8* | Shift didn't register on `"*` | just use `p` |
| *clipboard: No provider* | no xclip / wl-copy / win32yank | WSL: `win32yank.exe` on PATH · X11: `xclip` · SSH: OSC 52 (nvim ≥ 0.10) |

---

## Search from the shell

```
plocate ── NAMES, all of ~, instant (pre-built index) ── "where is that file?"
rg ─────── CONTENT, one tree, live ────────────────────── "which file says X?"
fzf ────── pick interactively from either list ────────── rg --files | fzf
```

### plocate — file names, instantly

| Command | Action |
|---|---|
| `plocate name` | every indexed path containing `name` |
| `plocate -i name` / `-b name` | case-insensitive / match the file name only |
| `plocate -r '\.ya?ml$'` | regex |
| `plocate -c name` | count only |
| `plocate_update` | rebuild the index now (`.zshrc` does it daily in the background) |

`setup.sh` builds plocate into `~/.local/bin` (Linux and WSL only, no sudo). It
indexes `$HOME`, minus `.git`, `node_modules`, `__pycache__` and `~/.cache`.
On WSL, the Windows drive under `/mnt/c` is **not** indexed; use `rg --files`
there instead.

### ripgrep (`rg`) — file contents

| Command | Action | Command | Action |
|---|---|---|---|
| `rg pat` | recursive search | `rg -i pat` | case-insensitive |
| `rg -t py pat` | only one file type | `rg -l pat` | file names only |
| `rg -C 3 pat` | 3 lines of context | `rg --hidden pat` | include hidden files |
| `rg --files \| rg name` | file names in this project (respects `.gitignore`) | `rg -w pat` | whole words |

---

## Shell: zsh + fzf

Plugins: `git` · `zsh-autosuggestions` · `z` · `colored-man-pages` · `fzf` · `zsh-syntax-highlighting`.

| Key / command | Action | Key / command | Action |
|---|---|---|---|
| `→` / `End` | accept autosuggestion | `Ctrl-→` | accept next word |
| `Ctrl-r` | fuzzy history | `Ctrl-t` | fuzzy-pick file, paste path |
| `Alt-c` | fuzzy-pick dir and `cd` | `cd **<Tab>` | fuzzy completion |
| `z foo` / `z foo bar` | jump to frecent dir | `z -l foo` | list candidates |

| Alias | Expands to | Alias | Expands to |
|---|---|---|---|
| `gst` | `git status` | `gd` / `gds` | `git diff` / `--staged` |
| `ga` / `gaa` | `git add` / `--all` | `gc` / `gca` | `git commit -v` / `-av` |
| `gp` / `gl` | `git push` / `pull` | `gco` / `gb` | `git checkout` / `branch` |
| `glog` | one-line graph log | `grb` / `grbi` | `git rebase` / `-i` |

Full list: `alias | grep '^g'`.

---

## tmux / screen

Press the prefix first: tmux `Ctrl-b`, screen `Ctrl-a`.

| Action | tmux | screen |
|---|---|---|
| new named session | `tmux new -s NAME` | `screen -S NAME` |
| list / attach | `tmux ls` / `tmux a -t NAME` | `screen -ls` / `screen -r NAME` |
| detach | `d` | `d` |
| new window / rename | `c` / `,` | `c` / `A` |
| next / prev / jump | `n` / `p` / `0-9` | `n` / `p` / `0-9` |
| list windows | `w` | `"` |
| kill window | `&` | `k` |
| split side-by-side / stacked | `%` / `"` | `\|` / `S` |
| move between panes | arrows · `o` cycles | `Tab` cycles |
| zoom pane / kill pane | `z` / `x` | — / `X` |
| copy mode / paste | `[` (vi keys, `Space`, `Enter`) / `]` | `Esc` / `]` |

---

## Small tools

| Command | Action | Command | Action |
|---|---|---|---|
| `eza -la` | long listing with hidden files | `eza --git -l` | with git status per file |
| `eza --tree -L 2` | tree, two levels | `tree -L 2 -a` | tree incl. hidden |
| `diskus` | fast directory size (`du -sh`) | `jq . file.json` | pretty-print JSON |

Reminders: `cmd 2>&1 | less` merges stderr · `Ctrl-z` / `fg` / `bg` suspend and resume ·
`sudo !!` re-runs the last command with sudo.

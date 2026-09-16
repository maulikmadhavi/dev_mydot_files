# Cheatsheet

Quick reference for the tools configured by this repo. Custom mappings (those defined in `.config/nvim/init.vim`, `.zshrc`, etc.) are marked **custom**.

---

## Neovim / Vim

### Modes
| Key | Mode |
|---|---|
| `i` / `a` | Insert before / after cursor |
| `I` / `A` | Insert at start / end of line |
| `o` / `O` | New line below / above |
| `v` / `V` / `Ctrl-v` | Visual char / line / block |
| `:` | Command-line |
| `Esc` / `Ctrl-[` | Back to Normal |

### Movement (Normal mode)
| Key | Action |
|---|---|
| `h j k l` | Left / Down / Up / Right |
| `w` / `b` / `e` | Next / prev word, end of word |
| `0` / `^` / `$` | Line start / first non-blank / end |
| `gg` / `G` | File top / bottom |
| `{` / `}` | Prev / next paragraph |
| `Ctrl-u` / `Ctrl-d` | Half page up / down |
| `Ctrl-b` / `Ctrl-f` | Page up / down |
| `%` | Jump to matching bracket |
| `*` / `#` | Search word under cursor fwd / back |
| `n` / `N` | Next / prev search match |

### Edit
| Key | Action |
|---|---|
| `x` / `X` | Delete char under / before cursor |
| `dd` / `D` | Delete line / to end of line |
| `yy` / `Y` | Yank line / to end |
| `p` / `P` | Paste after / before |
| `u` / `Ctrl-r` | Undo / redo |
| `.` | Repeat last change |
| `r<c>` | Replace single char with `<c>` |
| `ci"` / `ca"` | Change inside / around `"` |
| `>>` / `<<` | Indent / dedent line |
| `==` | Auto-indent line |

### Files, buffers, splits
| Key | Action |
|---|---|
| `:e <file>` | Open file |
| `:w` / `:q` / `:wq` / `:q!` | Save / quit / save+quit / force-quit |
| `:bn` / `:bp` / `:bd` | Next / prev buffer; close buffer |
| `:sp` / `:vsp` | Horizontal / vertical split |
| `Ctrl-w h/j/k/l` | Move between splits |
| `Ctrl-w =` | Equalize split sizes |

### System clipboard

This repo sets `clipboard=unnamedplus` in `init.vim`, so the **default register *is* the system clipboard** — plain `y` / `p` / `yy` / `dd` already round-trip to the OS clipboard. You only need explicit register prefixes for the cases below.

| Key | Action |
|---|---|
| `y` / `p` / `yy` / `dd` | Default — uses system clipboard (`+` register) |
| `"+y` / `"+p` | Explicit system clipboard yank / paste |
| `"*y` / `"*p` | X11 primary selection on Linux; same as `+` on WSL/Windows |
| `"0p` | Paste the last *yank* (skips deletes) |

> **Gotcha 1 — `E353: Nothing in register 8`.** `*` and `+` are shifted keys (`Shift-8`, `Shift-=`). If Shift doesn't hold you end up reading `"8` (the numbered register, usually empty). Use plain `p`.

> **Gotcha 2 — `^M` at end of every pasted line.** That means the paste bypassed `g:clipboard`. The usual cause is `Ctrl-Shift-V` (terminal paste) in **insert mode**, which sends raw bytes — so CRLF from a Windows source (VSCode, Notepad) survives. Fix: paste with `p` in normal mode or `Ctrl-R +` in insert mode — both use `win32yank -o --lf` which strips the CR. To clean an already-polluted file: `:%s/\r$//` (trailing CR) or `:%s/\r//g` (everywhere).

> **Gotcha 3 — `clipboard: No provider` on a remote server.** This means nvim couldn't find a clipboard tool (no xclip / wl-copy / DISPLAY). On SSH sessions the included `init.vim` falls back to **OSC 52** (nvim ≥ 0.10), which pipes yanks back through the terminal to your *local* clipboard. After updating, just `yy` and the line should be on your laptop's clipboard. Paste *into* vim from outside still needs terminal paste (Ctrl-Shift-V) — OSC 52 read is almost never supported by terminals.

### Custom mappings (this repo's `init.vim`)

**Leader is `Space`.** Panel toggles and pickers live behind the leader so they
don't shadow vim's built-in `Ctrl-` keys (`Ctrl-f` page forward, `Ctrl-l`
clear search highlight + redraw, `Ctrl-x` decrement number, `Ctrl-t` pop tag
stack, `Ctrl-g` file info — all still work).

Everything below uses only `Space`+letter or plain `Ctrl`+letter, so the same
keys behave identically on Windows PowerShell, WSL, and bare Linux — including
over SSH, tmux and screen. See [Portability](#why-these-keys-portability) for
what's deliberately avoided.

| Key | Action |
|---|---|
| `Space e` | Toggle NERDTree file explorer |
| `Space f` | `:Files` (fzf fuzzy file finder) |
| `Space r` | `:Rg` (live ripgrep project search) |
| `Space u` | Toggle Undotree (visual undo history) |
| `Space t` | Toggle Floaterm floating terminal |
| `Space o` | Toggle Aerial code outline (symbols from LSP/treesitter, no ctags) |
| `Space v` | Blockwise-visual — same as `Ctrl-v`, which most terminals steal |
| `Space j` / `Space k` | Move line (or visual selection) down / up — vim-move |
| `Ctrl-p` | `:Rg` — second binding for the same thing (normal-mode `Ctrl-p` is just `k`) |
| `F6` / `F7` | Aerial / Floaterm — F-key aliases; `F7` also works from insert and terminal mode |
| `Tab` / `Shift-Tab` (visual) | Indent right / left (keeps selection; inserts a **hard tab** — `init.vim` has no `expandtab`) |
| `Tab` (insert) | **Smart**: accept AI ghost text if visible → else next completion item → else literal tab |
| `Shift-Tab` (insert) | Prev completion item (literal shift-tab otherwise) |
| `Enter` (insert) | Confirm selected completion |
| `Ctrl-y` (insert) | **Smart accept**: AI ghost text → else confirm completion → else literal key |
| `Ctrl-e` (insert) | **Smart dismiss**: AI ghost text → else close completion popup → else literal key |
| `Ctrl-l` (insert) | Manually trigger completion (`Ctrl-Space` also works, but is unreliable — see below) |

### Why these keys (portability)

The bindings avoid four whole categories of key that break in at least one of
the three environments:

| Avoided | Why |
|---|---|
| **`Alt` / `Meta`** | gnome-terminal on Ubuntu binds `Alt-f/e/v/s/t/h` to its menu bar — `Alt-e` (the old AI-dismiss key) opened the Edit menu instead. Over SSH and tmux, `Alt` is sent as an `ESC` prefix that races with a real `<Esc>`. |
| **`Ctrl-Space`** | Sends a NUL byte that not every terminal forwards, and IBus on Ubuntu claims it as the input-method switcher. |
| **`Ctrl-v` / `Ctrl-c`** | Windows Terminal binds both (`Terminal.PasteFromClipboard` / `CopyToClipboard`), so they never reach nvim. `Ctrl-c` at least falls through when nothing is selected; `Ctrl-v` never does — hence `Space v`. |
| **`Ctrl-s` / `Ctrl-q`** | Terminal flow control (XON/XOFF). Harmless *inside* nvim, which puts the tty in raw mode, but it freezes the shell on WSL/Linux. `.zshrc` now runs `stty -ixon` to disable it. |

To use the real `Ctrl-v` for blockwise-visual instead of `Space v`, delete the
`ctrl+v` entry from Windows Terminal's `settings.json` keybindings and paste
with `Ctrl-Shift-V`.

### Editing many lines at once

Three ways, easiest first.

**1. `cgn` + `.` — the one to learn.** No plugin, no special keys, works over SSH
and in any terminal. Put the cursor on the word, then:

| Key | Action |
|---|---|
| `*` | Search for the word under the cursor (also lands you on the next one) |
| `cgn` | **c**hange the next match — type the replacement, then `Esc` |
| `.` | Repeat on the next match |
| `n` `n` | Skip a match — **two** presses, see below |

So `*` `cgn` `newname` `Esc` then `.` `.` `.` renames one occurrence per `.`.
This beats multi-cursor for most renames: you review each change as you make
it, and there's nothing to exit.

> **Skipping takes two `n`s, not one.** `.` changes the match at *or after* the
> cursor. A single `n` moves the cursor onto the next match — which is the same
> one `.` was already going to change, so `n` `.` and a bare `.` do exactly the
> same thing. To leave a match alone, press `n` twice: once to land on it, once
> to move past it, then `.`.

If you don't need to skip any, just use `:%s/old/new/g` — add the `c` flag
(`:%s/old/new/gc`) to confirm each one interactively.

**2. `Space v` — visual block**, for rectangular edits on consecutive lines.
Extend with `j`/`k`, then `I` (insert before), `A` (append after), `c`, `d`, or
`r<c>`. **The edit only replicates to the other lines when you press `Esc`** —
until then you'll see it on one line only, which is normal.

- Comment 5 lines: `Space v` `jjjj` `I` `# ` `Esc`
- Append `,` to ragged lines: `Space v` `jjjj` `$` `A` `,` `Esc` (the `$` is what
  handles lines of different lengths)

**3. `Ctrl-n` — multi-cursor** (vim-visual-multi), for scattered occurrences.
`Ctrl-n` selects the word and again adds the next; `q` skips one, `Q` drops a
cursor, `Tab` switches selections ↔ bare cursors, `Esc` exits. Then edit
normally and it applies at every cursor. Requires `:PlugInstall`.

> **Gotcha — `Ctrl-v` pastes instead of entering block mode.** Windows Terminal
> binds `ctrl+v` to `Terminal.PasteFromClipboard`, so the key never reaches
> nvim; VS Code's integrated terminal does the same. That's why `Space v` exists
> — it always gets through. To free the real `Ctrl-v` instead, delete the
> `ctrl+v` entry from Windows Terminal's `settings.json` keybindings and paste
> with `Ctrl-Shift-V`.

### LSP — Python via basedpyright + ruff (nvim 0.11 built-in keymaps)

basedpyright provides completions/types/auto-imports; ruff lints and **formats on save** (`*.py`).
| Key | Action |
|---|---|
| `K` | Hover docs |
| `Ctrl-]` | Go to definition (via `tagfunc`; `Ctrl-t` jumps back) |
| `grr` | List references |
| `grn` | Rename symbol |
| `gra` | Code action |
| `gri` | Go to implementation |
| `gO` | Document symbols |
| `[d` / `]d` | Prev / next diagnostic |
| `Ctrl-s` (insert) | Signature help |

> **Not `gd`.** nvim 0.11 does *not* map `gd` to the LSP — plain `gd` is the old
> built-in "search for the local declaration", which only looks at the current
> buffer and is wrong as often as it's right. The LSP-backed jump is `Ctrl-]`
> (nvim points `tagfunc` at the language server), and `Ctrl-t` pops back.

### AI completion (minuet-ai, local LLM)

Copilot-style grey **ghost-text** suggestions, generated by a local
OpenAI-compatible server (default `http://localhost:8000/v1`; set
`MINUET_ENDPOINT` to point elsewhere). On startup nvim auto-discovers the served
model from `GET /v1/models` — swap models on the server and nvim follows. If the
server is unreachable, AI completion silently stays off (no errors).

| Key / command | Action |
|---|---|
| `Tab` | Accept the visible suggestion (Copilot-style; falls through to completion menu / literal tab when no ghost text) |
| `Ctrl-y` | Accept the visible suggestion (falls through to confirming a normal completion) |
| `Ctrl-e` | Dismiss the visible suggestion (falls through to closing the completion popup) |
| `:Minuet virtualtext toggle` | Turn auto-suggestions on / off (prints new state) |
| `:Minuet virtualtext enable` / `disable` | Explicit on / off |

Notes:
- The toggle is per-session — every nvim restart begins **enabled**.
- Env overrides (set before launching nvim): `MINUET_ENDPOINT` (base URL),
  `MINUET_MODEL` (skip auto-discovery), `MINUET_API_KEY` (bearer; default `dummy`,
  fine for vLLM).

### Plugin shortcuts in `init.vim`
- **vim-surround** — `ysiw)` wrap word in `()`, `cs"'` change `"` → `'`, `ds"` delete surrounding `"`.
- **Commenting (built into nvim 0.10+)** — `gcc` toggle line comment, `gc<motion>` toggle range (e.g. `gcap` for paragraph, `gc` in visual mode).
- **vim-visual-multi** — `Ctrl-n` on a word selects it; keep pressing to add the next occurrence (multiple cursors). `q` skips one, `Q` removes a cursor, `Esc` exits. (`Ctrl-n` is exclusively multi-cursor's — NERDTree moved to `Space e`.)
- **vim-move** — `Space j` / `Space k` move current line or visual selection down / up. (Its `Alt-j`/`Alt-k` defaults are disabled via `g:move_map_keys = 0`; `Alt` is unreliable over SSH and tmux.)
- **vim-fugitive** — `:Git` status, `:Git blame`, `:Gdiffsplit`, `:Git log`.
- **gitsigns.nvim** — change markers in the gutter automatically; on demand: `:Gitsigns blame_line`, `:Gitsigns preview_hunk`, `:Gitsigns reset_hunk`. No keymaps by design.
- **nvim-autopairs** — auto-closes `()[]{}`""''` as you type; accepting a function completion inserts `()` with the cursor inside.
- **minuet-ai** — AI ghost-text suggestions; see the "AI completion" section above.
- **vim-closetag** — auto-closes HTML/XML tags as you type; no keys to learn.

---

## Tmux  (prefix: `Ctrl-b`)

### Sessions (outside tmux)
| Command | Action |
|---|---|
| `tmux new -s NAME` | New named session |
| `tmux ls` | List sessions |
| `tmux a -t NAME` | Attach |
| `tmux kill-session -t NAME` | Kill |

### Inside tmux (after pressing `Ctrl-b`)
| Key | Action |
|---|---|
| `d` | Detach |
| `s` | Switch session (list) |
| `$` | Rename session |
| `c` | New window |
| `,` | Rename window |
| `n` / `p` | Next / prev window |
| `0`–`9` | Jump to window by number |
| `w` | List windows |
| `&` | Kill window |
| `%` | Split pane left/right |
| `"` | Split pane top/bottom |
| `o` | Cycle to next pane |
| `←↑↓→` | Move to pane in direction |
| `z` | Toggle pane zoom |
| `x` | Kill pane |
| `{` / `}` | Swap panes |
| `Space` | Cycle layouts |
| `[` | Enter copy mode (vi keys, `Space` to select, `Enter` to copy) |
| `]` | Paste |

---

## GNU screen  (prefix: `Ctrl-a`)

### Sessions (outside screen)
| Command | Action |
|---|---|
| `screen -S NAME` | New named session |
| `screen -ls` | List sessions |
| `screen -r NAME` | Reattach |
| `screen -dr NAME` | Detach others + reattach |

### Inside screen (after pressing `Ctrl-a`)
| Key | Action |
|---|---|
| `c` | New window |
| `n` / `p` | Next / prev window |
| `0`–`9` | Jump to window by number |
| `A` | Rename window |
| `"` | List windows |
| `k` | Kill window |
| `d` | Detach |
| `S` / `\|` | Split horizontally / vertically |
| `Tab` | Cycle regions |
| `X` | Remove region |
| `Esc` | Enter copy mode (`Space` to select, `Enter` to copy) |
| `]` | Paste |

---

## fzf (terminal)

Enabled via the oh-my-zsh `fzf` plugin.

| Key | Action |
|---|---|
| `Ctrl-t` | Fuzzy-pick files, paste paths into command line |
| `Ctrl-r` | Fuzzy reverse history search |
| `Alt-c` | Fuzzy-pick directory and `cd` into it |
| `**<Tab>` | Fuzzy completion (e.g. `cd **<Tab>`) |

---

## Zsh / oh-my-zsh

Active plugins (set in `.zshrc`): `git`, `zsh-autosuggestions`, `z`, `colored-man-pages`, `fzf`, `zsh-syntax-highlighting`.

### Autosuggestions
| Key | Action |
|---|---|
| `→` or `End` | Accept full suggestion |
| `Ctrl-→` | Accept next word of suggestion |
| `↑` | Match-prefix history search |
| `Ctrl-r` | Fuzzy history search (via fzf) |

### `z` (frecency directory jump)
| Command | Action |
|---|---|
| `z foo` | Jump to most-used dir matching `foo` |
| `z foo bar` | Match both `foo` and `bar` |
| `z -l foo` | List candidates without jumping |

### Common git plugin aliases
| Alias | Expands to |
|---|---|
| `gst` | `git status` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gc` / `gca` | `git commit -v` / `git commit -av` |
| `gp` / `gl` | `git push` / `git pull` |
| `gco` / `gb` | `git checkout` / `git branch` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `glog` | `git log --oneline --decorate --graph` |
| `grb` / `grbi` | `git rebase` / `git rebase -i` |

Run `alias | grep '^g'` for the full list.

---

## CLI utilities

### ripgrep (`rg`)
| Command | Action |
|---|---|
| `rg pattern` | Recursive search |
| `rg -i pattern` | Case-insensitive |
| `rg -t py pattern` | Restrict to file type (e.g. `py`, `rust`, `md`) |
| `rg -l pattern` | List matching filenames only |
| `rg --hidden pattern` | Include hidden files |
| `rg -C 3 pattern` | 3 lines of context |

### eza (modern `ls`)
| Command | Action |
|---|---|
| `eza` | Plain listing |
| `eza -l` | Long format |
| `eza -la` | Long + hidden |
| `eza --tree -L 2` | Tree view, 2 levels |
| `eza --git -l` | Show git status next to each file |

### tree / diskus
| Command | Action |
|---|---|
| `tree -L 2` | Show 2 levels |
| `tree -a` | Include hidden |
| `diskus` | Fast directory size (replaces `du -sh`) |

---

## Quick reminders

- `cmd1 \| cmd2` — pipe stdout of `cmd1` into `cmd2`.
- `cmd > file` / `cmd >> file` — redirect (overwrite / append).
- `cmd 2>&1` — merge stderr into stdout.
- `Ctrl-z` / `fg` / `bg` — suspend / resume foreground or background.
- `Ctrl-r` (in zsh, with fzf) — fuzzy history search.
- `!!` — repeat last command (`sudo !!` re-runs it with sudo).

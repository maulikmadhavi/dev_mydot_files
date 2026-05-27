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
| Key | Action |
|---|---|
| `"+y` / `"+p` | Yank to / paste from system clipboard |
| `"*y` / `"*p` | X11 primary selection (Linux) |

### Custom mappings (this repo's `init.vim`)
| Key | Action |
|---|---|
| `Ctrl-f` | Focus NERDTree |
| `Ctrl-n` | Open NERDTree |
| `Ctrl-t` | Toggle NERDTree |
| `Ctrl-b` | Toggle NvimTree |
| `Ctrl-l` | Toggle Undotree |
| `Ctrl-g` | `:Files` (fzf fuzzy file finder) |
| `Ctrl-r` | `:Rg` (ripgrep search) |
| `Ctrl-x` | Toggle Floaterm terminal (works in term too) |
| `F6` | Toggle Tagbar |
| `Tab` (visual) | Indent right |
| `Shift-Tab` (visual) | Indent left |
| `Tab` / `Shift-Tab` (insert) | Navigate autocomplete popup |

### Plugin shortcuts in `init.vim`
- **vim-surround** — `ysiw)` wrap word in `()`, `cs"'` change `"` → `'`, `ds"` delete surrounding `"`.
- **vim-commentary** — `gcc` toggle line comment, `gc<motion>` toggle range (e.g. `gcap` for paragraph).
- **vim-move** — `Alt-j` / `Alt-k` move current line down / up.

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

# mydot_files

Collection of dotfiles for keeping shell, editor, and prompt config consistent across machines. One installer per OS; everything else is config that gets symlinked into `$HOME`.

For day-to-day key bindings and shortcuts (nvim custom mappings, tmux, screen, fzf, zsh plugins, ripgrep, eza, …) see [`cheatsheet.md`](cheatsheet.md).

---

## Quick start — Ubuntu / WSL / Linux (from a fresh account)

You only need a terminal. Run these in order.

### 1. Make sure prerequisites are available

The installer needs `git` and `curl` on PATH. Both are usually present on Ubuntu. If they are missing **and you have sudo**:

```bash
sudo apt update
sudo apt install -y git curl
```

If you don't have sudo, ask an admin to install `git` and `curl`, or use any pre-installed equivalents. Everything else is fetched into your home directory by [`pixi`](https://pixi.sh) — `setup.sh` itself never invokes `sudo`.

### 2. Clone the repo

Clone with `--recurse-submodules` so the included `oh-my-zsh` submodule is pulled in the same step:

```bash
git clone --recurse-submodules https://github.com/maulikmadhavi/dev_mydot_files.git ~/mydot_files
cd ~/mydot_files
```

### 3. Run the installer

```bash
./setup.sh
```

If you get `Permission denied`, make it executable first: `chmod +x setup.sh && ./setup.sh`.

The script prints a redrawn checklist at every step so you can see what's done, what's running, and what's still pending:

```
════════════════════════════════════════════════════════════════
  Setup Progress
════════════════════════════════════════════════════════════════
  [✓] Install Pixi + base packages
  [✓] Clean conflicting configs
  [▶] Install nvm + Node LTS  ← running
  [ ] Install vim-plug
  [ ] Initialize oh-my-zsh submodule
  [ ] Stow dotfiles into $HOME
  [ ] Install zsh plugins
  [ ] Install nvim plugins
  [ ] Install plocate + index $HOME
  [ ] Set zsh as default shell
════════════════════════════════════════════════════════════════
```

Toward the end the script tries `chsh` to make `zsh` your login shell. On machines where you can't change the login shell (no `/etc/shells` entry for the pixi-installed zsh, or no PAM access), `chsh` is skipped with a note — the stowed `.bashrc` hands local interactive Bash sessions to `zsh -l` when `zsh` is available, so opening a new terminal will still drop you into zsh either way. SSH sessions are intentionally left in the server-selected shell.

### 4. Restart your terminal

Close and reopen the terminal window. The new prompt should be `zsh` with the configured theme, and `vim` should be aliased to `nvim`.

---

## Quick start — Windows (PowerShell)

Open PowerShell as your normal user (not Administrator):

```powershell
# 1. Install git if not present
winget install --id Git.Git -e

# 2. Clone
git clone --recurse-submodules https://github.com/maulikmadhavi/dev_mydot_files.git $HOME\mydot_files
cd $HOME\mydot_files

# 3. Allow local scripts for this session if needed
Set-ExecutionPolicy -Scope Process Bypass

# 4. Run the installer
.\setup_powershell_omp.ps1
```

After install, configure your terminal (Windows Terminal, etc.) to use **FiraCode Nerd Font**, then restart it.

---

## What each installer does

### `setup.sh` (Linux)
- Installs [`pixi`](https://pixi.sh), then via pixi: `tmux`, `nvim`, `zsh`, `fzf`, `ripgrep`, `eza`, `stow`, `basedpyright`, `ruff`, `tree`, `diskus`, `xclip`, `jq`, `yarn`, `git`, `gcc`/`gxx`/`make`/`cmake`.
- Builds [`plocate`](https://plocate.sesse.net) from source into `~/.local/bin` (not on conda-forge, and apt would need sudo) and indexes `$HOME`; `.zshrc` refreshes the index daily.
- Installs `nvm` + Node LTS.
- Installs `vim-plug` and runs `:PlugInstall` for the plugins in `.config/nvim/init.lua`.
- Initializes the `oh-my-zsh` submodule and symlinks it to `~/.oh-my-zsh`.
- Clones `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- Uses `stow` to symlink every tracked dotfile into `$HOME`.
- Attempts to switch your default login shell to `zsh` via `chsh` (best-effort — falls back to `.bashrc`'s `exec zsh -l` if `chsh` is blocked).

### `setup_powershell_omp.ps1` (Windows)
- Installs `pixi`, then via pixi: `yarn`, `basedpyright`, `ruff`, `fzf`, `diskus`, `tree`, `ripgrep`, `eza`, `jq`, `gcc`, `gxx`, `make`, `cmake`. (plocate is Linux-only.)
- Installs `git`, `oh-my-posh`, `PSReadLine`, FiraCode Nerd Font, Neovim, `psmux` (tmux for Windows).
- Installs `vim-plug` and writes a one-line `%LOCALAPPDATA%\nvim\init.lua` stub that loads the repo's `.config/nvim/init.lua`, so Windows and WSL share one config.
- Writes `$PROFILE` with: oh-my-posh init (custom `zash.omp.json` theme), PSReadLine predictive autocomplete, and Linux-style aliases (`ls`, `cat`, `grep`, …). Idempotent — safe to re-run without duplicating lines.

---

## Notes

- **`secret.sh`** — intentionally not in the repo. Create `~/.secret.sh` manually for machine-specific env vars; `.bashrc` will source it if present.
- **`oh-my-zsh`** — included as a git submodule and symlinked manually (not stowed) to avoid NTFS permission issues on WSL.
- **Clipboard on WSL** — install [`win32yank.exe`](https://github.com/equalsraf/win32yank) on the Windows side for bidirectional nvim ↔ Windows clipboard. The nvim config auto-detects WSL and uses it.
- **Clipboard on bare Linux** — `xclip` (installed by `setup.sh`) covers X11. Wayland users: `sudo apt install wl-clipboard` separately.

## Troubleshooting

- **`./setup.sh: Permission denied`** — `chmod +x setup.sh` and retry.
- **`chsh: ... is not in /etc/shells` or PAM error** — non-fatal. The stowed `.bashrc` hands local interactive Bash sessions to `zsh -l` when it is installed, so new local terminals will still launch zsh without needing the login shell changed. SSH sessions remain in the remote account's configured shell.
- **`pixi: command not found` after install** — open a new shell, or `export PATH="$HOME/.pixi/bin:$PATH"`.
- **nvim plugins missing** — open nvim and run `:PlugInstall` manually.
- **An nvim key does nothing** — run `nvim -l tests/nvim_keymaps.lua` from the repo: it drives every documented keybinding in a real nvim and prints a fix for each failure. If those pass, `nvim --clean -S tests/nvim_keycheck.lua` shows which keys your terminal never delivers. See [cheatsheet → Keys not working?](cheatsheet.md#keys-not-working).
- **PowerShell `cannot be loaded because running scripts is disabled`** — `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.
- **`Shift-<digit>` produces just the digit in vim (e.g. `%` → `5`, `*` → `8`) — only in VSCode's integrated terminal under WSL.** Notepad, Windows Terminal, and plain `wsl.exe` all work; only VSCode's WSL-Remote terminal rewrites the key. Try one of:
  1. Open VSCode → `Ctrl-K Ctrl-S` (Keyboard Shortcuts), search `shift+5` — if anything is bound (often by a Vim/vscodevim extension), remove it or restrict its `when` clause to exclude `terminalFocus`.
  2. Add `"terminal.integrated.sendKeybindingsToShell": true` to VSCode `settings.json` so all key combinations are forwarded to the shell.
  3. Run vim from Windows Terminal / `wsl.exe` instead of VSCode's integrated terminal for serious editing sessions.

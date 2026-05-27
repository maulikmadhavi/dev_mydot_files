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
  [ ] Set zsh as default shell
════════════════════════════════════════════════════════════════
```

Toward the end the script tries `chsh` to make `zsh` your login shell. On machines where you can't change the login shell (no `/etc/shells` entry for the pixi-installed zsh, or no PAM access), `chsh` is skipped with a note — the stowed `.bashrc` does `exec zsh -l` for interactive shells, so opening a new terminal will still drop you into zsh either way.

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
- Installs [`pixi`](https://pixi.sh), then via pixi: `tmux`, `nvim`, `zsh`, `fzf`, `stow`, `python-lsp-server`, `tree`, `diskus`, `xclip`, `yarn`, `git`.
- Installs `nvm` + Node LTS.
- Installs `vim-plug` and runs `:PlugInstall` for the plugins in `.config/nvim/init.vim`.
- Initializes the `oh-my-zsh` submodule and symlinks it to `~/.oh-my-zsh`.
- Clones `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- Uses `stow` to symlink every tracked dotfile into `$HOME`.
- Attempts to switch your default login shell to `zsh` via `chsh` (best-effort — falls back to `.bashrc`'s `exec zsh -l` if `chsh` is blocked).

### `setup_powershell_omp.ps1` (Windows)
- Installs `pixi`, then via pixi: `yarn`, `python-lsp-server`, `fzf`, `diskus`, `ripgrep`, `eza`, `gcc`, `gxx`, `make`, `cmake`.
- Installs `git`, `oh-my-posh`, `PSReadLine`, FiraCode Nerd Font, Neovim, `psmux` (tmux for Windows).
- Installs `vim-plug` and copies `init.vim` into `$HOME\.config\nvim\`.
- Writes `$PROFILE` with: oh-my-posh init (custom `zash.omp.json` theme), PSReadLine predictive autocomplete, and Linux-style aliases (`ls`, `cat`, `grep`, …). Idempotent — safe to re-run without duplicating lines.

---

## Notes

- **`secret.sh`** — intentionally not in the repo. Create `~/.secret.sh` manually for machine-specific env vars; `.bashrc` will source it if present.
- **`oh-my-zsh`** — included as a git submodule and symlinked manually (not stowed) to avoid NTFS permission issues on WSL.
- **Clipboard on WSL** — install [`win32yank.exe`](https://github.com/equalsraf/win32yank) on the Windows side for bidirectional nvim ↔ Windows clipboard. The init.vim auto-detects WSL and uses it.
- **Clipboard on bare Linux** — `xclip` (installed by `setup.sh`) covers X11. Wayland users: `sudo apt install wl-clipboard` separately.

## Troubleshooting

- **`./setup.sh: Permission denied`** — `chmod +x setup.sh` and retry.
- **`chsh: ... is not in /etc/shells` or PAM error** — non-fatal. The stowed `.bashrc` already does `exec zsh -l` on interactive shells, so new terminals will still launch zsh without needing the login shell changed.
- **`pixi: command not found` after install** — open a new shell, or `export PATH="$HOME/.pixi/bin:$PATH"`.
- **nvim plugins missing** — open nvim and run `:PlugInstall` manually.
- **PowerShell `cannot be loaded because running scripts is disabled`** — `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.
- **`Shift-<digit>` produces just the digit in vim (e.g. `%` → `5`, `*` → `8`) — only in VSCode's integrated terminal under WSL.** Notepad, Windows Terminal, and plain `wsl.exe` all work; only VSCode's WSL-Remote terminal rewrites the key. Try one of:
  1. Open VSCode → `Ctrl-K Ctrl-S` (Keyboard Shortcuts), search `shift+5` — if anything is bound (often by a Vim/vscodevim extension), remove it or restrict its `when` clause to exclude `terminalFocus`.
  2. Add `"terminal.integrated.sendKeybindingsToShell": true` to VSCode `settings.json` so all key combinations are forwarded to the shell.
  3. Run vim from Windows Terminal / `wsl.exe` instead of VSCode's integrated terminal for serious editing sessions.

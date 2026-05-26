# mydot_files

Collection of dotfiles for keeping shell, editor, and prompt config consistent across machines.

## Install

Clone the repo with the oh-my-zsh submodule, then run the script for your OS:

```bash
git clone --recurse-submodules <repo-url> ~/mydot_files
cd ~/mydot_files
```

### Ubuntu / WSL / Linux

```bash
./setup.sh
```

Installs (via [pixi](https://pixi.sh)) `tmux`, `nvim`, `zsh`, `fzf`, `stow`, `python-lsp-server`, `xclip`, and friends. Also installs `nvm`, `vim-plug`, `oh-my-zsh` (symlinked from the submodule), and the `zsh-autosuggestions` / `zsh-syntax-highlighting` plugins. Dotfiles are linked into `$HOME` with `stow`, and the default shell is switched to `zsh`.

### Windows (PowerShell)

```powershell
.\setup_powershell_omp.ps1
```

Installs `pixi`, `git`, `oh-my-posh`, `PSReadLine`, FiraCode Nerd Font, Neovim + vim-plug, `psmux` (tmux for Windows), and `ripgrep`/`eza`/`gcc`/`cmake` via pixi. Writes the PowerShell `$PROFILE` with oh-my-posh init (using a custom `zash.omp.json` theme), PSReadLine predictive autocomplete, and Linux-style aliases (`ls`, `cat`, `grep`, …).

After install: configure your terminal to use FiraCode Nerd Font, then restart it.

## Notes

- `secret.sh` is intentionally not in the repo. Create `~/.secret.sh` manually for machine-specific env vars; `.bashrc` will source it if it exists.
- `oh-my-zsh` is included as a git submodule and symlinked manually (not stowed) to avoid NTFS permission issues on WSL.
- Clipboard: on WSL, [`win32yank.exe`](https://github.com/equalsraf/win32yank) is required for bidirectional nvim ↔ Windows clipboard. On bare Linux, `xclip` (installed by `setup.sh`) covers X11; Wayland users need `wl-clipboard` separately.

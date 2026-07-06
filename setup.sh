#!/usr/bin/env bash
# Bootstrap script for Ubuntu / WSL / Linux. Safe to re-run.

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

# Self-update: pull latest dotfiles so a re-run on any machine picks up new
# files (e.g. utils.sh). Skipped if not a git checkout or pull fails (offline).
if [ -d "$REPO_DIR/.git" ]; then
    git -C "$REPO_DIR" pull --ff-only 2>/dev/null \
        || echo "Note: could not 'git pull' (offline or diverged); continuing with the current checkout."
fi

# === Progress display

STEPS=(
  "Install Pixi + base packages"
  "Clean conflicting configs"
  "Install nvm + Node LTS"
  "Install vim-plug"
  "Initialize oh-my-zsh submodule"
  "Stow dotfiles into \$HOME"
  "Install zsh plugins"
  "Install nvim plugins"
  "Set zsh as default shell"
)
CURRENT_STEP=-1
STEP_FAILED=()

# Mark the current step as failed (setup continues; the final summary shows a
# red ✗ and the script exits non-zero). Append to a critical command:
#   some_command || fail_step
fail_step() { STEP_FAILED[$CURRENT_STEP]=1; }

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  Setup Progress"
  echo "════════════════════════════════════════════════════════════════"
  for i in "${!STEPS[@]}"; do
    if   (( i <  CURRENT_STEP )); then printf "  \033[0;32m[✓]\033[0m %s\n"             "${STEPS[$i]}"
    elif (( i == CURRENT_STEP )); then printf "  \033[1;33m[▶]\033[0m %s  ← running\n" "${STEPS[$i]}"
    else                               printf "  \033[0;37m[ ]\033[0m %s\n"             "${STEPS[$i]}"
    fi
  done
  echo "════════════════════════════════════════════════════════════════"
  echo ""
}

# Honest summary: shows what actually happened, returns 1 if anything failed.
step_complete() {
  local any_fail=0 i
  for i in "${!STEP_FAILED[@]}"; do any_fail=1; done
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  if [ "$any_fail" -eq 0 ]; then
    echo "  Setup Complete!"
  else
    echo "  Setup finished WITH ERRORS — see failed steps below"
  fi
  echo "════════════════════════════════════════════════════════════════"
  for i in "${!STEPS[@]}"; do
    if [ -n "${STEP_FAILED[$i]:-}" ]; then
      printf "  \033[0;31m[✗]\033[0m %s\n" "${STEPS[$i]}"
    else
      printf "  \033[0;32m[✓]\033[0m %s\n" "${STEPS[$i]}"
    fi
  done
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  return "$any_fail"
}

# === 1. Install Pixi + base packages

step
command -v pixi >/dev/null 2>&1 || curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"
# Package list kept in parity with setup_powershell_omp.ps1 (which swaps
# tmux->psmux and installs git/nvim via winget instead).
pixi global install tmux yarn git nvim zsh basedpyright ruff stow tree fzf \
    diskus xclip ripgrep eza gcc gxx make cmake universal-ctags jq || fail_step

# Fast hashers for compare_fast_directories (utils.sh). Best-effort and in
# their own commands: b3sum has no linux-aarch64 conda build, so it must not
# abort the bootstrap on ARM. xxhash (xxh128sum/xxhsum) covers all platforms;
# utils.sh falls back to sha1sum/md5sum if neither is present.
pixi global install xxhash 2>/dev/null || echo "Note: xxhash unavailable; compare_fast_directories will fall back to sha1sum/md5sum."
pixi global install b3sum  2>/dev/null || echo "Note: b3sum unavailable on this platform (e.g. linux-aarch64); using xxhash/sha1sum instead."

# === 2. Clean conflicting configs

step
if [ -f ~/.config/nvim/init.vim ] && [ -f ~/.config/nvim/init.lua ]; then
    echo "Removing conflicting init.vim (keeping init.lua)"
    rm ~/.config/nvim/init.vim
fi

# === 3. nvm + Node LTS

step
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts || fail_step

# === 4. vim-plug

step
# A failed download is only a real failure when plug.vim is missing — if a
# previous run installed it, a network blip just means we keep that copy.
PLUG_VIM="$HOME/.local/share/nvim/site/autoload/plug.vim"
if ! curl -fLo "$PLUG_VIM" --create-dirs --retry 3 \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; then
    if [ -s "$PLUG_VIM" ]; then
        echo "Note: couldn't refresh vim-plug (network?); keeping the existing copy."
    else
        fail_step
    fi
fi

# === 5. oh-my-zsh submodule + symlink

step
if [ ! -d "$REPO_DIR/.oh-my-zsh/.git" ]; then
    git submodule update --init --recursive .oh-my-zsh 2>/dev/null || \
    git submodule add https://github.com/ohmyzsh/ohmyzsh.git .oh-my-zsh 2>/dev/null || true
fi
# .oh-my-zsh is excluded from stow (NTFS-perm conflicts on WSL); symlink manually.
if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
fi
ln -sfn "$REPO_DIR/.oh-my-zsh" "$HOME/.oh-my-zsh" || fail_step

# === 6. Stow dotfiles

step
# Remove stray symlinks in $HOME that point into ANY checkout of this repo —
# the current one, or an older one (e.g. a /mnt/c/Users/<user>/mydot_files
# checkout from before the repo moved into WSL). Stow treats these as "not
# owned by stow" and aborts the whole run, so clear them first. readlink -f
# resolves relative link targets (../../mnt/c/...) so the match works either
# way. Only symlinks are removed — never real files.
while IFS= read -r link; do
    target="$(readlink -f "$link" 2>/dev/null)"
    case "$target" in
        */mydot_files/*|*/mydot_files)
            echo "Removing stale symlink: $link"; rm -f "$link" ;;
    esac
done < <(find "$HOME" -maxdepth 3 \
            -path "$REPO_DIR" -prune -o \
            -path "$HOME/.oh-my-zsh" -prune -o \
            -type l -print 2>/dev/null)

# Back up any REAL file (not symlink) that collides with a stowed file, so
# stow can't abort on it and nothing is lost. Deleting rc files earlier (old
# behaviour) left the shell unconfigured whenever a later step failed.
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
for f in .zshrc .bashrc .bash_aliases .vimrc utils.sh .config/nvim/init.vim; do
    if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$f")"
        echo "Backing up existing ~/$f to $BACKUP_DIR/$f"
        mv "$HOME/$f" "$BACKUP_DIR/$f"
    fi
done

# No --adopt: it silently moves $HOME files INTO the repo, overwriting
# committed content. Conflicts are handled above; anything left is a real
# problem that must stop the run rather than scroll past.
if ! stow --target="$HOME" --restow .; then
    echo "ERROR: stow failed — dotfiles were NOT linked into \$HOME." >&2
    echo "       Resolve the conflicts above and re-run ./setup.sh." >&2
    exit 1
fi

# === 7. zsh plugins

step
# Plugins go into the repo's own custom dir ($ZSH_CUSTOM in .zshrc), not the
# oh-my-zsh submodule's custom/, so the submodule never gets dirty. The dir is
# gitignored (third-party clones, not ours).
mkdir -p "$REPO_DIR/oh-my-zsh-custom/plugins"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    [ -d "$REPO_DIR/oh-my-zsh-custom/plugins/$plugin" ] || \
        git clone "https://github.com/zsh-users/$plugin" \
            "$REPO_DIR/oh-my-zsh-custom/plugins/$plugin" || fail_step
done
# Clean up artifacts the old approach left inside the submodule (plugin clones
# and copied themes made `git status` report the submodule as dirty). Only
# remove themes that exist in our repo's custom dir — the submodule ships its
# own tracked example.zsh-theme which must stay.
rm -rf "$REPO_DIR/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
       "$REPO_DIR/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
for theme in "$REPO_DIR/oh-my-zsh-custom/themes/"*.zsh-theme; do
    [ -e "$theme" ] && rm -f "$REPO_DIR/.oh-my-zsh/custom/themes/$(basename "$theme")"
done

# === 8. nvim plugins

step
# PlugClean! also prunes plugin dirs left behind by removed Plug lines.
nvim --headless +PlugInstall +PlugClean! +qall 2>/dev/null || {
    echo "Warning: nvim PlugInstall had issues but continuing"
    fail_step
}

# === 9. Switch default shell to zsh (best-effort; needs no sudo)

step
# chsh can fail when zsh isn't in /etc/shells (common when zsh comes from pixi)
# or when PAM rejects the change. The stowed .bashrc already does `exec zsh -l`,
# so a failure here is non-fatal — zsh will still launch in new terminals.
if chsh -s "$(which zsh)" 2>/dev/null; then
    echo "Default login shell switched to zsh."
else
    echo "Note: 'chsh' couldn't change the login shell (likely zsh isn't in"
    echo "      /etc/shells, which would need admin rights to add). No worries —"
    echo "      .bashrc runs 'exec zsh -l' on interactive shells, so opening a"
    echo "      new terminal will still drop you into zsh."
fi

# === Done

if step_complete; then
    echo "Please restart your terminal."
else
    echo "Fix the failed steps above and re-run ./setup.sh (safe to re-run)."
    exit 1
fi

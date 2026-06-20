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

step_complete() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  Setup Complete!"
  echo "════════════════════════════════════════════════════════════════"
  for s in "${STEPS[@]}"; do
    printf "  \033[0;32m[✓]\033[0m %s\n" "$s"
  done
  echo "════════════════════════════════════════════════════════════════"
  echo ""
}

# === 1. Install Pixi + base packages

step
curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"
pixi global install tmux yarn git nvim zsh python-lsp-server stow tree fzf diskus xclip

# === 2. Clean conflicting configs

step
if [ -f ~/.config/nvim/init.vim ] && [ -f ~/.config/nvim/init.lua ]; then
    echo "Removing conflicting init.vim (keeping init.lua)"
    rm ~/.config/nvim/init.vim
fi
rm -f ~/.zshrc ~/.bashrc 2>/dev/null || true

# === 3. nvm + Node LTS

step
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# === 4. vim-plug

step
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

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
ln -sfn "$REPO_DIR/.oh-my-zsh" "$HOME/.oh-my-zsh"

# === 6. Stow dotfiles

step
# Remove stray symlinks in $HOME that point back into this repo but were NOT
# created by stow (older `ln -s` installs used absolute targets). Stow treats
# these as "not owned by stow" and aborts the whole run, so clear them first.
# Only symlinks are removed — never real files.
while IFS= read -r link; do
    target="$(readlink "$link")"
    case "$target" in
        "$REPO_DIR"/*) echo "Removing stale symlink: $link"; rm -f "$link" ;;
    esac
done < <(find "$HOME" -maxdepth 3 \
            -path "$REPO_DIR" -prune -o \
            -path "$HOME/.oh-my-zsh" -prune -o \
            -type l -print 2>/dev/null)

stow --target="$HOME" --restow . --adopt

# === 7. zsh plugins

step
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true

# === 8. nvim plugins

step
nvim --headless +PlugInstall +qall 2>/dev/null || \
    echo "Warning: nvim PlugInstall had issues but continuing"

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

step_complete

mkdir -p "$HOME/.oh-my-zsh/custom/themes"
cp -f "oh-my-zsh-custom/themes/"*.zsh-theme "$HOME/.oh-my-zsh/custom/themes/"

# # AI autocomplete advisory: minuet-ai.nvim is installed via the new Plug lines
# # in init.vim, but it needs $MINUET_MODEL to match a model your local server
# # actually serves. Defaults to YOUR_MODEL_NAME (a placeholder) in .zshrc/.bashrc.
# if curl -fsS -m 1 http://localhost:8000/v1/models >/dev/null 2>&1; then
#     MODELS="$(curl -fsS -m 1 http://localhost:8000/v1/models 2>/dev/null \
#               | python3 -c 'import json,sys; [print(m["id"]) for m in json.load(sys.stdin).get("data", [])]' 2>/dev/null)"
#     if [ -n "$MODELS" ]; then
#         echo "Detected local OpenAI-compatible server on :8000. Served model(s):"
#         echo "$MODELS" | sed 's/^/    /'
#         echo "To use one for nvim AI autocomplete, set in your shell:"
#         echo "    export MINUET_MODEL=<id-from-above>"
#     fi
# else
#     echo "Note: nvim AI autocomplete (minuet-ai.nvim) expects an OpenAI-compatible"
#     echo "      server on http://localhost:8000. None detected right now — that's"
#     echo "      fine; start one later and set MINUET_MODEL to your served model id."
# fi

echo "Please restart your terminal."

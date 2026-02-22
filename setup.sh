# Change to the repo directory so all relative paths work
cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

# === pixi
curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"
pixi global install tmux yarn git nvim zsh python-lsp-server stow tree fzf diskus

# === Clean up conflicting config files BEFORE installing plugins
if [ -f ~/.config/nvim/init.vim ] && [ -f ~/.config/nvim/init.lua ]; then
    echo "Removing conflicting init.vim (keeping init.lua)"
    rm ~/.config/nvim/init.vim
fi

# === Remove existing zsh/bash configs so stow can symlink them
rm -f ~/.zshrc ~/.bashrc 2>/dev/null || true

# === nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# === Install vim-plug (before stow, for nvim)
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# === Oh-my-zsh as git submodule
if [ ! -d "$REPO_DIR/.oh-my-zsh/.git" ]; then
    git submodule update --init --recursive .oh-my-zsh 2>/dev/null || \
    git submodule add https://github.com/ohmyzsh/ohmyzsh.git .oh-my-zsh 2>/dev/null || true
fi

# Symlink .oh-my-zsh manually (excluded from stow to avoid conflicts with NTFS perms)
# Remove if it's a plain directory (not a symlink) so we can link properly
if [ -d "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
fi
ln -sfn "$REPO_DIR/.oh-my-zsh" "$HOME/.oh-my-zsh"

# === Apply stow to create symlinks for dotfiles
stow --target="$HOME" . --adopt

# === Install zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true

# === Install nvim plugins (after stow, so config is linked)
nvim --headless +PlugInstall +qall 2>/dev/null || {
    echo "Warning: nvim PlugInstall had issues but continuing"
}

# == Go to zsh
chsh -s $(which zsh)

# === Final message
echo "Setup complete! Please restart your terminal."

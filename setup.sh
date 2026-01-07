# First copy current bashrc as backup abd cioy the things

# cp ~/.bashrc ~/.bashrc_bak
#mkdir -p ~/.config/nvim
#cp -r .config/nvim/* ~/.config/nvim/.

# === pixi
curl -fsSL https://pixi.sh/install.sh | bash
#pixi install
. ~/.bashrc
pixi global install tmux yarn git nvim zsh python-lsp-server stow

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

# === Pre-create zshrc to avoid interactive prompts
touch ~/.zshrc

# === Oh-my-zsh (skip - user should install separately if needed)
# Note: oh-my-zsh installation requires the actual user to own the home directory
# Run separately as the target user:
#   RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "Note: Run oh-my-zsh setup as the actual user (maulik) if needed"

# === Apply stow to create symlinks for dotfiles (this links nvim config)
stow . --adopt

# === Install nvim plugins (after stow, so config is linked)
nvim --headless +PlugInstall +qall 2>/dev/null || {
    echo "Warning: nvim PlugInstall had issues but continuing"
}

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

# === Install nvim plugins
if [ -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
    nvim --headless +PlugInstall +qall
else
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  nvim --headless +PlugInstall +qall
fi

# === Pre-create zshrc to avoid interactive prompts
touch ~/.zshrc

# === Oh-my-zsh (non-interactive mode, skip if already installed)
if [ ! -d ~/.oh-my-zsh ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        echo "Warning: Oh-my-zsh installation failed. Continuing anyway."
    }
fi

# === Apply stow to create symlinks for dotfiles
stow . --adopt

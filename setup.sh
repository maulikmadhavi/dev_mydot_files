# First copy current bashrc as backup abd cioy the things

# cp ~/.bashrc ~/.bashrc_bak
#mkdir -p ~/.config/nvim
#cp -r .config/nvim/* ~/.config/nvim/.

# === pixi
curl -fsSL https://pixi.sh/install.sh | bash
#pixi install
. ~/.bashrc
pixi global install tmux yarn git nvim zsh python-lsp-server stow

# === nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
if [ -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
    nvim --headless +PlugInstall +qall
else
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  nvim --headless +PlugInstall +qall
fi

# === Handle conflicting nvim configs - keep only one
if [ -f ~/.config/nvim/init.vim ] && [ -f ~/.config/nvim/init.lua ]; then
    echo "Warning: Both init.vim and init.lua exist. Keeping init.lua (modern nvim)"
    rm ~/.config/nvim/init.vim
fi

# === Pre-create zshrc to avoid interactive prompts
touch ~/.zshrc

# === Oh-my-zsh (non-interactive mode, skip if already installed)
if [ ! -d ~/.oh-my-zsh ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
fi

# === Apply stow to create symlinks for dotfiles
stow .

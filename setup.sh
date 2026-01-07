# First copy current bashrc as backup abd cioy the things

# cp ~/.bashrc ~/.bashrc_bak
#mkdir -p ~/.config/nvim
#cp -r .config/nvim/* ~/.config/nvim/.

# === pixi
curl -fsSL https://pixi.sh/install.sh | bash
#pixi install
source ~/.bashrc
pixi global install tmux yarn git nvim zsh python-lsp-server stow

# === nvim
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
source ~/.bashrc  # or ~/.zshrc, depending on your shell
nvm install --lts
if [ -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
    nvim --headless +PlugInstall +qall
else
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  nvim --headless +PlugInstall +qall
fi



# ===  Oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#cp .zshrc ~/.zshrc
# cp .zshrc.pre-oh-my-zsh ~/.

stow .
zsh

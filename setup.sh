# First copy current bashrc as backup

cp ~/.bashrc ~/.bashrc_bak

cp -r * ~/.

sh pixi_deps.sh

sh .config/nvim/deps.sh

nvim --headless +PlugInstall +qall

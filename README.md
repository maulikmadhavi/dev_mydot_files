# Introduction
This project is the collection of my dot files. These can be used to sync up the bash environment across multiple systems.

## Pixi
we leverage pixi to install several binary utils, namely, nvim, tmux, python, conda, pip, etc.
```bash
curl -fsSL https://pixi.sh/install.sh | zsh

#pixi install
pixi global install tmux yarn python=3.10 git nvim conda 
```

## Secrets
`secret.sh` is not the part of the project, which preserves the secret environment varibles.

# zsh setup
```bash
# Download and extract
wget http://www.zsh.org/pub/zsh-5.9.tar.xz
tar -xzf zsh-5.9.tar.xz
rm zsh-5.9.tar.xz
cd zsh-5.9

# install to $HOME/local -- change it to suit your case
mkdir ~/local
# check install directory
./configure --prefix=$HOME/local
make
# all tests should pass or skip
make check
make install
```

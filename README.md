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


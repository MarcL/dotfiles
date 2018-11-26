# Dotfiles

Forked from [@craigkj](https://github.com/craigkj) who forked from [@holman](https:/github.com/holman).

## Install

Clone the repo

```bash
git clone git@github.com:MarcL/dotfiles.git .dotfiles
```

### Install XCode command line tools

```bash
xcode-select --install
```

### Install Brew

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Install dotfiles

```bash
cd .dotfiles
script/bootstrap
script/install
chsh -s /usr/local/bin/zsh
```

### Local secrets

To add environment variables which need to be private, add them to the file `~/.localrc`. They will automatically be picked up by [zshrc.symlink](/zsh/zshrc.symlink). This will allow private secrets to be added but to avoid putting them in version control.

## Additional installs

[Fira Code font](https://github.com/tonsky/FiraCode)

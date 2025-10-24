# FZF - Fuzzy Finder

[repo](https://github.com/junegunn/fzf)

FZF does not really require a config file.
Although, I find it a very useful tool to have.
I will be adding installation instructions therefore.

## Installation

### Package manager

Although not preferred since usually this is outdated,
you can install it through your package manager

#### Ubuntu

```sh
sudo apt install fzf
```

#### Arch

```sh
sudo pacman -S fzf
```

### Git

Alternatively it can be installed using git.

```sh
git clone --depth 1 https://github.com/junegunn/fzf.git ~/src/.fzf
~/src/.fzf/install
```

## Shell integration

Finally to achieve the full power,
make sure the following line is added to the `.zshrc`

```sh
source <(fzf --zsh)
```

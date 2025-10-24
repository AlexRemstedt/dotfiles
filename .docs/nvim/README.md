# NeoVim

## Installation

Preferred installation is through [bob](https://github.com/MordechaiHadad/bob)

### Install w/ bob

Install bob using `cargo`

```
cargo install bob-nvim
bob install nightly
bob use nightly
nvim -V1 --version
```

### Build from source

[Prerequisites](https://github.com/neovim/neovim/blob/master/BUILD.md#build-prerequisites):

```sh
sudo apt-get install ninja-build gettext cmake curl build-essential
```

[Installation](https://github.com/neovim/neovim/blob/master/BUILD.md#quick-start):

```sh
git clone https://github.com/neovim/neovim $HOME/src/neovim
cd $HOME/src/neovim
git checkout stable
make CMAKE_BUILD_TYPE=RelWithDebInfo -sss
sudo make install -sss
```

Upgrade

```sh
cd $HOME/src/neovim
git pull
make clean -sss
make CMAKE_BUILD_TYPE=RelWithDebInfo -sss
sudo make install -sss
```

[Uninstall](https://github.com/neovim/neovim/blob/master/INSTALL.md#uninstall):

```sh
sudo rm /usr/local/bin/nvim
sudo rm -r /usr/local/share/nvim/
```

## Configuration

At the moment I use [LazyVim](https://www.lazyvim.org/) for customization.

Prerequisites for LazyVim are:

* NeoVim (>= 0.9.0)
* Git (>= 2.19.0)
* A nerdfont
* [lazygit](https://github.com/jesseduffield/lazygit)
* A C compiler [for treesitter](https://github.com/nvim-treesitter/nvim-treesitter#requirements)
* cURL
* fzf-lua
  * [fzf](https://github.com/junegunn/fzf)
  * [ripgrep](https://github.com/BurntSushi/ripgrep)
  * [find files (fd)](https://github.com/sharkdp/fd)

The config files can be accessed by invoking:

```sh
stow -S nvim
```

### Fresh config

If you want to start a fresh config, look [here](https://www.lazyvim.org/installation)

tldr;

```sh
git clone https://github.com/LazyVim/starter ~dotfiles/nvim/.config/nvim
rm -rf ~/.config/nvim/.git
nvim
```

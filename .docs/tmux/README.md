# Tmux

## Installation

install tmux using

```sh
sudo apt install tmux
```

## Configuration

Use stow:

```
stow -S tmux
```

For plugins I use TPM:

```sh
git clone https://github.com/tmux-plugins/tpm ~/dotfiles/tmux/.tmux/plugins/tpm
```

### Resurrect

One of the most useful plugins I use is resurrect. This helps maintain tmux configs.

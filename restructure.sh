#!/bin/bash

# Move nvim
if [ -d "nvim/.config/nvim" ]; then
    mkdir -p private_dot_config
    mv nvim/.config/nvim private_dot_config/
fi

# Move tmux files
[ -f "tmux/.tmux.conf" ] && mv tmux/.tmux.conf dot_tmux.conf
[ -f "tmux/.tmux-cht-command" ] && mv tmux/.tmux-cht-command dot_tmux-cht-command
[ -f "tmux/.tmux-cht-languages" ] && mv tmux/.tmux-cht-languages dot_tmux-cht-languages

# Move zsh
[ -f "zsh/.zshrc" ] && mv zsh/.zshrc dot_zshrc

# Check for fish config
if [ -d "fish/.config/fish" ]; then
    mkdir -p private_dot_config
    mv fish/.config/fish private_dot_config/
fi

echo "Restructuring complete!"

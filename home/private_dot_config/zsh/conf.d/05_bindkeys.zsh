# Use emacs key bindings
bindkey -e

# Home and End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# History beginning search
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^[[A' history-beginning-search-backward-end
bindkey '^[[B' history-beginning-search-forward-end

# History substring search
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

bindkey -s '^f' "tmux-sessionizer\n"

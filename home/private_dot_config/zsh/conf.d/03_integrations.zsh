eval "$(sheldon source)"

autoload -Uz compinit
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
compinit -Cd "${XDG_CACHE_HOME}/zsh/zcompdump"

(( $+commands[chezmoi] )) && eval "$(chezmoi completion zsh)"

(( $+commands[fzf] )) && source <(fzf --zsh)

(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

(( $+commands[tldr] )) && eval "$(tldr --print-completion zsh)"

(( $+commands[gh] )) && eval "$(gh completion -s zsh)"

(( $+commands[git-flow] )) && eval "$(git-flow completion zsh)"

# lazygit: if you change the repo inside lazygit, the shell follows.
# lazygit writes the new path to LAZYGIT_NEW_DIR_FILE on exit.
if (( $+commands[lazygit] )); then
  lg() {
    export LAZYGIT_NEW_DIR_FILE="${XDG_CACHE_HOME:-${HOME}/.cache}/lazygit/newdir"
    mkdir -p "${LAZYGIT_NEW_DIR_FILE:h}"

    lazygit "$@"

    if [[ -f "$LAZYGIT_NEW_DIR_FILE" ]]; then
      cd "$(cat "$LAZYGIT_NEW_DIR_FILE")"
      rm -f "$LAZYGIT_NEW_DIR_FILE" > /dev/null
    fi
  }
fi

# Node
if (( $+commands[fnm] )); then
  [[ -d "/run/user/${UID}" ]] || export XDG_RUNTIME_DIR="/tmp/runtime-${UID}"
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi
(( ! $+commands[node] && $+commands[fnm] )) && fnm install latest

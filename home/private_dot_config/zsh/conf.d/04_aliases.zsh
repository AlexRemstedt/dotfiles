(( $+commands[bat] )) && alias cat="bat -pp"

if (( $+commands[eza] )); then
  alias ls="eza"
  alias ll="ls -lh"
  alias l="ls -al"
  alias la="ls -a"
  alias lla="ls -alh"
  alias tree="ls --tree"
fi

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias reload='source ${ZDOTDIR}/.zshrc'

alias nvim-update='update_neovim_plugins.sh'

# tmux aliases
function _build_tmux_alias {
  setopt localoptions no_rc_expand_param
  eval "function $1 {
    if [[ -z \$1 ]] || [[ \${1:0:1} == '-' ]]; then
      tmux $2 \"\$@\"
    else
      tmux $2 $3 \"\$@\"
    fi
  }"

  local f s
  f="_omz_tmux_alias_${1}"
  s=(${(z)2})

  eval "function ${f}() {
    shift words;
    words=(tmux ${@:2} \$words);
    ((CURRENT+=${#s[@]}+1))
    _tmux
  }"

  compdef "$f" "$1"
}

alias tksv='tmux kill-server'
alias tl='tmux list-sessions'
alias tmuxconf='$EDITOR $ZSH_TMUX_CONFIG'

_build_tmux_alias "ta" "attach" "-t"
_build_tmux_alias "tad" "attach -d" "-t"
_build_tmux_alias "ts" "new-session" "-s"
_build_tmux_alias "tkss" "kill-session" "-t"

unfunction _build_tmux_alias

# git aliases
source ~/.config/zsh/aliases/git.zsh
source ~/.config/zsh/aliases/python.zsh

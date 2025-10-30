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

alias nvu='update_neovim_plugins.sh'


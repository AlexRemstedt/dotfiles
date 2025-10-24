# Editor settings
if  ((  $+commands[nvim] )); then
  export EDITOR="nvim"
else
  export EDITOR="vim"
fi
export VISUAL="${EDITOR}"
export GIT_EDITOR="${EDITOR}"

# History / App configs
export CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME}/claude"
export LESSHISTFILE=-
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
export RUFF_CACHE_DIR="${XDG_CACHE_HOME}/ruff"
export STARSHIP_CACHE="${XDG_CACHE_HOME}/starship"


# Bob
export BOB_HOME="${XDG_DATA_HOME}/bob"
path+=("${BOB_HOME}/nvim-bin")

# Nvim
export NVIM_CONFIG_HOME="${XDG_CONFIG_HOME}/nvim"

# Cargo
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
path+=("${CARGO_HOME}/bin")

# Poetry 
export POETRY_HOME="$HOME/.local/share/pypoetry"
path+=("${POETRY_HOME}/bin")

# Fnm
export FNM_HOME="${XDG_DATA_HOME}/fnm"
path+=("${FNM_HOME}/bin")

# User executables
path+=("${XDG_BIN_HOME}")

export TERM="xterm-256color"
export COLORTERM="truecolor"

# Resolve the checkout even when ~/.zshenv is a symlink and the clone was renamed.
export ZDOTDIR="${${(%):-%N}:A:h}"
export XDG_CONFIG_HOME="${ZDOTDIR:h}"
typeset -U path
path=("$HOME/.local/bin" $path)

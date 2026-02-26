# Path to your Oh My Zsh installation
export ZSH="$ZDOTDIR/ohmyzsh"

ZSH_THEME="franke"

# Better behavior
setopt NO_NOMATCH
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt NO_CASE_GLOB
setopt PROMPT_SP

unsetopt share_history
setopt inc_append_history
setopt hist_ignore_dups

# Better completion behavior
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
KEYTIMEOUT=1

# Plugins (added useful ones)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)

source $ZSH/oh-my-zsh.sh
unset LS_COLORS

#------------------------------
# Aliases
#-----------------------------
alias ls='eza --icons --group-directories-first --git --header --time-style "+%Y/%m/%d %H:%M"'
alias ll='ls -l'
alias la='ls -la'

alias ezaconfig="micro $XDG_CONFIG_HOME/eza/theme.yml"
alias reload="source $XDG_CONFIG_HOME/zsh/.zshrc"
alias hyprconfig="micro $XDG_CONFIG_HOME/hypr/hyprland.conf"

# ---------------------------
# Better completion styling
# ---------------------------

autoload -Uz compinit
compinit

zmodload zsh/complist

zstyle ':completion:*' menu select=1
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*'

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' format '%F{blue}%B-- %d --%b%f'
zstyle ':completion:*' verbose yes
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' select-prompt '%F{yellow}Scrolling active: %p lines%f'

zstyle ':completion:*:*:cd:*' tag-order \
  local-directories \
  directory-stack \
  path-directories

bindkey -M menuselect '\e' abort
bindkey -M menuselect '\e' send-break
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# ---------------------------
# Smart symbol replacements
# ---------------------------

# --- Smart symbol substitutions (-> → etc.) ---
# Save original self-insert
zle -A self-insert _orig_self_insert

smart-symbols() {
  # first insert the typed character normally
  zle _orig_self_insert

  # then rewrite patterns at the end of the left buffer
  case "$LBUFFER" in
    *"->") LBUFFER="${LBUFFER%->}→" ;;
    *"<-") LBUFFER="${LBUFFER%<-}←" ;;
    *">=") LBUFFER="${LBUFFER%>=}≥" ;;
    *"<=") LBUFFER="${LBUFFER%<=}≤" ;;
    *"!=") LBUFFER="${LBUFFER%!=}≠" ;;
    *"=>") LBUFFER="${LBUFFER%=>}⇒" ;;
  esac
}

# Replace the default self-insert with our wrapper (no bindkey needed)
zle -N self-insert smart-symbols

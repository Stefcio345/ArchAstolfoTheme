# Path to your Oh My Zsh installation
export ZSH="$ZDOTDIR/ohmyzsh"
export LLMS_SERVER="https://llmsserver.jukis.pl"


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
COMPLETION_WAITING_DOTS="true"
KEYTIMEOUT=1
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(normal-word-right)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(normal-right) 
ZSH_AUTOSUGGEST_STRATEGY+=(history completion) 
WORDCHARS=$(echo "$WORDCHARS" | tr -d '/')

# Plugins (added useful ones)
plugins=(
  git
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
unset LS_COLORS

#------------------------------
# Aliases
#-----------------------------
alias ls='eza --icons --group-directories-first --git --header --time-style "+%Y/%m/%d %H:%M"'
alias ll='ls -l'
alias la='ls -la'
alias top='clear; top'

alias ezaconfig="micro $XDG_CONFIG_HOME/eza/theme.yml"
alias reload="source $XDG_CONFIG_HOME/zsh/.zshrc"
alias hyprconfig="micro $XDG_CONFIG_HOME/hypr/hyprland.conf"

# ---------------------------
# Better completion styling
# ---------------------------

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
# Standard text editor keybinds
# ---------------------------

bindkey -e   # emacs keymap

# Region highlight style
zle_highlight=(region:bg=242)

# Extend by character
extend-left() {
  [[ $REGION_ACTIVE -eq 0 ]] && zle set-mark-command
  zle backward-char
}
extend-right() {
  [[ $REGION_ACTIVE -eq 0 ]] && zle set-mark-command
  zle forward-char
}

# Extend by word
extend-word-left() {
  [[ $REGION_ACTIVE -eq 0 ]] && zle set-mark-command
  zle backward-word
}
extend-word-right() {
  [[ $REGION_ACTIVE -eq 0 ]] && zle set-mark-command
  zle forward-word
}

zle -N extend-left
zle -N extend-right
zle -N extend-word-left
zle -N extend-word-right

# Shift + Arrow
bindkey '^[[1;2D' extend-left
bindkey '^[[1;2C' extend-right

# Ctrl + Shift + Arrow
bindkey '^[[1;6D' extend-word-left
bindkey '^[[1;6C' extend-word-right


# Stop selection before normal movement
normal-left() {
  zle deactivate-region
  zle backward-char
}

# Right arrow: stop selecting, then let autosuggestions handle it
normal-right() {
  zle deactivate-region
  zle forward-char
}

normal-word-left() {
  zle deactivate-region
  zle backward-word
}

normal-word-right() {
  zle deactivate-region
  zle forward-word
}

zle -N normal-left
zle -N normal-right
zle -N normal-word-left
zle -N normal-word-right

# Arrow keys
bindkey '^[[D' normal-left
bindkey '^[[C' normal-right
bindkey '^[OD'  normal-left
bindkey '^[OC'  normal-right

# Ctrl + Arrow
bindkey '^[[1;5D' normal-word-left
bindkey '^[[1;5C' normal-word-right

bindkey '^H' backward-kill-word

# ---------------------------
# SELECT and DELETE ALL
# ---------------------------

select-all() {
  zle beginning-of-line
  zle set-mark-command
  zle end-of-line
}
zle -N select-all
bindkey '^A' select-all

backward-delete-or-region() {
  if (( REGION_ACTIVE && CURSOR != MARK )); then
    zle kill-region
  else
    zle backward-delete-char
  fi
}
zle -N backward-delete-or-region
bindkey '^?' backward-delete-or-region   # Backspace

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

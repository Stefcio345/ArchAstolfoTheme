# Path to your Oh My Zsh installation
export ZSH="$ZDOTDIR/ohmyzsh"

ZSH_THEME="franke"

# Better completion behavior
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Plugins (added useful ones)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

#------------------------------
# Aliases
#-----------------------------
alias ls='eza --icons --group-directories-first --git --header --time-style "+%Y/%m/%d %H:%M"'
alias ll='ls -l'
alias la='ls -la'

alias ezaconfig="micro $XDG_CONFIG_HOME/eza/theme.yml"
alias reload="source $XDG_CONFIG_HOME/zsh/.zshrc"

# ---------------------------
# Better completion styling
# ---------------------------

# Modern completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

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

# Kitty shell integration


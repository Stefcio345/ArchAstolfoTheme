# -----------------------------
# VOID GRAY + ASTOLFO ACCENT ZSH
# -----------------------------

autoload -U colors && colors
setopt prompt_subst
setopt transient_rprompt

# Palette (matches your kitty/waybar vibe)
BG_DARK="%F{#1a1b1f}"      # main background tone (used as "dark" text color here)
GRAY_MAIN="%F{#e4e4e7}"    # primary text
GRAY_SOFT="%F{#cfcfd4}"    # secondary text
GRAY_MUTED="%F{#9a9aa3}"   # dim text (FIXED: you used this but didn't define it)
SURFACE="%F{#3a3a40}"      # muted surface / separators
PINK="%F{#f38ba8}"         # Astolfo accent
PINK_SOFT="%F{#ffb3c6}"    # hover/bright accent
RESET="%f"

# Git branch
git_prompt_info() {
  command git rev-parse --is-inside-work-tree &>/dev/null || return
  local branch
  branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) || return
  echo " ${SURFACE} ${GRAY_SOFT}${branch}${RESET}"
}

# Exit status indicator (shows if last command failed)
exit_status() {
  [[ $? -ne 0 ]] && echo " ${PINK}✖${RESET}"
}

# Run fastfetch with a random image logo (only in interactive shells)
run_fastfetch_random_logo() {
  [[ -o interactive ]] || return

  # Don't run inside VS Code integrated terminal
  [[ "$TERM_PROGRAM" == "vscode" ]] && return

  $XDG_CONFIG_HOME/scripts/CuteMessage.sh

  local dir="$HOME/Pictures/ZshLogos"

  # pick once per shell session
  if [[ -z "$FASTFETCH_LOGO" ]]; then
    local -a imgs
    imgs=("$dir"/*.(png|jpg|jpeg|webp)(N))

    if (( ${#imgs} > 0 )); then
      FASTFETCH_LOGO="${imgs[RANDOM % ${#imgs} + 1]}"
    fi
  fi

  if [[ -n "$FASTFETCH_LOGO" ]]; then
    fastfetch --logo "$FASTFETCH_LOGO" --logo-type kitty
  else
    fastfetch
  fi
}

###########################################
############# COLORS ######################
###########################################

ZSH_HIGHLIGHT_STYLES[default]="fg=#e4e4e7"

ZSH_HIGHLIGHT_STYLES[alias]="fg=#f38ba8, bold"
ZSH_HIGHLIGHT_STYLES[command]="fg=#f38ba8, bold"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#f38ba8, bold"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=#ee91ab, bold"

ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#f56767"

ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=#ff9fc2,bold"
ZSH_HIGHLIGHT_STYLES[suffix-alias]="fg=#b8b8bf"
ZSH_HIGHLIGHT_STYLES[global-alias]="fg=#ff9fc2"
ZSH_HIGHLIGHT_STYLES[function]="fg=#ff77aa"
ZSH_HIGHLIGHT_STYLES[commandseparator]="fg=#b8b8bf,bold"
ZSH_HIGHLIGHT_STYLES[hashed-command]="fg=#cfcfd4"

ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#8bf392"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]="fg=#d6f38b"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#8bf392"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]="fg=#d6f38b"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#8bf392"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]="fg=#d6f38b"

run_fastfetch_random_logo

TRAPWINCH() {
    [[ "$TERM_PROGRAM" == "vscode" ]] && return

    printf '\e[H\e[J'
    run_fastfetch_random_logo
    printf '\n'
    [[ -o zle ]] && zle reset-prompt
}

# Prompt
PROMPT="%{$GRAY_SOFT%}%n%{$GRAY_MUTED%}@%{$GRAY_SOFT%}%m %{$GRAY_MUTED%}%~%{$RESET%}\$(git_prompt_info)\$(exit_status)%{$RESET%}
%{$PINK%}❯ %{$RESET%}"

RPROMPT="${GRAY_MUTED}%*${RESET}"

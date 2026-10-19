# -----------------------------
# VOID GRAY + ASTOLFO ACCENT ZSH
# -----------------------------

autoload -U colors && colors
setopt prompt_subst
# Keep each command's timestamp in the scrollback.
unsetopt transient_rprompt

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
  command git rev-parse --is-inside-work-tree &>/dev/null || return 0
  local branch
  branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) || return 0
  echo " ${SURFACE} ${GRAY_SOFT}${branch}${RESET}"
}

# Run fastfetch with a random image logo (only in interactive shells)
run_fastfetch_random_logo() {
  [[ -o interactive ]] || return

  # Don't run inside VS Code integrated terminal
  [[ "$TERM_PROGRAM" == "vscode" ]] && return

  # Quarter-screen terminals need their rows for the image and system text.
  # The large greeting/footer otherwise scroll the top of the image out of view.
  local compact=0
  local start_row=0
  (( ${LINES:-40} < 28 )) && compact=1
  printf '\e[H\e[2J'
  if (( ! compact )); then
    "${XDG_CONFIG_HOME:-$HOME/.config}/scripts/CuteMessage.sh"
    print ''
    start_row=2
  fi

  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/astolfo-goth/logos"

  # pick once per shell session
  if [[ -z "$FASTFETCH_LOGO" ]]; then
    local -a imgs
    imgs=("$dir"/*.(png|jpg|jpeg|webp)(N))

    if (( ${#imgs} > 0 )); then
      FASTFETCH_LOGO="${imgs[RANDOM % ${#imgs} + 1]}"
    fi
  fi

  if [[ -n "$FASTFETCH_LOGO" ]]; then
    local logo_to_display="$FASTFETCH_LOGO"
    local frame_script="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/astolfo-goth/frame_logo.py"
    if [[ -f "$frame_script" ]]; then
      local framed
      framed="$(python3 "$frame_script" "$FASTFETCH_LOGO")"
      [[ -n "$framed" && -f "$framed" ]] && logo_to_display="$framed"
    fi
    if [[ -f "$frame_script" ]]; then
      # Keep Fastfetch's parent as zsh so its shell/version detection stays true.
      local panel_info=''
      (( COLUMNS >= 68 )) && panel_info="$(fastfetch --logo none --pipe false)"
      python3 "$frame_script" --panel "$logo_to_display" "$start_row" "$panel_info"
    else
      fastfetch --logo none
    fi
  else
    fastfetch
  fi

  # One quiet line finishes the panel without consuming a second image block.
  local deco='───  ♡  ♱  ♡  ───'
  local pad=$(( (COLUMNS - ${(m)#deco}) / 2 ))
  (( pad < 0 )) && pad=0
  printf '%*s' "$pad" ''
  print -P "%F{#9e6b82}${deco}%f"
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

typeset -g ASTOLFO_WELCOME_PRISTINE=1
astolfo_command_started() { typeset -g ASTOLFO_WELCOME_PRISTINE=0; }
autoload -Uz add-zsh-hook
add-zsh-hook preexec astolfo_command_started

run_fastfetch_random_logo

TRAPWINCH() {
    [[ "${TERM_PROGRAM:-}" == "vscode" || "${ASTOLFO_WELCOME_PRISTINE:-0}" != 1 \
       || "${ASTOLFO_WELCOME_DRAWING:-0}" == 1 ]] && return 0
    # Reflow only the untouched welcome screen, never a command's output.
    if zle >/dev/null 2>&1; then
      typeset -g ASTOLFO_WELCOME_DRAWING=1
      zle -I
      # Do not invoke a redisplay widget here: that consumes the invalidation
      # and remembers the old cursor anchor before the panel is drawn.
      run_fastfetch_random_logo
      zle -R
      typeset -g ASTOLFO_WELCOME_DRAWING=0
    fi
    return 0
}

# Prompt
# Native status expansion reports the last command, not the Git lookup above.
PROMPT=$'%F{#6e5265}╭─%f %F{#cfcfd4}%n %F{#d8b1c0}%3~%f$(git_prompt_info)%(?.. %F{#f38ba8}✕ %?%f)\n%F{#6e5265}╰─%F{#f38ba8}❯%f '
RPROMPT='%F{#6e5265}♡ %F{#9a9aa3}%D{%H:%M}%f'

# Refresh while the editor still owns the command line, just before submission.
# This records run time rather than the time the prompt first appeared.
astolfo_command_timestamp() {
  [[ -n "${BUFFER//[[:space:]]/}" ]] || return 0
  zle reset-prompt
  zle -R
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-finish astolfo_command_timestamp

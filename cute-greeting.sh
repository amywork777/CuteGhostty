#!/usr/bin/env bash
# Cute Ghostty launch greeting.
# Opt in by adding this to ~/.zshrc (or ~/.bashrc):
#   source /absolute/path/to/cute-greeting.sh
# Prints only for interactive shells. Works in both bash and zsh.

_cute_greeting() {
  case $- in *i*) ;; *) return 0 ;; esac

  local pink=$'\033[38;2;255;111;163m'
  local dim=$'\033[38;2;176;127;208m'
  local reset=$'\033[0m'

  # Positional params are 1-based in both bash and zsh.
  set -- \
    "your terminal is feeling extra cute today ♡" \
    "pastel dreams loaded ₊✩‧₊˚" \
    "go make something adorable ੨੎" \
    "you + this terminal = iconic ✧" \
    "stay cute, code cuter ⋆˚"
  local n=$(( ${RANDOM:-0} % $# + 1 ))
  local msg
  eval "msg=\${$n}"

  printf '%s' "$pink"
  cat <<'GHOST'
       .-~~~-.
      /       \
     |  o   o  |
     |    w    |
     |         |
      \^v^v^v^/
GHOST
  printf '%s%s%s\n' "$dim" "$msg" "$reset"
  printf '%s%s%s\n' "$dim" "₊✩‧₊˚ ੨੎ ˚₊✩‧₊" "$reset"
}

_cute_greeting
unset -f _cute_greeting 2>/dev/null || true

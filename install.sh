#!/usr/bin/env bash
# Install Cute Ghostty onto stock Ghostty.
#   ./install.sh            # add an include line to your config (least destructive)
#   ./install.sh --replace  # make the cute config your main config (backs up existing)
#   ./install.sh --uninstall
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CFG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
CFG="$CFG_HOME/config"
THEMES="$CFG_HOME/themes"
INCLUDE_LINE="config-file = $SRC/cute-ghostty.config"
GREETING_LINE="source $SRC/cute-greeting.sh"

uninstall() {
  if [ -f "$CFG" ]; then
    sed -i.bak "\#$INCLUDE_LINE#d" "$CFG"
    echo "  Removed include from $CFG (backup: $CFG.bak)"
  fi
  if [ -d "$THEMES" ]; then
    for t in "$SRC"/themes/*; do rm -f "$THEMES/$(basename "$t")"; done
    echo "  Removed Cute Ghostty themes from $THEMES"
  fi
  echo "♡ Uninstalled. (Your own config and any backups are untouched.)"
}

if [ "${1:-}" = "--uninstall" ]; then uninstall; exit 0; fi

mkdir -p "$THEMES"
echo "  Installing themes → $THEMES"
cp "$SRC"/themes/* "$THEMES"/

if [ "${1:-}" = "--replace" ]; then
  if [ -f "$CFG" ]; then
    bak="$CFG.bak-$(date +%s)"; cp "$CFG" "$bak"; echo "  Backed up existing config → $bak"
  fi
  cp "$SRC/cute-ghostty.config" "$CFG"
  echo "  Wrote cute config → $CFG"
else
  mkdir -p "$CFG_HOME"; touch "$CFG"
  if grep -qF "$INCLUDE_LINE" "$CFG"; then
    echo "  Include already present in $CFG"
  else
    printf '\n# Cute Ghostty\n%s\n' "$INCLUDE_LINE" >> "$CFG"
    echo "  Added include → $CFG"
  fi
fi

echo ""
echo "  ♡ Cute Ghostty installed. Restart Ghostty (or reload config)."
echo "  Optional cute launch greeting — add to your ~/.zshrc:"
echo "      $GREETING_LINE"

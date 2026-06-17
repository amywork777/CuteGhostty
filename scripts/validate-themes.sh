#!/usr/bin/env bash
# Validate every theme file has palette 0..15 + required keys.
set -euo pipefail
dir="${1:-themes}"
fail=0
for f in "$dir"/*; do
  [ -f "$f" ] || continue
  for i in $(seq 0 15); do
    grep -qE "^palette = $i=#[0-9A-Fa-f]{6}$" "$f" || { echo "FAIL $f: missing palette $i"; fail=1; }
  done
  for key in background foreground cursor-color selection-background; do
    grep -qE "^$key = " "$f" || { echo "FAIL $f: missing $key"; fail=1; }
  done
done
[ "$fail" = 0 ] && echo "OK: all themes in '$dir' valid"
exit "$fail"

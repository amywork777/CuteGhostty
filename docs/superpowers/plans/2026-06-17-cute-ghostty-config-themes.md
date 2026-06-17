# Cute Ghostty config + themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Cute Ghostty as a drop-in config + pastel theme family for stock Ghostty (with an optional build-your-own `.app`), making the cute icon, themes, and messages real, and closing issues #2/#3/#5/#6.

**Architecture:** Cute Ghostty becomes config + theme files installed onto the real upstream Ghostty binary. A safe `install.sh` lays down the config, theme family, and optional launch greeting. `build.sh` is reworked to produce a minimally-modified `.app` (icon + name only) from the user's current Ghostty. README + site are rewritten to present both paths.

**Tech Stack:** Ghostty config format, POSIX/bash shell scripts, static HTML/CSS site.

**Environment notes:** `ghostty` CLI not installed → no `ghostty +validate-config`; validate theme/config files structurally. `shellcheck` not installed → use `bash -n` for syntax. `create-dmg` is installed. A `CuteGhostty.app` exists in `/Applications` (not stock Ghostty), so `build.sh` cannot be end-to-end run here.

**Spec:** `docs/superpowers/specs/2026-06-17-cute-ghostty-config-themes-design.md`

---

### Task 0: Branch + scaffolding

**Files:**
- Create dir: `themes/`
- Create: `scripts/validate-themes.sh` (dev-only validator)

- [ ] **Step 1: Create a feature branch**

```bash
cd /Users/amy/code/CuteGhostty
git checkout -b cute-config-themes
```

- [ ] **Step 2: Create the themes directory and a theme validator**

Create `scripts/validate-themes.sh`:

```bash
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
```

- [ ] **Step 3: Verify the validator runs (no themes yet → trivially OK)**

Run: `bash -n scripts/validate-themes.sh && chmod +x scripts/validate-themes.sh && ./scripts/validate-themes.sh themes`
Expected: `OK: all themes in 'themes' valid` (empty dir passes)

- [ ] **Step 4: Commit**

```bash
git add scripts/validate-themes.sh
git commit -m "chore: add theme validator and themes scaffold"
```

---

### Task 1: Cute theme family

**Files:**
- Create: `themes/Cute Pink`, `themes/Cute Lavender`, `themes/Cute Mint`, `themes/Cute Peach`, `themes/Cute Lemon`, `themes/Cute Sky` (light family)
- Create: `themes/Cute Pastel Dreams`, `themes/Cute Midnight Pink`, `themes/Cute Midnight Lavender`, `themes/Cute Midnight Mint` (dark family)

**Shared light accent ramp** (palette 0–15; readable on light pastel backgrounds):
```
0=#6B4A5C 1=#D6447E 2=#3FA98A 3=#C2872E 4=#5E84CC 5=#9B5FC0 6=#3C97A4 7=#C9A8B8
8=#9B8290 9=#FF6FA3 10=#5FB89A 11=#D89E3E 12=#6E94DC 13=#B07FD0 14=#4CA7B4 15=#5C4150
```

**Shared dark accent ramp** (website-matched pastels; readable on dark backgrounds):
```
0=#3A2A47 1=#FF85B8 2=#A8E6CF 3=#FFF3B0 4=#B8D4F0 5=#C8A2F0 6=#6DD5A8 7=#F5EEF8
8=#7A6690 9=#FFB2D9 10=#D4F5E4 11=#FFD4A8 12=#B8D4F0 13=#E8D5FF 14=#A8E6CF 15=#FFFFFF
```

**Per-theme background / foreground / cursor-color / cursor-text / selection-background / selection-foreground:**

Light family (use the light ramp for palette 0–15):
| Theme | background | foreground | cursor-color | cursor-text | selection-background | selection-foreground |
|---|---|---|---|---|---|---|
| Cute Pink | #FFF0F6 | #6B4A5C | #FF6FA3 | #FFF0F6 | #FBD5E6 | #6B4A5C |
| Cute Lavender | #F4EEFF | #534A66 | #9B5FC0 | #F4EEFF | #E3D6F7 | #534A66 |
| Cute Mint | #ECFBF4 | #3E5B50 | #3FA98A | #ECFBF4 | #CFEEDF | #3E5B50 |
| Cute Peach | #FFF4EA | #6B5340 | #E0894B | #FFF4EA | #FCE0C8 | #6B5340 |
| Cute Lemon | #FFFCEC | #5F5A36 | #C7A12E | #FFFCEC | #F4ECC2 | #5F5A36 |
| Cute Sky | #EEF6FF | #41506B | #5E84CC | #EEF6FF | #D4E4F7 | #41506B |

Dark family (use the dark ramp for palette 0–15):
| Theme | background | foreground | cursor-color | cursor-text | selection-background | selection-foreground |
|---|---|---|---|---|---|---|
| Cute Pastel Dreams | #1C1025 | #F5EEF8 | #FFB2D9 | #1C1025 | #3A2A47 | #F5EEF8 |
| Cute Midnight Pink | #241320 | #FCEAF3 | #FFB2D9 | #241320 | #43293A | #FCEAF3 |
| Cute Midnight Lavender | #1E1830 | #ECE6FA | #C8A2F0 | #1E1830 | #382E52 | #ECE6FA |
| Cute Midnight Mint | #10211B | #E2F6EC | #A8E6CF | #10211B | #233F34 | #E2F6EC |

- [ ] **Step 1: Write each theme file** in the format below (example shown for `Cute Pink`; every theme follows this layout, substituting the ramp + row values above):

```
palette = 0=#6B4A5C
palette = 1=#D6447E
palette = 2=#3FA98A
palette = 3=#C2872E
palette = 4=#5E84CC
palette = 5=#9B5FC0
palette = 6=#3C97A4
palette = 7=#C9A8B8
palette = 8=#9B8290
palette = 9=#FF6FA3
palette = 10=#5FB89A
palette = 11=#D89E3E
palette = 12=#6E94DC
palette = 13=#B07FD0
palette = 14=#4CA7B4
palette = 15=#5C4150
background = #FFF0F6
foreground = #6B4A5C
cursor-color = #FF6FA3
cursor-text = #FFF0F6
selection-background = #FBD5E6
selection-foreground = #6B4A5C
```

- [ ] **Step 2: Validate all theme files**

Run: `./scripts/validate-themes.sh themes`
Expected: `OK: all themes in 'themes' valid`

- [ ] **Step 3: Commit**

```bash
git add themes
git commit -m "feat: add cute pastel theme family (light + dark)"
```

---

### Task 2: Cute config

**Files:**
- Create: `cute-ghostty.config`

- [ ] **Step 1: Write `cute-ghostty.config`**

```
# Cute Ghostty — drop-in config for stock Ghostty.
# Install with ./install.sh, or include from your own config:
#   config-file = /absolute/path/to/cute-ghostty.config

# Cute icon: original Ghostty ghost, aluminum frame, medium-pink screen.
macos-icon = custom-style
macos-icon-frame = aluminum
macos-icon-screen-color = #FF6FA3

# Pastel themes — auto-switch with the system appearance.
# Swap either side for any "Cute *" theme in ./themes.
theme = "light:Cute Pink,dark:Cute Pastel Dreams"

# Tasteful defaults (tweak freely).
cursor-style = block
mouse-hide-while-typing = true
```

- [ ] **Step 2: Structural check** (no `ghostty` CLI available)

Run: `grep -E '^(macos-icon|macos-icon-frame|macos-icon-screen-color|theme) ' cute-ghostty.config`
Expected: all four lines printed.

- [ ] **Step 3: Commit**

```bash
git add cute-ghostty.config
git commit -m "feat: add cute config (pink-screen icon + theme selection)"
```

---

### Task 3: Launch greeting

**Files:**
- Create: `cute-greeting.sh`

- [ ] **Step 1: Extract the ghost art** from `site/index.html` (the `<pre class="braille-ghost-art">` block, ~lines 1209–1226) for reuse, and write `cute-greeting.sh`:

```bash
#!/usr/bin/env bash
# Cute Ghostty launch greeting.
# Opt in by adding this to ~/.zshrc (or ~/.bashrc):
#   source /absolute/path/to/cute-greeting.sh
# Prints only for interactive shells.

case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

cute_pink=$'\033[38;2;255;111;163m'
cute_dim=$'\033[38;2;176;127;208m'
cute_reset=$'\033[0m'

cute_messages=(
  "your terminal is feeling extra cute today ♡"
  "pastel dreams loaded ₊✩‧₊˚"
  "go make something adorable ੨੎"
  "you + this terminal = iconic ✧"
  "stay cute, code cuter ⋆˚"
)
idx=$(( ${RANDOM:-0} % ${#cute_messages[@]} ))

printf '%s' "$cute_pink"
cat <<'GHOST'
        ⢀⣀⣤⣤⣤⣀⡀
     ⣠⣶⡿⠟⠛⠛⠛⠻⢿⣶⣄
    ⣰⡿⠋          ⠙⢿⣆
   ⣼⡟    ⣀⣀    ⣀⣀   ⢻⣧
   ⣿⡇   ⣿⣿⣿   ⣿⣿⣿   ⢸⣿
   ⣿⡇   ⠿⠿⠿   ⠿⠿⠿   ⢸⣿
   ⢿⣧                ⣼⡿
   ⠈⢿⣧⣄          ⣠⣴⡿⠁
     ⠙⠻⢷⣶⣦⣤⣤⣶⣶⡾⠟⠋
GHOST
printf '%b\n' "$cute_dim${cute_messages[$idx]}$cute_reset"
printf '%b\n' "$cute_dim₊✩‧₊˚ ੨੎ ˚₊✩‧₊$cute_reset"
```

- [ ] **Step 2: Syntax + behavior check**

Run: `bash -n cute-greeting.sh && bash -ic 'source ./cute-greeting.sh'`
Expected: ghost art + a cute message print without error.

- [ ] **Step 3: Commit**

```bash
git add cute-greeting.sh
git commit -m "feat: add opt-in cute launch greeting"
```

---

### Task 4: Installer

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Write `install.sh`**

```bash
#!/usr/bin/env bash
# Install Cute Ghostty onto stock Ghostty.
#   ./install.sh            # install (adds an include line; least destructive)
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
  [ -f "$CFG" ] && sed -i.bak "\#$INCLUDE_LINE#d" "$CFG" || true
  for t in "$SRC"/themes/*; do rm -f "$THEMES/$(basename "$t")"; done
  echo "♡ Removed Cute Ghostty include + themes. Your config backup: $CFG.bak"
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
```

- [ ] **Step 2: Syntax check**

Run: `bash -n install.sh`
Expected: no output (valid).

- [ ] **Step 3: Dry-run against a throwaway HOME (include mode)**

```bash
T=$(mktemp -d); HOME="$T" XDG_CONFIG_HOME="$T/.config" bash ./install.sh
grep -q "config-file = $(pwd)/cute-ghostty.config" "$T/.config/ghostty/config" && echo "INCLUDE OK"
ls "$T/.config/ghostty/themes" | grep -q "Cute Pink" && echo "THEMES OK"
```
Expected: `INCLUDE OK` and `THEMES OK`.

- [ ] **Step 4: Dry-run replace + uninstall**

```bash
T2=$(mktemp -d); HOME="$T2" XDG_CONFIG_HOME="$T2/.config" bash ./install.sh --replace
grep -q "macos-icon = custom-style" "$T2/.config/ghostty/config" && echo "REPLACE OK"
HOME="$T2" XDG_CONFIG_HOME="$T2/.config" bash ./install.sh --uninstall
[ -z "$(ls -A "$T2/.config/ghostty/themes" 2>/dev/null)" ] && echo "UNINSTALL OK"
```
Expected: `REPLACE OK` and `UNINSTALL OK`.

- [ ] **Step 5: Commit**

```bash
chmod +x install.sh
git add install.sh
git commit -m "feat: add safe installer/uninstaller for stock Ghostty"
```

---

### Task 5: Rework `build.sh` (app path)

**Files:**
- Modify: `build.sh`
- Modify: `assets/Info.plist` (keep stock `CFBundleIdentifier`)

- [ ] **Step 1: Edit `assets/Info.plist`** — change `CFBundleIdentifier` value back to `com.mitchellh.ghostty` (keep `CFBundleName`/display name = "Cute Ghostty" and the service strings). This removes the bundle-ID mismatch behind #3/#6.

- [ ] **Step 2: Edit `build.sh`** — make these changes:
  - Remove the `rm -rf .../PlugIns/DockTilePlugin.plugin` step (keep plugins → addresses #6).
  - After copying the app, run `install.sh` guidance: print a reminder that themes/greeting install via `./install.sh`.
  - Add a banner near the top warning to point it at the **latest** stock Ghostty:
    `echo "  Note: build from the CURRENT Ghostty (ghostty.org) so you get upstream perf/fixes."`
  - Keep icon swap, Info.plist swap, Assets.car swap, signing, DMG, notarization.

- [ ] **Step 3: Syntax check**

Run: `bash -n build.sh`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add build.sh assets/Info.plist
git commit -m "fix: app path keeps stock bundle id + plugins, builds from current Ghostty (#3,#5,#6)"
```

---

### Task 6: Retire the stale prebuilt app + DMG

**Files:**
- Delete (from git): `Cute Ghostty.app/`, `site/CuteGhostty.dmg`
- Modify: `.gitignore`

- [ ] **Step 1: Stop tracking the stale binary artifacts**

```bash
git rm -r --cached "Cute Ghostty.app" site/CuteGhostty.dmg
```

- [ ] **Step 2: Append to `.gitignore`**

```
Cute Ghostty.app/
site/CuteGhostty.dmg
*.dmg
```

- [ ] **Step 3: Verify they are no longer tracked**

Run: `git status --short | grep -E "Cute Ghostty.app|CuteGhostty.dmg"`
Expected: shows `D` (deleted from index) / no longer staged as tracked content.

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: stop shipping stale prebuilt app + DMG (root cause of #5/#6 for downloads)"
```

---

### Task 7: Rewrite README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite `README.md`** to: open with the two co-equal paths; add a "Themes" section listing the family + how to switch (`theme = "Cute Mint"`); document the icon config; document the opt-in greeting; document the app-path side-by-side caveat (stock bundle ID); update the "What's different" section (config + themes + icon, not a custom binary). Remove the v0.2 DMG as the primary download; link the config install + `build.sh`.

- [ ] **Step 2: Link check**

Run: `grep -nE "install.sh|cute-ghostty.config|themes/|build.sh|ghostty.org" README.md`
Expected: references present.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for config + themes (two co-equal paths)"
```

---

### Task 8: Update the website

**Files:**
- Modify: `site/index.html`

- [ ] **Step 1: Update the install section** to present both paths (config install + build-your-own), replacing the DMG-only steps. Keep the cute aesthetic.
- [ ] **Step 2: Fix the requirements badge** ("Apple Silicon (arm64)" → "Apple Silicon + Intel" to match README) and point the download CTA at the GitHub repo / install instructions instead of `CuteGhostty.dmg`.
- [ ] **Step 3: Add a small "Themes" showcase** strip listing the pastel theme names (optional, keep light).

- [ ] **Step 4: Render check**

Run: `python3 -c "import html.parser,sys; html.parser.HTMLParser().feed(open('site/index.html').read()); print('parsed ok')"`
Expected: `parsed ok`. (Then verify visually with the preview tools.)

- [ ] **Step 5: Commit**

```bash
git add site/index.html
git commit -m "docs(site): present both install paths; fix requirements + CTA"
```

---

### Task 9: Close the GitHub issues

**Files:** none (uses `gh`; requires `dangerouslyDisableSandbox: true` due to the TLS sandbox issue).

- [ ] **Step 1: Comment + close each issue** with the resolution from the spec's issue matrix, linking the new files. One `gh issue comment` + `gh issue close` per issue (#2, #3, #5, #6). Phrase #2 as "yes — it's now a config," #3/#5/#6 as resolved by the config path with the app-path notes.

- [ ] **Step 2: Verify**

Run: `gh issue list --repo amywork777/CuteGhostty --state open`
Expected: the four issues no longer listed (or only intentionally-open ones remain).

---

## Self-review

- **Spec coverage:** themes (T1), config/icon (T2), greeting (T3), installer/#3 (T4), build.sh/#5/#6 (T5), stale DMG/#5/#6 (T6), README (T7), site (T8), close issues/#2 (T9). All spec sections mapped.
- **Placeholder scan:** theme files use the explicit shared ramps + per-theme table (complete, not "similar to"); scripts have full bodies. README/site tasks describe edits to existing large files (content-level, follow existing patterns).
- **Consistency:** include line, greeting line, and theme names match across install.sh, cute-ghostty.config, and README.

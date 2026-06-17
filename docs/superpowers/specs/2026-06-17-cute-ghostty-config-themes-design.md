# Cute Ghostty — config + themes redesign

Date: 2026-06-17
Status: design / awaiting review

## Goal

Resolve all four open issues on `amywork777/CuteGhostty` by shipping Cute Ghostty
two co-equal ways — a **drop-in config + themes** for stock Ghostty, and an
**optional build-your-own `.app`** — and by making the "cute" parts (pastel
themes, the pink-screen icon, and the cute launch messages) actually real instead
of website-only.

## Root-cause analysis

`build.sh` takes a *stock* Ghostty.app, swaps the icon, swaps `Info.plist`
(changing the bundle ID to `com.amy.cute-ghostty`, name to "Cute Ghostty", version
pinned to `0.1`), deletes the DockTilePlugin, swaps `Assets.car`, and re-signs. It
never recompiles Ghostty, and it never applies any pastel theme or message — those
exist only in `site/index.html`.

All four issues trace back to shipping a **re-bundled binary**:

| # | Issue | Cause | Resolution |
|---|-------|-------|------------|
| 2 | "Can it just be a config file?" | — (the right question) | Drop-in config path delivers exactly this |
| 3 | CMD+comma opens stock Ghostty config | Ghostty hardcodes its config path (`~/.config/ghostty/config`), independent of bundle ID | Config path: you *are* editing the cute config at that path. App path: keep stock bundle ID so there is one config |
| 5 | Higher CPU on Intel | Shipped binary built from an old/different Ghostty than upstream 1.2.3 | Config path runs the real upstream binary. App path builds from the user's *current* Ghostty; we stop shipping a stale prebuilt binary |
| 6 | Memory leak (reopened) | Re-bundling under a changed bundle ID + plugin tampering on a binary not meant to be re-bundled | Config path runs the untouched upstream binary. App path keeps the stock bundle ID and plugins (icon/name only) |

## Approach: two co-equal paths

Neither is "the core product." Both are first-class and documented side by side.

1. **Drop-in config** — install stock Ghostty (`brew install --cask ghostty` or
   ghostty.org), then run our `install.sh` to add the cute config, themes, icon
   settings, and (optionally) the launch greeting. This is the path that fully
   dodges #3/#5/#6 because it runs the real binary.
2. **Build-your-own `.app`** — `build.sh` takes the user's *current* stock
   Ghostty.app and produces a "Cute Ghostty.app" with the pink-screen icon baked
   in. Minimal tampering (see below).

## Components

### A. Cute theme family (`themes/`)

Ghostty theme files use a flat format; one file per theme, no extension, dropped in
`~/.config/ghostty/themes/<Name>` and selected with `theme = "<Name>"`:

```
palette = 0=#hex
... palette = 15=#hex
background = #hex
foreground = #hex
cursor-color = #hex
cursor-text = #hex
selection-background = #hex
selection-foreground = #hex
```

We ship a **family** keyed on background hue, drawn from the website brand palette
(`--pink #FFB2D9`, `--lavender #C8A2F0`, `--mint #A8E6CF`, `--peach #FFD4A8`,
`--yellow #FFF3B0`, `--blue-soft #B8D4F0`, dark base `#1C1025`). The website and
terminal will finally match.

Light family (pastel backgrounds):
`Cute Pink` `#FFF0F6` · `Cute Lavender` `#F4EEFF` · `Cute Mint` `#ECFBF4` ·
`Cute Peach` `#FFF4EA` · `Cute Lemon` `#FFFCEC` · `Cute Sky` `#EEF6FF`

Dark family:
`Cute Pastel Dreams` `#1C1025` (default dark) · `Cute Midnight Pink` `#241320` ·
`Cute Midnight Lavender` `#1E1830` · `Cute Midnight Mint` `#10211B`

Recipe: a shared **light** accent ramp (saturated-but-soft, readable on light
pastel bg) and a shared **dark** accent ramp (bright website pastels). Per theme we
vary background, foreground, cursor, and selection tints to suit the hue; the
16-color accent ramp stays consistent within each family so the themes are a
cohesive set, not 12 unrelated palettes.

Two flagship palettes specified in full (rest authored from the recipe during
implementation):

`Cute Pastel Dreams` (dark, website-matched):
```
palette 0=#3A2A47 1=#FF85B8 2=#A8E6CF 3=#FFF3B0 4=#B8D4F0 5=#C8A2F0 6=#6DD5A8 7=#F5EEF8
palette 8=#7A6690 9=#FFB2D9 10=#D4F5E4 11=#FFD4A8 12=#B8D4F0 13=#E8D5FF 14=#A8E6CF 15=#FFFFFF
background=#1C1025 foreground=#F5EEF8 cursor-color=#FFB2D9 cursor-text=#1C1025
selection-background=#3A2A47 selection-foreground=#F5EEF8
```

`Cute Pink` (light, default light — features the medium pink `#FF6FA3`):
```
palette 0=#6B4A5C 1=#D6447E 2=#3FA98A 3=#C2872E 4=#5E84CC 5=#9B5FC0 6=#3C97A4 7=#C9A8B8
palette 8=#9B8290 9=#FF6FA3 10=#5FB89A 11=#D89E3E 12=#6E94DC 13=#B07FD0 14=#4CA7B4 15=#6B4A5C
background=#FFF0F6 foreground=#6B4A5C cursor-color=#FF6FA3 cursor-text=#FFF0F6
selection-background=#FBD5E6 selection-foreground=#6B4A5C
```

### B. Cute config (`cute-ghostty.config`)

The file users install or include. Contains:

```
# Cute icon: original Ghostty ghost + aluminum frame, pink screen only
macos-icon = custom-style
macos-icon-frame = aluminum
macos-icon-screen-color = #FF6FA3

# Auto-switch by system appearance
theme = "light:Cute Pink,dark:Cute Pastel Dreams"

# Tasteful touches
cursor-style = block
# (background-opacity etc. left to user taste, documented but not forced)
```

The icon is **fully config-driven** and identical in both paths (aluminum is a real
material; the default ghost is kept). `macos-icon-*` cannot live in a theme file
([ghostty#3215]), which is why the icon ships in the config, not a theme.

### C. `install.sh`

Safe, idempotent installer for the config path:
- Detects `~/.config/ghostty/` (XDG) as the config home.
- Copies the theme family into `~/.config/ghostty/themes/`.
- Backs up any existing `~/.config/ghostty/config` to `config.bak-<n>`, then either
  writes the cute config or appends `config-file = <repo>/cute-ghostty.config`
  (prompted choice; default = include, least destructive).
- Prints how to opt into the launch greeting (component D).
- `./install.sh --uninstall` reverses it (restores backup, removes our themes).

Because the cute config becomes the user's Ghostty config at the standard path,
**CMD+comma / Settings opens it** — resolving #3.

### D. Launch greeting (`cute-greeting.sh`)

The "cute messages." They are not in the app bundle today (verified: the bundle is
stock Ghostty `themes/` + `shell-integration/` + `doc/` plus a renamed
`Info.plist`); they live only in `site/index.html`. We lift them into a shippable
script:
- The pink ghost braille art (from `site/index.html` lines ~1054–1071), printed in
  the theme's ANSI pink.
- A random cute message per new shell, e.g. "your terminal is feeling extra cute
  today ♡", "pastel dreams loaded ₊✩‧₊˚", "go make something adorable ୨ৎ".
- A sparkle divider line `₊✩‧₊˚ ୨ৎ ˚₊✩‧₊`.

Opt-in: prints only for interactive shells; user adds one line
(`source <repo>/cute-greeting.sh`) to `~/.zshrc`. `install.sh` offers to add it.

### E. `build.sh` fixes (app path)

- Build from the user's **current** stock Ghostty (the binary stays upstream's
  latest) — fixes the staleness behind #5. Stop committing a prebuilt
  `Cute Ghostty.app` and stop shipping a stale DMG (see F).
- **Keep the stock bundle identifier** (`com.mitchellh.ghostty`) and **keep the
  DockTilePlugin** — change only the display name and icon. This removes the
  bundle-ID mismatch + plugin tampering implicated in #6, and means the app reads
  the same `~/.config/ghostty/config` (consistent with the config path, #3).
  Documented caveat: with the stock bundle ID you should not run both stock Ghostty
  and Cute Ghostty.app side by side.
- Bake the pink-screen icon into the bundle so the dock tile is pink even before
  the config loads; remind the user to run `install.sh` for themes + greeting.

### F. Stale release / DMG

The `v0.2` DMG ships an old binary (the literal cause of #5/#6 for download users).
Plan: remove the committed `Cute Ghostty.app` and `site/CuteGhostty.dmg` from the
repo, add them to `.gitignore`, and point downloads at the config install + the
`build.sh` instructions. **Notarizing a fresh DMG cannot be done in this
environment** (no Ghostty source build + signing identity); `build.sh` is wired
correctly and the actual re-release/notarization is a documented step Amy runs
locally.

### G. README + site

- `README.md`: lead with the two co-equal paths; document the theme family, icon
  config, greeting, and the side-by-side caveat. Drop "separate app / custom bundle
  identity" framing.
- `site/index.html`: update install section to present both paths; keep the
  existing cute aesthetic; make the terminal preview use the real shipped palette
  (it already nearly does). Fix the stale "Apple Silicon only" requirement and the
  direct-DMG download CTA.

### H. Close the issues

Comment on and close #2, #3, #5, #6, each explaining the resolution and linking the
new files (config, themes, `install.sh`, `build.sh`).

## Repo structure after

```
cute-ghostty.config        # the cute config (icon + theme selection + touches)
themes/                    # Cute Pink, Cute Pastel Dreams, … (Ghostty format)
install.sh                 # safe installer / uninstaller for stock Ghostty
cute-greeting.sh           # opt-in launch greeting (ghost + cute messages)
build.sh                   # optional: build Cute Ghostty.app from current Ghostty
assets/                    # icon source, dmg background, Info.plist (name only)
site/                      # website (updated)
README.md                  # updated
```

## Caveats / honesty

- DMG notarization and any leak/CPU *verification* require a local macOS build +
  signing identity; out of scope for this environment and documented for Amy.
- `macos-icon = custom-style` occasionally needs a macOS icon-cache nudge
  ([ghostty#11029]); the app path bakes the icon to sidestep it.
- Light pastel themes trade some pastel softness for text contrast; the dark family
  is the showcase.

## Out of scope (YAGNI)

- Cute shell prompt and neofetch banner (offered, not selected).
- CI/CD for builds; auto-update channel changes.
- Per-hue *distinct* accent ramps (themes share a family ramp by design).

[ghostty#3215]: https://github.com/ghostty-org/ghostty/issues/3215
[ghostty#11029]: https://github.com/ghostty-org/ghostty/discussions/11029

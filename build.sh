#!/bin/bash
# Build Cute Ghostty from a stock Ghostty.app
#
# Usage:
#   ./build.sh /path/to/Ghostty.app
#
# This takes a stock Ghostty.app and applies the Cute Ghostty customizations:
#   - Replaces the app icon with the cute kawaii icon
#   - Updates the bundle identity to com.amy.cute-ghostty
#   - Sets the display name to "Cute Ghostty"
#   - Preserves upstream version metadata and updates bundle branding
#   - Code signs with Developer ID (or ad-hoc if unavailable)
#   - Creates a styled DMG with Applications shortcut
#   - Notarizes the DMG (if credentials are configured)
#
# Environment variables:
#   CODESIGN_IDENTITY  - Signing identity (default: auto-detect "Developer ID Application")
#   APPLE_ID           - Apple ID email for notarization
#   TEAM_ID            - Apple Developer Team ID for notarization
#   AC_PASSWORD        - App-specific password keychain label (default: "AC_PASSWORD")
#   SKIP_NOTARIZE      - Set to 1 to skip notarization
#   SKIP_DMG           - Set to 1 to skip DMG creation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

if [ $# -lt 1 ]; then
    echo "Usage: $0 /path/to/Ghostty.app"
    echo ""
    echo "Download Ghostty from https://ghostty.org and pass the .app path."
    exit 1
fi

SOURCE_APP="$1"

if [ ! -d "$SOURCE_APP" ]; then
    echo "Error: '$SOURCE_APP' not found or is not a directory."
    exit 1
fi

if [ ! -f "$SOURCE_APP/Contents/MacOS/ghostty" ]; then
    echo "Error: '$SOURCE_APP' doesn't look like a Ghostty app bundle."
    exit 1
fi

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: building the app requires macOS. Use ./install.sh for the config-only option."
    exit 1
fi

if [ "${SKIP_DMG:-}" != "1" ] && ! command -v create-dmg &>/dev/null; then
    echo "Error: create-dmg not found. Install with: brew install create-dmg"
    echo "Or build only the app with: SKIP_DMG=1 ./build.sh /path/to/Ghostty.app"
    exit 1
fi

OUTPUT_APP="$SCRIPT_DIR/Cute Ghostty.app"
DMG_PATH="$SCRIPT_DIR/site/CuteGhostty.dmg"

if [ "$(cd "$SOURCE_APP" && pwd -P)" = "$OUTPUT_APP" ]; then
    echo "Error: the source app cannot be the build output. Pass a stock Ghostty.app."
    exit 1
fi

echo "♡ Building Cute Ghostty..."
echo ""

# 1. Copy the stock Ghostty app
echo "  Copying Ghostty app bundle..."
rm -rf "$OUTPUT_APP"
cp -R "$SOURCE_APP" "$OUTPUT_APP"

# 2. Replace the icon
echo "  Applying cute icon..."
cp "$ASSETS_DIR/Ghostty.icns" "$OUTPUT_APP/Contents/Resources/Ghostty.icns"

# 3. Update bundle branding
echo "  Updating bundle identity..."
PLIST="$OUTPUT_APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.amy.cute-ghostty "$PLIST"
plutil -replace CFBundleDisplayName -string 'Cute Ghostty' "$PLIST"
plutil -replace CFBundleName -string 'Cute Ghostty' "$PLIST"
plutil -replace CFBundleIconFile -string Ghostty "$PLIST"
plutil -replace CFBundleIconName -string Ghostty "$PLIST"
plutil -replace SUEnableAutomaticChecks -bool NO "$PLIST"
if plutil -extract NSDockTilePlugIn raw -o - "$PLIST" >/dev/null 2>&1; then
    plutil -remove NSDockTilePlugIn "$PLIST"
fi

# 3b. Remove the Dock Tile plugin (causes memory leak under different bundle ID)
echo "  Removing Dock Tile plugin..."
rm -rf "$OUTPUT_APP/Contents/PlugIns/DockTilePlugin.plugin"

# 4. Update the Assets.car if we have a custom one
if [ -f "$ASSETS_DIR/Assets.car" ]; then
    echo "  Applying custom asset catalog..."
    cp "$ASSETS_DIR/Assets.car" "$OUTPUT_APP/Contents/Resources/Assets.car"
fi

# 5. Code sign the app
# Auto-detect Developer ID Application identity if not specified
if [ -z "${CODESIGN_IDENTITY:-}" ]; then
    DETECTED_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
    if [ -n "$DETECTED_IDENTITY" ]; then
        CODESIGN_IDENTITY="$DETECTED_IDENTITY"
    fi
fi

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    echo "  Signing with: $CODESIGN_IDENTITY"
    codesign --force --deep --sign "$CODESIGN_IDENTITY" --options runtime --entitlements "$ASSETS_DIR/Ghostty.entitlements" "$OUTPUT_APP"
else
    echo "  No Developer ID found — signing ad-hoc (DMG will not pass Gatekeeper)."
    echo "  To sign properly, install a Developer ID Application certificate and re-run."
    codesign --force --deep --sign - --options runtime --entitlements "$ASSETS_DIR/Ghostty.entitlements" "$OUTPUT_APP"
fi
codesign --verify --deep --strict "$OUTPUT_APP"

echo ""
echo "  ✩ Cute Ghostty.app is ready."
echo ""

# 6. Create styled DMG
if [ "${SKIP_DMG:-}" = "1" ]; then
    echo "  Skipping DMG creation (SKIP_DMG=1)."
else
    echo "  Creating styled DMG..."
    mkdir -p "$SCRIPT_DIR/site"
    rm -f "$DMG_PATH"

    create-dmg \
        --volname "Cute Ghostty" \
        --background "$ASSETS_DIR/dmg-background.png" \
        --window-pos 200 120 \
        --window-size 660 400 \
        --icon-size 128 \
        --icon "Cute Ghostty.app" 180 200 \
        --app-drop-link 480 200 \
        --no-internet-enable \
        "$DMG_PATH" \
        "$OUTPUT_APP"

    echo "  ✩ CuteGhostty.dmg created at site/CuteGhostty.dmg"
    echo ""

    # 7. Notarize the DMG
    if [ "${SKIP_NOTARIZE:-}" = "1" ]; then
        echo "  Skipping notarization (SKIP_NOTARIZE=1)."
    elif [ -z "${CODESIGN_IDENTITY:-}" ]; then
        echo "  Skipping notarization (no signing identity — ad-hoc builds can't be notarized)."
    elif [ -z "${APPLE_ID:-amzyst@gmail.com}" ] || [ -z "${TEAM_ID:-JUBFND4JUY}" ]; then
        echo "  Skipping notarization (set APPLE_ID and TEAM_ID env vars to enable)."
    else
        APPLE_ID="${APPLE_ID:-amzyst@gmail.com}"
        TEAM_ID="${TEAM_ID:-JUBFND4JUY}"
        AC_PASSWORD_LABEL="${AC_PASSWORD:-AC_PASSWORD}"
        echo "  Submitting DMG for notarization..."
        xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$AC_PASSWORD_LABEL" \
            --wait

        echo "  Stapling notarization ticket..."
        xcrun stapler staple "$DMG_PATH"
        echo "  ✩ DMG is notarized and stapled."
    fi
fi

echo ""
echo "  ♡ All done!"

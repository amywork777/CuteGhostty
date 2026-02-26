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
#   - Applies the custom Info.plist
#
# The output is "Cute Ghostty.app" in the current directory.

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

OUTPUT_APP="$SCRIPT_DIR/Cute Ghostty.app"

echo "♡ Building Cute Ghostty..."
echo ""

# 1. Copy the stock Ghostty app
echo "  Copying Ghostty app bundle..."
rm -rf "$OUTPUT_APP"
cp -R "$SOURCE_APP" "$OUTPUT_APP"

# 2. Replace the icon
echo "  Applying cute icon..."
cp "$ASSETS_DIR/Ghostty.icns" "$OUTPUT_APP/Contents/Resources/Ghostty.icns"

# 3. Replace Info.plist with our custom one
echo "  Updating bundle identity..."
cp "$ASSETS_DIR/Info.plist" "$OUTPUT_APP/Contents/Info.plist"

# 4. Update the Assets.car if we have a custom one
if [ -f "$ASSETS_DIR/Assets.car" ]; then
    echo "  Applying custom asset catalog..."
    cp "$ASSETS_DIR/Assets.car" "$OUTPUT_APP/Contents/Resources/Assets.car"
fi

# 5. Re-sign the app (ad-hoc signing so it runs locally)
echo "  Re-signing app (ad-hoc)..."
codesign --force --deep --sign - "$OUTPUT_APP" 2>/dev/null || {
    echo "  Warning: codesign failed. The app may trigger Gatekeeper."
    echo "  You can manually sign with: codesign --force --deep --sign - 'Cute Ghostty.app'"
}

echo ""
echo "  ✩ Done! Cute Ghostty.app is ready."
echo "  Run:  cp -R 'Cute Ghostty.app' /Applications/"
echo ""

# 6. Optionally create a zip for distribution
if [ "${ZIP:-}" = "1" ]; then
    echo "  Creating CuteGhostty.zip..."
    cd "$SCRIPT_DIR"
    zip -r -q CuteGhostty.zip "Cute Ghostty.app"
    echo "  ✩ CuteGhostty.zip created."
fi

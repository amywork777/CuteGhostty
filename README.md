# Cute Ghostty

<p align="center">
  <img src="assets/icon-512.png" alt="Cute Ghostty" width="200">
</p>

<p align="center">
  <strong>The same Ghostty you love, but cuter.</strong><br>
  Cute pastel colours, adorable emojis, kawaii icon &mdash; same blazing-fast terminal.
</p>

<p align="center">
  <a href="https://github.com/amywork777/CuteGhostty/releases/download/v0.2/CuteGhostty.dmg">Download</a> &bull;
  <a href="https://cute-ghostty.vercel.app">Website</a> &bull;
  <a href="https://ghostty.org">Ghostty</a>
</p>

---

## What is this?

Cute Ghostty is [Ghostty](https://ghostty.org) with a cute makeover. It's the exact same terminal emulator under the hood &mdash; same GPU-accelerated rendering, same native macOS UI, same features &mdash; just with cute pastel colours, a kawaii icon, and adorable aesthetic touches.

[Ghostty](https://github.com/ghostty-org/ghostty) is an incredible open-source terminal emulator created by Mitchell Hashimoto. We just made it cuter.

## Download

Grab the latest build: **[CuteGhostty.dmg](https://github.com/amywork777/CuteGhostty/releases/download/v0.2/CuteGhostty.dmg)**

1. Open the DMG and drag **Cute Ghostty.app** to your Applications folder
2. Launch and enjoy!

**Requirements:** macOS 13.0+ &bull; Universal binary (Apple Silicon + Intel)

## Build It Yourself

Want to build Cute Ghostty from a stock Ghostty install? The build script takes any Ghostty.app and applies the cute customizations:

```bash
git clone https://github.com/amywork777/CuteGhostty.git
cd CuteGhostty

# Pass your Ghostty.app path
./build.sh /Applications/Ghostty.app

# Install it
cp -R "Cute Ghostty.app" /Applications/
```

To also create a distributable zip:
```bash
ZIP=1 ./build.sh /Applications/Ghostty.app
```

## What's Different from Ghostty?

- Custom kawaii app icon (pink Hello Kitty-style ghost)
- Custom bundle identity (`com.amy.cute-ghostty`)
- Custom display name ("Cute Ghostty")
- Custom asset catalog with cute styling
- That's it! Everything else is pure Ghostty

## Repo Structure

```
build.sh                  # Build script - takes stock Ghostty and makes it cute
assets/
  Ghostty.icns            # The cute app icon (Apple icon format)
  Assets.car              # Compiled asset catalog with cute styling
  Info.plist              # Bundle configuration (ID, name, permissions)
  icon-512.png            # Icon preview at 512px
  icon-1024.png           # Icon preview at 1024px
Cute Ghostty.app/         # Pre-built app bundle (ready to use)
```

## Contributing

Contributions are welcome! Ideas:

- **New icon designs** &mdash; alternative cute icons for people to swap in
- **Colour themes** &mdash; cute Ghostty config themes (pastel, kawaii, cottagecore, etc.)
- **Build improvements** &mdash; CI/CD, notarization support, version bumping
- **Asset tooling** &mdash; scripts to generate Assets.car from source images

To customize the icon:
1. Edit `assets/Ghostty.icns` (use an icon editor or `iconutil`)
2. Run `./build.sh /Applications/Ghostty.app`
3. Test your new Cute Ghostty!

## Credits

- [Ghostty](https://ghostty.org) by Mitchell Hashimoto
- [Ghostty Source](https://github.com/ghostty-org/ghostty) &mdash; MIT Licensed

## License

Based on [Ghostty](https://github.com/ghostty-org/ghostty), licensed under the [MIT License](https://github.com/ghostty-org/ghostty/blob/main/LICENSE).

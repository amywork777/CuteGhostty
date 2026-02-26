# Cute Ghostty

<p align="center">
  <img src="app-resources/icon-512.png" alt="Cute Ghostty" width="200">
</p>

<p align="center">
  <strong>The same Ghostty you love, but cuter.</strong><br>
  Cute pastel colours, adorable emojis, kawaii icon &mdash; same blazing-fast terminal.
</p>

---

## What is this?

Cute Ghostty is [Ghostty](https://ghostty.org) with a cute makeover. It's the exact same terminal emulator under the hood &mdash; same GPU-accelerated rendering, same native macOS UI, same features &mdash; just with cute pastel colours, a kawaii icon, and adorable aesthetic touches.

[Ghostty](https://github.com/ghostty-org/ghostty) is an incredible open-source terminal emulator created by Mitchell Hashimoto.

## Download & Install

The app is right here in the repo. Clone it and you're done:

```bash
git clone https://github.com/amywork777/CuteGhostty.git
cp -R "CuteGhostty/Cute Ghostty.app" /Applications/
```

Or just download from [Releases](https://github.com/amywork777/CuteGhostty/releases) if you prefer a zip.

On first launch, right-click the app and select "Open" to bypass Gatekeeper.

### Requirements

- macOS 13.0 (Ventura) or later
- Universal binary (Apple Silicon + Intel)

## What's Different from Ghostty?

- Custom kawaii app icon (pink Hello Kitty-style ghost)
- Custom bundle identity (`com.amy.cute-ghostty`)
- Custom display name ("Cute Ghostty")
- That's it! Everything else is pure Ghostty

## Repo Structure

```
Cute Ghostty.app/         # The full app bundle - ready to run
  Contents/
    Info.plist            # Bundle config (com.amy.cute-ghostty)
    MacOS/ghostty         # Universal binary (arm64 + x86_64)
    Resources/
      Ghostty.icns        # Cute app icon
      Assets.car          # Compiled asset catalog
      *.nib               # Interface Builder files
      terminfo/           # Terminal info database
      vim/                # Vim syntax highlighting for ghostty config
      bash-completion/    # Shell completions
      zsh/, fish/         # More shell completions
      man/                # Man pages
    Frameworks/           # Embedded frameworks
    PlugIns/              # Dock tile plugin
    _CodeSignature/       # Code signing data
app-resources/            # Extracted assets for easy editing
  Ghostty.icns            # The cute icon (Apple icon format)
  icon-512.png            # Icon preview at 512px
  icon-1024.png           # Icon preview at 1024px
  Info.plist              # Bundle configuration
```

## Contributing

Contributions are welcome! Ideas:

- **New icon designs** &mdash; alternative cute icons people can swap in
- **Colour themes** &mdash; cute Ghostty config themes (pastel, kawaii, etc.)
- **Build scripts** &mdash; automate re-signing the app after icon swaps
- **Documentation** &mdash; guides for customizing Ghostty's look

Feel free to open an issue or PR.

## Credits

- [Ghostty](https://ghostty.org) by Mitchell Hashimoto
- [Ghostty Source](https://github.com/ghostty-org/ghostty) &mdash; MIT Licensed

## License

Based on [Ghostty](https://github.com/ghostty-org/ghostty), licensed under the [MIT License](https://github.com/ghostty-org/ghostty/blob/main/LICENSE).

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

## Download

Grab `CuteGhostty.zip` from this repo or from [Releases](https://github.com/amywork777/CuteGhostty/releases).

### Install

1. Download and unzip `CuteGhostty.zip`
2. Drag **Cute Ghostty.app** to your Applications folder
3. On first launch, right-click the app and select "Open" to bypass Gatekeeper

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
CuteGhostty.zip          # Ready-to-install app bundle (universal binary)
app-resources/
  Ghostty.icns            # Custom app icon (Apple icon format)
  icon-512.png            # Icon at 512px for previews
  icon-1024.png           # Icon at 1024px for previews
  Info.plist              # App bundle configuration (bundle ID, name, etc.)
```

### App Bundle Structure (inside the zip)

```
Cute Ghostty.app/
  Contents/
    Info.plist            # Bundle config: com.amy.cute-ghostty
    MacOS/
      ghostty             # Universal binary (arm64 + x86_64)
    Resources/
      Ghostty.icns        # Cute app icon
      Assets.car          # Compiled asset catalog
      *.nib               # Interface Builder files
      terminfo/           # Terminal info database
      vim/                # Vim syntax highlighting for ghostty config
      bash-completion/    # Shell completions
      zsh/                # Shell completions
      fish/               # Shell completions
      man/                # Man pages
    Frameworks/           # Embedded frameworks
    PlugIns/
      DockTilePlugin.plugin/  # Dock tile customization
    _CodeSignature/       # Code signing data
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

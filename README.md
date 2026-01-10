# Scramble

A privacy-focused image metadata removal tool for the Linux desktop.

![Scramble Application](data/screenshots/main-window.png)

## 🎉 Version 1.4.0 - Selective Metadata Removal

**Scramble 1.4.0** introduces selective metadata removal, giving you fine-grained control over which metadata categories to remove.

### 🆕 What's New in 1.4.0

- **🎯 Selective Removal**: Choose which metadata to remove: GPS, Camera, DateTime, Software, or Author info.
- **⚙️ Metadata Preferences**: New "Metadata Removal" section in Preferences with per-category toggles.
- **🎨 New Icons**: Fresh new application icons (Thanks to @oiimrosabel).
- **🔧 Development Icon**: Development builds now display the dedicated Devel icon.

For detailed release notes and version history, see [CHANGELOG.md](CHANGELOG.md).

## Features

### Core Features

- **📊 Metadata Inspection**: View detailed EXIF, IPTC, and XMP metadata with organized display.
- **🎯 Selective Removal**: Choose which metadata categories to remove or keep.
- **📦 Batch Processing**: Process multiple images at once with progress tracking.
- **🔍 Before/After Comparison**: Side-by-side comparison view to preview changes.
- **📤 Metadata Export**: Export metadata to JSON or CSV for analysis.

### User Experience

- **🖱️ Drag-and-Drop**: Simply drag images into the application.
- **⌨️ Keyboard Shortcuts**: Full keyboard navigation for all actions.
- **🎨 Modern UI**: Clean GTK4/LibAdwaita design following GNOME HIG.
- **📝 What's New Dialog**: Automatic release notes on version updates.

### Privacy & Security

- **🔒 Offline Operation**: No network access, no data collection.
- **🛡️ Sandboxed**: Runs in a secure Flatpak environment.
- **📁 Non-Destructive**: Original files are never modified.
- **🧹 Secure Memory**: Image data cleared from memory after processing.
- **🔍 Format Validation**: Magic number checking prevents malicious files.

### Format Support

| Input (Read & Clean) | Output (Save Clean) |
|---------------------|---------------------|
| JPEG, PNG, WebP | JPEG, PNG, WebP |
| TIFF, HEIF, HEIC | (converted to PNG) |

## Installation

### Flatpak (Recommended)

[![Get it on Flathub](https://flathub.org/api/badge)](https://flathub.org/en/apps/io.github.tobagin.scramble)

### From Source

```bash
# Install dependencies
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Build and install
./scripts/build.sh --dev
```

## Usage

### Basic Usage

1. **Open an image**: Drag & drop, click Open, or press `Ctrl+O`
2. **View metadata**: Inspect EXIF/IPTC/XMP data in the right panel
3. **Configure removal**: Open Preferences (`Ctrl+,`) → Metadata Removal
4. **Save clean copy**: Press `Ctrl+S` or click "Save Clean Copy"

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open image | `Ctrl+O` |
| Save clean copy | `Ctrl+S` |
| Compare before/after | `Ctrl+R` |
| Batch process | `Ctrl+B` |
| Export metadata | `Ctrl+E` |
| Clear image | `Ctrl+Shift+C` |
| Preferences | `Ctrl+,` |
| Quit | `Ctrl+Q` |

## Architecture

- **Language**: Vala with GTK4/LibAdwaita
- **UI Definition**: Blueprint markup language
- **Build System**: Meson with Flatpak packaging
- **Metadata Engine**: GExiv2 with BMFF support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test thoroughly with `./scripts/build.sh --dev`
4. Submit a pull request

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for details.

## Support

- **Bug Reports**: [GitHub Issues](https://github.com/tobagin/scramble/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/tobagin/scramble/discussions)

## Acknowledgments

- Built with [GTK4](https://www.gtk.org/) and [LibAdwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/)
- Metadata handling by [GExiv2](https://gitlab.gnome.org/GNOME/gexiv2)
- UI defined with [Blueprint](https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/)

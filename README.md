# Scramble

**Privacy-focused image metadata removal tool**

Scramble is a simple, privacy-focused utility for viewing and removing metadata from images. The application provides a clean, intuitive interface built with GTK4 and Libadwaita, featuring a user-friendly drag-and-drop workflow for metadata inspection and removal.

## Features

- **Metadata Inspection**: View detailed image metadata (EXIF, IPTC, XMP) in a clear, organized list
- **One-Click Removal**: Remove all metadata with a single click
- **Drag-and-Drop Interface**: Simply drag images into the application
- **Non-Destructive**: Original files are never modified
- **Privacy-First**: Completely offline operation with no data collection
- **Format Support**: JPEG and TIFF formats (Phase 1)

## Requirements

- GNOME 45+ runtime
- Python 3.12+
- GTK4 and Libadwaita
- Flatpak for packaging

## Building

### Development Build

For rapid development and testing:

```bash
./build.sh --dev --install --run
```

### Production Build

For release builds:

```bash
./build.sh --prod --clean
```

### Build Options

- `--dev`: Build for development (uses local source)
- `--prod`: Build for production (uses git source)
- `--install`: Install the application after building
- `--run`: Run the application after building/installing
- `--clean`: Clean build directory before building
- `--force-clean`: Force clean all Flatpak artifacts

## Installation

### From Source

1. Install dependencies:
   ```bash
   # On Fedora/RHEL
   sudo dnf install flatpak flatpak-builder

   # On Ubuntu/Debian
   sudo apt install flatpak flatpak-builder
   ```

2. Add Flathub repository:
   ```bash
   flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
   ```

3. Build and install:
   ```bash
   ./build.sh --dev --install
   ```

### From Flathub

*Coming soon - application will be available on Flathub after initial release*

## Usage

1. **Launch Scramble** from your application launcher or run:
   ```bash
   flatpak run io.github.tobagin.scramble
   ```

2. **Load an image** by dragging and dropping it into the application window

3. **View metadata** in the right panel - all extractable metadata will be displayed in organized categories

4. **Remove metadata** by clicking the "Save Clean Copy" button and choosing a save location

5. **Copy metadata values** by clicking the copy button next to any metadata entry

## Supported Formats

- **JPEG** (.jpg, .jpeg)
- **TIFF** (.tiff, .tif)

Additional formats (PNG, WebP, RAW) are planned for future releases.

## Privacy & Security

Scramble is designed with privacy as the top priority:

- **No Network Access**: Completely offline operation
- **No Data Collection**: Zero telemetry or analytics
- **Sandboxed**: Runs in a secure Flatpak environment
- **Non-Destructive**: Original files are never modified
- **Secure Memory**: Image data is properly cleaned from memory

## Architecture

The application follows a Model-View-Controller (MVC) pattern:

- **Model**: Pure Python business logic for metadata operations (`metadata.py`)
- **View**: Blueprint-defined UI components with LibAdwaita styling
- **Controller**: Python GTK classes connecting model and view (`window.py`)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

Please ensure your code follows PEP 8 standards and includes appropriate tests.

## License

This project is licensed under the GPL-3.0-or-later license. See the LICENSE file for details.

## Support

- **Bug Reports**: [GitHub Issues](https://github.com/tobagin/scramble/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/tobagin/scramble/discussions)
- **Documentation**: [Project Wiki](https://github.com/tobagin/scramble/wiki)

## Acknowledgments

- Built with [GTK4](https://www.gtk.org/) and [Libadwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/)
- Uses [Blueprint](https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/) for UI definition
- Metadata handling powered by [Pillow](https://python-pillow.org/) and [piexif](https://pypi.org/project/piexif/)
- Distributed via [Flatpak](https://flatpak.org/) for security and portability

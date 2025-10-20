# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Refactored project structure to align with Vala/GNOME conventions
- Renamed all Vala source files to PascalCase (matching their class names)
- Organized source code into logical subdirectories (`dialogs/`, `widgets/`, `core/`, `utils/`)
- Organized Blueprint UI files into subdirectories (`dialogs/`, `widgets/`)
- Moved build script to `scripts/build.sh`

## [1.2.0] - 2025-10-08

### Added
- HEIF/HEIC format support with metadata extraction
- Batch processing feature for multiple images
- Before/after comparison dialog view
- Metadata export functionality (JSON and CSV formats)
- Keyboard shortcuts window
- Support for WebP, TIFF image formats

### Fixed
- Critical 0-byte file save bug in Flatpak environment
- Shortcuts dialog implementation (now uses `Gtk.ShortcutsWindow`)
- TIFF/WebP save failures (automatic PNG conversion for unsupported formats)
- Batch processing crash caused by threading issues
- Output path validation and error handling

### Changed
- Improved file format detection and validation
- Enhanced metadata display with better organization
- Updated UI for better user experience

## [1.1.0] - (Earlier Release)

### Added
- Initial metadata viewing and removal functionality
- Support for JPEG and PNG formats
- Basic GTK4/LibAdwaita interface

### Changed
- Improved performance and stability

## [1.0.0] - (Initial Release)

### Added
- Initial release of Scramble
- Basic image metadata viewing
- Metadata removal functionality
- GTK4/LibAdwaita-based interface
- GNOME HIG-compliant design
- Flatpak packaging

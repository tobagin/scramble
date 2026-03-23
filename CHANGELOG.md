# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.2] - 2026-03-23

### 🐛 Fixed

- **JPEG file size increase**: Clean copies of JPEG images no longer grow larger than the original. Metadata is now stripped using GExiv2 (copy + strip) instead of re-encoding at a fixed quality of 95.
- **Saving fails on Flatpak**: Fixed a crash when saving on Flatpak-based systems (e.g. CachyOS) caused by GdkPixbuf failing to resolve the document portal FUSE path. Switched to GIO stream-based image loading for full portal compatibility.

### 🔧 Changed

- **Adaptive mobile layout**: The main window now responds to narrow widths (≤ 600px) by switching to a vertical layout, improving usability on smaller screens.
- **Build script**: Switched to a shared local Flatpak repo (`~/repo`) for installs, avoiding stale per-build remotes.

## [1.4.1] - 2026-01-12

### 📰 Metadata & Documentation

- **Branding**: Added official brand colors to metainfo for better store presence.
- **Documentation**: Significant improvements to README and metainfo descriptions.
- **Assets**: Added official Flathub and Ko-Fi badges.

## [1.4.0] - 2026-01-10

### ✨ New Features

- **Selective Metadata Removal**: Choose which metadata categories to remove (GPS, Camera, DateTime, Software, Author) instead of all-or-nothing.
- **Metadata Preferences**: New "Metadata Removal" section in Preferences with per-category toggle switches.
- **New Icons**: Fresh new application icons (Thanks to @oiimrosabel).

### 🔧 Changed

- **Development Icon**: Development builds now use the dedicated `io.github.tobagin.scramble.Devel.svg` icon.

## [1.3.0] - 2025-12-12

### ✨ New Features

- **CLI & Context Menu**: Support for opening images directly via CLI arguments and "Open With" context menu.
- **Magic Number Validation**: Validate all supported image formats (JPEG, PNG, WebP, TIFF, HEIF/HEIC) by their file signatures.
- **Development Symlinks**: New development-only setting to allow symlinks for testing.

### 🔒 Security

- **Enhanced Format Validation**: Magic number checking prevents processing of malicious files with fake extensions (SEC-003).
- **Symlink Protection**: Improved symlink handling to prevent TOCTOU attacks (SEC-001).
- **ReDoS Prevention**: Replaced regex-based error sanitization to prevent ReDoS attacks (SEC-002).
- **Privacy**: Removed unused network permission.

### 🔧 Changed

- **Project Structure**: Refactored to align with Vala/GNOME conventions (PascalCase files, logical subdirectories).
- **Error Handling**: Improved error messages with path disclosure prevention.

## [1.2.0] - 2025-10-08

### ✨ New Features

- **HEIF/HEIC Support**: Full metadata extraction for Apple's modern image formats.
- **Batch Processing**: Process multiple images at once with progress tracking and detailed reports.
- **Comparison View**: Side-by-side before/after comparison dialog.
- **Metadata Export**: Export metadata to JSON or CSV formats.
- **Keyboard Shortcuts**: Added shortcuts window with all available actions.
- **Format Support**: Added WebP and TIFF image format support.

### 🐛 Bug Fixes

- **Critical Save Bug**: Fixed 0-byte file save bug in Flatpak environment.
- **Shortcuts Dialog**: Now uses proper `Gtk.ShortcutsWindow`.
- **Format Conversion**: TIFF/WebP save failures now auto-convert to PNG.
- **Batch Stability**: Fixed batch processing crash caused by threading issues.

### 🔧 Changed

- **Format Detection**: Improved file format detection and validation.
- **Metadata Display**: Enhanced organization and presentation.

## [1.1.0] - (Earlier Release)

### ✨ New Features

- **Metadata Viewing**: Initial metadata viewing and removal functionality.
- **Format Support**: Support for JPEG and PNG formats.
- **GTK4 Interface**: Basic GTK4/LibAdwaita interface.

## [1.0.0] - (Initial Release)

### ✨ New Features

- **Initial Release**: First public release of Scramble.
- **Core Features**: Image metadata viewing and removal.
- **Modern UI**: GTK4/LibAdwaita-based interface following GNOME HIG.
- **Flatpak**: Secure sandboxed distribution via Flatpak.

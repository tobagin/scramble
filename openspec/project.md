# Project Context

## Purpose

**Scramble** is a privacy-focused GTK4/LibAdwaita application for viewing and removing metadata from images. The primary goal is to help users protect their privacy by easily removing sensitive information (EXIF, IPTC, XMP) embedded in image files before sharing them online or with others.

### Key Goals:
- Provide a simple, intuitive interface for metadata inspection and removal
- Ensure complete privacy with offline-only operation (no network access)
- Support modern image formats including HEIF/HEIC
- Maintain image quality during metadata removal
- Follow GNOME Human Interface Guidelines for consistent UX
- Enable batch processing for efficiency

## Tech Stack

### Core Technologies
- **Language**: Vala (GObject-based compiled language)
- **UI Framework**: GTK4 with LibAdwaita for modern GNOME design
- **UI Definition**: Blueprint (.blp files) - declarative UI markup
- **Build System**: Meson
- **Packaging**: Flatpak with GNOME runtime

### Key Libraries
- **GExiv2 0.16**: Metadata reading/writing (with BMFF support for HEIF/HEIC)
- **GdkPixbuf 2.0**: Image loading and basic manipulation
- **libheif**: HEIF/HEIC format support
- **libde265**: HEIC decoder
- **GLib/GIO**: Core utilities and I/O operations

### Development Tools
- **Blueprint Compiler**: Converts .blp to .ui files
- **flatpak-builder**: Builds and packages the application
- **Meson**: Build configuration and compilation

## Project Conventions

### Code Style

#### Naming Conventions
- **Classes**: PascalCase (e.g., `ScrambleWindow`, `MetadataRow`)
- **Methods/Functions**: snake_case (e.g., `load_image()`, `remove_metadata()`)
- **Constants**: UPPER_SNAKE_CASE
- **Private members**: Prefix with underscore (e.g., `_current_image`)
- **Namespace**: All classes prefixed with `Scramble.`

#### Formatting Rules
- **Indentation**: 4 spaces (no tabs)
- **Line length**: Keep under 120 characters when reasonable
- **Braces**: Opening brace on same line, closing brace on new line
- **Documentation**: All public methods must have Vala doc comments

#### Documentation Format
```vala
/**
 * Brief summary of what the method does.
 *
 * More detailed description if needed.
 *
 * @param param1 Description of first parameter
 * @param param2 Description of second parameter
 * @return Description of return value
 */
```

#### Code Organization
- **File size limit**: Maximum 500 lines per file - refactor if exceeded
- **Separation of concerns**: Each class in its own file
- **Blueprint files**: UI definitions separate from logic
- **Comments**: Use `// Reason:` for non-obvious logic explanations

### Architecture Patterns

#### Application Structure
- **Main Application** (`main.vala`): Entry point, application lifecycle
- **Window** (`window.vala`): Main window, image display, UI coordination
- **Feature Modules**: Separate files for distinct features:
  - `metadata_display.vala`: Metadata viewing logic
  - `metadata_exporter.vala`: Export to JSON/CSV
  - `batch_processor.vala`: Batch operations
  - `comparison_dialog.vala`: Before/after comparison
  - `image_operations.vala`: Core image processing
  - `file_validator.vala`: File type validation
  - `secure_memory.vala`: Memory cleanup utilities

#### UI Architecture
- **Blueprint-based**: All UI defined in .blp files under `data/ui/`
- **Template binding**: Widgets bound to Vala class properties
- **Signal-driven**: GTK signals connect UI events to handlers
- **Header bar integration**: Controls in AdwHeaderBar
- **Responsive layout**: 50/50 split pane (image | metadata)

#### Data Flow
1. User loads image (drag-drop or file picker)
2. Validator checks format support
3. GdkPixbuf loads image for display
4. GExiv2 extracts metadata
5. Metadata displayed in organized UI
6. User triggers cleanup
7. Image saved without metadata

### Testing Strategy

#### Current State
- **Manual testing**: Primary testing method
- **Test images**: Located in `~/test_images/` directory
- **Format coverage**: Test with JPEG, PNG, TIFF, WebP, HEIF, HEIC

#### Testing Requirements (from CLAUDE.md)
- **Unit tests**: Pytest-based tests for new features (note: needs adaptation for Vala)
- **Test structure**: Mirror main app structure in `/tests` folder
- **Coverage**: Minimum 3 tests per feature:
  1. Expected use case
  2. Edge case
  3. Failure case

#### Testing Approach
- **Development builds**: Use `./build.sh --dev` for testing
- **Flatpak environment**: All tests run in sandboxed environment
- **Metadata verification**: Confirm metadata is fully removed
- **Quality checks**: Ensure image quality maintained after processing

### Git Workflow

#### Branching Strategy
- **main**: Stable production branch
- **feature/XXX-description**: Feature development branches
- **fix/XXX-description**: Bug fix branches
- **Release tags**: Semantic versioning (e.g., `v1.2.0`)

#### Commit Conventions
- **Clear messages**: Descriptive commit messages (1-2 sentences)
- **Focus on why**: Explain motivation, not just what changed
- **Co-authored**: Claude Code commits include co-author attribution
- **Task tracking**: Reference `TASK.md` for completed work

#### Release Process
1. Update version in `meson.build`
2. Update `data/release-notes.md`
3. Build and test production version: `./build.sh`
4. Create git tag
5. Push with tags

## Domain Context

### Metadata Types
- **EXIF**: Camera settings, GPS location, timestamps, device info
- **IPTC**: Copyright, keywords, captions (journalism standard)
- **XMP**: Extensible metadata (Adobe standard)

### Privacy Concerns
- **GPS coordinates**: Exact location where photo was taken
- **Device fingerprinting**: Camera model, lens, serial numbers
- **Software traces**: Editing software, versions used
- **Timestamps**: When photo was taken, modified
- **Personal info**: Author names, copyright holders

### Image Format Specifics

#### HEIF/HEIC
- Modern format with high compression efficiency
- Multi-image sequences (burst photos)
- Requires BMFF support in Exiv2
- Apple's default iPhone format

#### Format Conversions
- **HEIF/HEIC → JPEG/PNG/WebP**: Required due to GdkPixbuf portal limitations
- **TIFF output → PNG**: Automatic conversion (lossless)
- **Quality preservation**: 95% quality for lossy formats

### GNOME/GTK Ecosystem
- **Flatpak sandbox**: Limited filesystem access (portal-based)
- **XDG portals**: File picker, save dialogs
- **GResource**: Embedded UI and resources
- **GSettings**: User preferences storage
- **Icon theme integration**: Symbolic and scalable icons

## Important Constraints

### Technical Constraints
- **Vala language**: Limited to GObject-compatible libraries
- **Flatpak sandbox**: No direct filesystem access, portal-based only
- **GdkPixbuf limitations**: Some format conversions required for saving
- **Offline only**: No network access permitted (privacy requirement)
- **GNOME 45+ runtime**: Minimum platform version

### Build Constraints
- **Meson only**: No alternative build systems
- **Blueprint required**: All UI must use Blueprint, not raw XML
- **Flatpak packaging**: Primary distribution method

### Performance Constraints
- **Memory management**: Must clear sensitive data from memory
- **Large images**: Handle high-resolution images efficiently
- **Batch processing**: Background processing without UI freeze

### Security/Privacy Constraints
- **No telemetry**: Zero data collection or analytics
- **No network access**: Complete offline operation
- **Original preservation**: Never modify original files
- **Secure cleanup**: Overwrite sensitive data in memory

### Design Constraints
- **GNOME HIG**: Must follow Human Interface Guidelines
- **LibAdwaita**: Use Adwaita widgets and design patterns
- **Accessibility**: Keyboard navigation, screen reader support
- **Internationalization**: Support translations via gettext

## External Dependencies

### GNOME Platform (Runtime)
- **org.gnome.Platform 49**: Base runtime environment
- **org.gnome.Sdk 49**: Development SDK

### Core Libraries (Bundled in Flatpak)
- **inih (r62)**: INI file parser (for Exiv2 config)
- **Exiv2 (v0.28.7)**: Metadata engine (with BMFF support enabled)
- **libde265 (v1.0.15)**: HEIC decoder
- **libheif (v1.19.8)**: HEIF/HEIC format support
- **GExiv2 (0.16.0)**: GObject wrapper for Exiv2

### Build Dependencies
- **flatpak-builder**: Flatpak packaging tool
- **blueprint-compiler**: Blueprint → GTK UI compiler
- **Vala compiler (valac)**: Source code compilation
- **Meson**: Build system

### Development Dependencies
- **Git**: Version control
- **Blueprint language server** (optional): IDE support for .blp files
- **Vala language server** (optional): IDE support for .vala files

### External Resources
- **Flathub**: Target distribution platform (planned)
- **GitHub**: Source hosting and issue tracking
- **Release notes**: `data/release-notes.md` displayed in app

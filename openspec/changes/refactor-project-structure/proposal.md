# Proposal: Refactor Project Structure for Vala Conventions

**Change ID**: `refactor-project-structure`
**Status**: Draft
**Created**: 2025-10-20
**Owners**: AI Assistant

## Overview

Refactor the project file structure to align with Vala/GNOME conventions and improve code organization. This includes renaming source files to PascalCase (matching their class names), organizing source code into logical subdirectories, restructuring UI files, relocating build scripts, and establishing a changelog.

## Why

The current project structure has several issues that impact maintainability and developer experience:

1. **Inconsistent file naming**: Source files use snake_case (e.g., `about-dialog.vala`, `batch_processor.vala`) while their class names are PascalCase (`AboutDialog`, `BatchProcessor`). This creates cognitive overhead when navigating between files and classes.

2. **Flat source directory**: All 15+ source files exist in `/src` with no logical grouping. As the project grows, finding related files becomes increasingly difficult.

3. **Flat UI directory**: All Blueprint files in `/data/ui` without categorization, making UI file management difficult.

4. **Build script location**: `build.sh` at project root alongside source and data directories, not clearly separated as a development tool.

5. **Missing changelog**: No structured CHANGELOG.md for tracking version history, making it hard for users and contributors to understand what changed between versions.

**Benefits of this refactoring:**
- **Vala convention alignment**: PascalCase file names are the norm in Vala/GNOME projects
- **Improved navigation**: Logical subdirectories make the codebase easier to explore and understand
- **Better scalability**: Structure supports future growth without clutter
- **Standard practices**: Follows GNOME/GTK ecosystem conventions
- **Version tracking**: CHANGELOG.md provides clear release history for users and contributors

## What Changes

- Rename all Vala source files from snake_case to PascalCase (13 files)
- Organize `/src` into subdirectories: `dialogs/`, `widgets/`, `core/`, `utils/`
- Organize `/data/ui` into subdirectories: `dialogs/`, `widgets/`
- Move `build.sh` to `scripts/build.sh`
- Create `CHANGELOG.md` with historical release entries
- Update `src/meson.build` with new file paths
- Update root `meson.build` with new Blueprint paths
- Update project documentation (README.md, CLAUDE.md, openspec/project.md)

## Proposed Changes

### 1. File Naming: snake_case → PascalCase
Rename all Vala source files to match their class names:

| Current | New | Class |
|---------|-----|-------|
| `about-dialog.vala` | `AboutDialog.vala` | `AboutDialog` |
| `batch_processor.vala` | `BatchProcessor.vala` | `BatchProcessor` |
| `comparison_dialog.vala` | `ComparisonDialog.vala` | `ComparisonDialog` |
| `file_validator.vala` | `FileValidator.vala` | `FileValidator` |
| `image_operations.vala` | `ImageOperations.vala` | `ImageOperations` |
| `metadata_display.vala` | `MetadataDisplay.vala` | `MetadataDisplay` |
| `metadata_exporter.vala` | `MetadataExporter.vala` | `MetadataExporter` |
| `metadata_row.vala` | `MetadataRow.vala` | `MetadataRow` |
| `preferences_dialog.vala` | `PreferencesDialog.vala` | `PreferencesDialog` |
| `secure_memory.vala` | `SecureMemory.vala` | `SecureMemory` |
| `shortcuts-window.vala` | `ShortcutsWindow.vala` | `ShortcutsWindow` |
| `window.vala` | `Window.vala` | `Window` |
| `main.vala` | `Main.vala` | (entry point) |

### 2. Source Directory Organization
Reorganize `/src` into logical subdirectories:

```
src/
├── Main.vala              # Application entry point
├── Window.vala            # Main window (keep at root for prominence)
├── Config.vala.in         # Build-time configuration
├── dialogs/               # Dialog windows
│   ├── AboutDialog.vala
│   ├── ComparisonDialog.vala
│   ├── PreferencesDialog.vala
│   └── ShortcutsWindow.vala
├── widgets/               # Custom widgets
│   └── MetadataRow.vala
├── core/                  # Core business logic
│   ├── BatchProcessor.vala
│   ├── ImageOperations.vala
│   ├── MetadataDisplay.vala
│   └── MetadataExporter.vala
└── utils/                 # Utility classes
    ├── FileValidator.vala
    └── SecureMemory.vala
```

### 3. UI Directory Organization
Organize `/data/ui` to mirror source structure:

```
data/ui/
├── Window.blp             # Main window (keep at root)
├── dialogs/
│   ├── PreferencesDialog.blp
│   └── ShortcutsWindow.blp
└── widgets/
    └── MetadataRow.blp
```

Note: `AboutDialog` is created programmatically (no .blp file)

### 4. Build Script Relocation
Move build-related scripts to dedicated directory:

```
scripts/
└── build.sh              # Development/production build script
```

### 5. Changelog Introduction
Create `CHANGELOG.md` at project root following Keep a Changelog format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2025-10-08
### Added
- HEIF/HEIC format support with metadata extraction
- Batch processing for multiple images
- Before/after comparison dialog
- Export metadata to JSON/CSV
...
```

## Impact Analysis

### Files Affected
- **Source files**: 13 Vala files renamed
- **Build files**: `src/meson.build` (update source file references)
- **Root meson.build**: Update blueprint compilation paths
- **Build script**: `build.sh` → `scripts/build.sh`
- **Documentation**: Update README.md, CLAUDE.md with new structure
- **New files**: `CHANGELOG.md`

### No Breaking Changes
- Class names remain unchanged
- Public API unchanged
- File references updated in build system
- Git history preserved (file renames tracked)

## Dependencies & Constraints

### Build System Updates Required
1. Update `src/meson.build` with new file paths
2. Update root `meson.build` blueprint compilation paths
3. Update any hardcoded paths in Flatpak manifest (if any)

### Developer Impact
- New contributors must learn new directory structure
- Documentation must be updated to reflect structure
- IDE/editor file navigation patterns change

### Git History
- Use `git mv` to preserve file history
- Rename operations tracked properly
- Minimal diff with proper tooling

## Success Criteria

1. All source files renamed to PascalCase
2. Source files organized into logical subdirectories
3. UI files organized to mirror source structure
4. Build script relocated to `scripts/` directory
5. CHANGELOG.md created with historical entries
6. All build configurations updated and functional
7. Development and production builds work: `scripts/build.sh --dev` and `scripts/build.sh`
8. Application runs without errors
9. Git history preserved for renamed files
10. Documentation updated (README.md, CLAUDE.md)

## Out of Scope

- Changing code logic or functionality
- Refactoring class implementations
- Modifying public APIs or interfaces
- Adding new features or capabilities
- Changing build system (Meson)
- Altering UI designs or layouts

## Related Changes

None - this is a standalone structural refactoring.

## Questions & Clarifications

None - requirements are clear and straightforward.

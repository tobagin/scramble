# Contributing to Scramble

Thank you for your interest in contributing to Scramble! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

## Code of Conduct

This project follows the general principles of respectful collaboration:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Assume good intentions

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/scramble.git
   cd scramble
   ```
3. **Add the upstream repository**:
   ```bash
   git remote add upstream https://github.com/tobagin/scramble.git
   ```

## Development Setup

### Prerequisites

- **Flatpak** and **flatpak-builder**
- **GNOME SDK 49** (installed automatically during build)
- **Git** for version control

### Building the Project

For development builds:
```bash
./scripts/build.sh --dev
```

For production builds:
```bash
./scripts/build.sh
```

### Running the Application

```bash
# Development version
flatpak run io.github.tobagin.scramble.Devel

# Production version
flatpak run io.github.tobagin.scramble
```

## Project Structure

```
scramble/
├── src/                    # Vala source code
│   ├── Main.vala          # Application entry point
│   ├── Window.vala        # Main window
│   ├── Config.vala.in     # Build-time configuration
│   ├── dialogs/           # Dialog windows
│   ├── widgets/           # Custom widgets
│   ├── core/              # Core business logic
│   └── utils/             # Utility classes
├── data/                  # Application data
│   ├── ui/                # Blueprint UI files
│   │   ├── dialogs/       # Dialog UI definitions
│   │   └── widgets/       # Widget UI definitions
│   ├── icons/             # Application icons
│   └── resources/         # GResource definitions
├── packaging/             # Flatpak manifests
├── scripts/               # Build and utility scripts
├── po/                    # Translations
└── openspec/              # Project specifications
```

## Coding Standards

### Vala Code Style

#### File Naming
- **Vala source files**: PascalCase matching the class name (e.g., `MetadataDisplay.vala`)
- **Blueprint UI files**: snake_case (e.g., `metadata_row.blp`, `window.blp`)

#### Naming Conventions
- **Classes**: PascalCase (e.g., `ScrambleWindow`, `MetadataRow`)
- **Methods/Functions**: snake_case (e.g., `load_image()`, `remove_metadata()`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_FILE_SIZE`)
- **Private members**: Prefix with underscore (e.g., `_current_image`)
- **Namespace**: All classes prefixed with `Scramble.`

#### Formatting
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
public void example_method(string param1, int param2) {
    // Implementation
}
```

### File Organization

- **Maximum file size**: 500 lines of code
- **One class per file**: Each class should have its own file
- **Logical grouping**: Place files in appropriate subdirectories:
  - `dialogs/` - Dialog windows (AboutDialog, PreferencesDialog, etc.)
  - `widgets/` - Custom widgets (MetadataRow, etc.)
  - `core/` - Core business logic (BatchProcessor, ImageOperations, etc.)
  - `utils/` - Utility classes (FileValidator, SecureMemory, etc.)

### Blueprint UI Files

- Use Blueprint syntax, not raw GTK XML
- Keep UI definitions separate from logic
- Use snake_case for file names
- Organize into subdirectories matching source structure

## Making Changes

### Branching Strategy

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards

3. **Keep commits focused**:
   - One logical change per commit
   - Write clear, descriptive commit messages
   - Follow the commit message format (see below)

### Commit Message Format

```
Brief summary of the change (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain the problem this commit solves and how it solves it.

- Use bullet points for multiple changes
- Reference issue numbers if applicable

Fixes #123
```

### Before Committing

1. **Build the project** to ensure no errors:
   ```bash
   ./scripts/build.sh --dev
   ```

2. **Test your changes** manually:
   - Launch the application
   - Test affected features
   - Test all dialogs if UI changes were made

3. **Check for code quality**:
   - Follow naming conventions
   - Add documentation comments
   - Keep code clean and readable

## Testing

While Scramble doesn't currently have automated tests, manual testing is required:

### Testing Checklist

- [ ] Application launches without errors
- [ ] Main window displays correctly
- [ ] Image loading works (JPEG, PNG, TIFF, WebP, HEIF/HEIC)
- [ ] Metadata displays correctly
- [ ] Metadata removal works
- [ ] Image saving works without data loss
- [ ] All dialogs open and function correctly:
  - [ ] About dialog
  - [ ] Preferences dialog
  - [ ] Shortcuts window
  - [ ] Comparison dialog (if applicable)
- [ ] Batch processing works (if applicable)
- [ ] Export features work (JSON/CSV)
- [ ] No crashes or errors in terminal output

### Test Images

Use test images located in `~/test_images/` with various formats:
- JPEG with EXIF data
- PNG with metadata
- HEIF/HEIC files
- TIFF files
- WebP images

## Submitting Changes

### Pull Request Process

1. **Update documentation** if needed:
   - Update README.md for user-facing changes
   - Update CLAUDE.md for development conventions
   - Add entry to CHANGELOG.md under `[Unreleased]`

2. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request** on GitHub:
   - Use a clear, descriptive title
   - Reference any related issues
   - Describe what changes were made and why
   - Include screenshots for UI changes
   - List testing performed

4. **Address review feedback**:
   - Respond to comments
   - Make requested changes
   - Push updates to your branch

### Pull Request Template

```markdown
## Description
Brief description of the changes

## Motivation
Why this change is needed

## Changes Made
- List of specific changes
- Another change

## Testing Performed
- [ ] Built successfully
- [ ] Tested feature X
- [ ] Verified no regressions

## Screenshots (if applicable)
[Add screenshots for UI changes]

## Related Issues
Fixes #123
```

## Reporting Bugs

When reporting bugs, please include:

1. **Clear title** describing the issue
2. **Steps to reproduce** the bug
3. **Expected behavior** vs **actual behavior**
4. **Environment information**:
   - Scramble version
   - Linux distribution
   - GNOME/GTK version
   - Flatpak version
5. **Relevant logs** or error messages
6. **Screenshots** if applicable

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Environment:**
- Scramble version: [e.g., 1.2.0]
- Linux distribution: [e.g., Fedora 39]
- GNOME version: [e.g., 45]

**Additional context**
Any other relevant information.
```

## Requesting Features

Feature requests are welcome! Please:

1. **Check existing issues** to avoid duplicates
2. **Describe the feature** clearly
3. **Explain the use case** and why it's valuable
4. **Consider implementation** if you have ideas
5. **Be open to discussion** about the approach

### Feature Request Template

```markdown
**Feature Description**
Clear description of the proposed feature.

**Use Case**
Why this feature would be valuable.

**Proposed Solution**
How you envision this working (optional).

**Alternatives Considered**
Other approaches you've thought about (optional).
```

## Development Workflow

### Typical Development Cycle

1. **Sync with upstream**:
   ```bash
   git checkout main
   git fetch upstream
   git merge upstream/main
   ```

2. **Create feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make changes**:
   - Write code following standards
   - Add documentation
   - Update CHANGELOG.md

4. **Test changes**:
   ```bash
   ./scripts/build.sh --dev
   flatpak run io.github.tobagin.scramble.Devel
   ```

5. **Commit changes**:
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```

6. **Push and create PR**:
   ```bash
   git push origin feature/my-feature
   ```

## Additional Resources

- **GNOME Human Interface Guidelines**: https://developer.gnome.org/hig/
- **Vala Documentation**: https://valadoc.org/
- **Blueprint Documentation**: https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/
- **LibAdwaita Documentation**: https://gnome.pages.gitlab.gnome.org/libadwaita/

## Questions?

If you have questions about contributing:

1. Check existing documentation (README.md, CLAUDE.md)
2. Search existing issues
3. Open a new issue with the "question" label
4. Reach out to maintainers

## License

By contributing to Scramble, you agree that your contributions will be licensed under the GNU General Public License v3.0.

---

Thank you for contributing to Scramble! Your efforts help make privacy tools accessible to everyone.

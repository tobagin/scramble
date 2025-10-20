# Tasks: Refactor Project Structure

**Change ID**: refactor-project-structure
**Status**: Ready for approval

## Prerequisites

- [x] Ensure working directory is clean (`git status`)
- [x] Ensure all tests pass (if applicable)
- [x] Create feature branch: `git checkout -b refactor-project-structure`

## Phase 1: Directory Structure Setup

**Goal**: Create new directory structure without moving files yet

- [x] **T001**: Create `src/dialogs/` directory
- [x] **T002**: Create `src/widgets/` directory
- [x] **T003**: Create `src/core/` directory
- [x] **T004**: Create `src/utils/` directory
- [x] **T005**: Create `data/ui/dialogs/` directory
- [x] **T006**: Create `data/ui/widgets/` directory
- [x] **T007**: Create `scripts/` directory at project root

**Validation**: All directories exist and are tracked by git

## Phase 2: Vala Source File Renaming and Organization

**Goal**: Rename and move all Vala source files using git mv to preserve history

### Dialogs
- [x] **T101**: `git mv src/about-dialog.vala src/dialogs/AboutDialog.vala`
- [x] **T102**: `git mv src/comparison_dialog.vala src/dialogs/ComparisonDialog.vala`
- [x] **T103**: `git mv src/preferences_dialog.vala src/dialogs/PreferencesDialog.vala`
- [x] **T104**: `git mv src/shortcuts-window.vala src/dialogs/ShortcutsWindow.vala`

### Widgets
- [x] **T111**: `git mv src/metadata_row.vala src/widgets/MetadataRow.vala`

### Core Business Logic
- [x] **T121**: `git mv src/batch_processor.vala src/core/BatchProcessor.vala`
- [x] **T122**: `git mv src/image_operations.vala src/core/ImageOperations.vala`
- [x] **T123**: `git mv src/metadata_display.vala src/core/MetadataDisplay.vala`
- [x] **T124**: `git mv src/metadata_exporter.vala src/core/MetadataExporter.vala`

### Utils
- [x] **T131**: `git mv src/file_validator.vala src/utils/FileValidator.vala`
- [x] **T132**: `git mv src/secure_memory.vala src/utils/SecureMemory.vala`

### Root Files (rename only, stay at src/ root)
- [x] **T141**: `git mv src/main.vala src/Main.vala`
- [x] **T142**: `git mv src/window.vala src/Window.vala`
- [x] **T143**: `git mv src/config.vala.in src/Config.vala.in`

**Validation**: All Vala files renamed and moved, git history preserved

## Phase 3: Blueprint UI File Organization

**Goal**: Move Blueprint files to subdirectories (keeping snake_case naming per Vala/Blueprint conventions)

### Dialogs
- [x] **T201**: `git mv data/ui/preferences_dialog.blp data/ui/dialogs/preferences_dialog.blp`
- [x] **T202**: `git mv data/ui/shortcuts-window.blp data/ui/dialogs/shortcuts_window.blp`

### Widgets
- [x] **T211**: `git mv data/ui/metadata_row.blp data/ui/widgets/metadata_row.blp`

### Root (keep at data/ui/ root)
- [x] **T221**: Keep `data/ui/window.blp` at root (no rename needed)

**Validation**: All Blueprint files organized into subdirectories

## Phase 4: Build Script Relocation

**Goal**: Move build script to scripts directory

- [x] **T301**: `git mv build.sh scripts/build.sh`
- [x] **T302**: Update relative paths in `scripts/build.sh` (added `cd "$(dirname "$0")/.."`)
- [x] **T303**: Test script execution: `./scripts/build.sh --dev`
- [x] **T304**: Verify script can still find Flatpak manifest and project files

**Validation**: Build script works from new location

## Phase 5: Meson Build System Updates

**Goal**: Update build configuration to reference new file paths

### Update src/meson.build
- [x] **T401**: Update `src/meson.build` to reference all source files with new paths:
  - Main files: `Main.vala`, `Window.vala`, `Config.vala.in`
  - Dialog files: `dialogs/AboutDialog.vala`, `dialogs/ComparisonDialog.vala`, `dialogs/PreferencesDialog.vala`, `dialogs/ShortcutsWindow.vala`
  - Widget files: `widgets/MetadataRow.vala`
  - Core files: `core/BatchProcessor.vala`, `core/ImageOperations.vala`, `core/MetadataDisplay.vala`, `core/MetadataExporter.vala`
  - Utils files: `utils/FileValidator.vala`, `utils/SecureMemory.vala`
- [x] **T402**: Verify syntax is correct in `src/meson.build`

### Update root meson.build
- [x] **T411**: Update Blueprint compilation custom_target for window.blp (kept snake_case per conventions):
  - Changed input path to `files('data/ui/window.blp')`
  - Output: `window.ui`
- [x] **T412**: Update Blueprint compilation custom_target for metadata_row.blp:
  - Changed input path to `files('data/ui/widgets/metadata_row.blp')`
- [x] **T413**: Update Blueprint compilation custom_target for preferences_dialog.blp:
  - Changed input path to `files('data/ui/dialogs/preferences_dialog.blp')`
- [x] **T414**: Update Blueprint compilation custom_target for shortcuts_window.blp:
  - Changed input path to `files('data/ui/dialogs/shortcuts_window.blp')`
- [x] **T415**: Verify all output names match GResource references (kept snake_case)

### Update data/ui/meson.build
- [x] **T421**: Checked `data/ui/meson.build` - no updates needed
- [x] **T422**: No install_data() calls requiring updates

**Validation**: Meson configuration is syntactically correct

## Phase 6: Build Testing

**Goal**: Verify the application builds and runs correctly

- [x] **T501**: Clean build directory: `rm -rf _build`
- [x] **T502**: Run development build: `./scripts/build.sh --dev`
- [x] **T503**: Verify build completes without errors
- [x] **T504**: Test application launch: `flatpak run io.github.tobagin.scramble.Devel`
- [x] **T505**: Verify main window loads correctly
- [ ] **T506**: Test loading an image (user can test manually)
- [ ] **T507**: Test metadata display functionality (user can test manually)
- [ ] **T508**: Test all dialogs (About, Preferences, Shortcuts, Comparison) (user can test manually)
- [ ] **T509**: Test metadata removal and save functionality (user can test manually)
- [ ] **T510**: Run production build: `./scripts/build.sh` (user can test)
- [ ] **T511**: Verify production build completes successfully (user can test)

**Validation**: Application builds and launches successfully in dev mode

## Phase 7: Documentation Updates

**Goal**: Update all documentation to reflect new structure

### CHANGELOG.md Creation
- [x] **T601**: Create `CHANGELOG.md` at project root
- [x] **T602**: Add header with Keep a Changelog reference
- [x] **T603**: Add `[Unreleased]` section with current refactoring note
- [x] **T604**: Add historical entries for v1.2.0, v1.1.0, v1.0.0 from git history
- [x] **T605**: Format all entries following Keep a Changelog sections (Added, Changed, Fixed, etc.)

### README.md Updates
- [ ] **T611**: Add or update "Project Structure" section in README.md
- [ ] **T612**: Document new directory layout with explanations
- [ ] **T613**: Update build instructions to use `./scripts/build.sh`
- [ ] **T614**: Update any other references to file paths

### CLAUDE.md Updates
- [ ] **T621**: Update "Code Structure & Modularity" section with new subdirectory structure
- [ ] **T622**: Add PascalCase file naming convention explicitly
- [ ] **T623**: Update build command references to `./scripts/build.sh`
- [ ] **T624**: Add guidance for where to place new files (dialogs/, widgets/, core/, utils/)

### openspec/project.md Updates
- [ ] **T631**: Update "Code Organization" section under "Project Conventions"
- [ ] **T632**: Document subdirectory purposes (dialogs, widgets, core, utils)
- [ ] **T633**: Update file naming conventions to specify PascalCase
- [ ] **T634**: Update architecture patterns section with new organization
- [ ] **T635**: Update build script references to `./scripts/build.sh`

**Validation**: All documentation accurately reflects new structure

## Phase 8: Git Finalization

**Goal**: Commit changes and prepare for merge

- [ ] **T701**: Stage all changes: `git add -A`
- [ ] **T702**: Review staged changes: `git status` and `git diff --cached --stat`
- [ ] **T703**: Commit with message: "Refactor project structure to Vala conventions"
- [ ] **T704**: Verify commit includes all renamed files with history
- [ ] **T705**: Push branch: `git push -u origin refactor-project-structure`

**Validation**: All changes committed with proper git history

## Dependencies

### Sequential Dependencies
- Phase 1 must complete before Phase 2, 3, 4 (need directories first)
- Phases 2, 3, 4 can run in parallel (file renames independent)
- Phase 5 depends on Phases 2, 3, 4 (need new paths to reference)
- Phase 6 depends on Phase 5 (need working build config)
- Phase 7 can partially run in parallel with earlier phases
- Phase 8 depends on all previous phases

### Parallelizable Work
- T101-T143 (Vala renames) can be done quickly in sequence
- T201-T221 (Blueprint renames) can be done quickly in sequence
- T601-T635 (documentation updates) can be started early and refined later

## Rollback Plan

If issues are encountered:

1. **Before committing**: `git reset --hard` to discard changes
2. **After committing**: `git revert HEAD` to undo commit
3. **Partial rollback**: Use `git mv` to move individual files back if needed
4. **Build issues**: Check meson.build paths first, as most likely source of errors

## Success Criteria

- [ ] All source files use PascalCase naming
- [ ] Source directory organized into dialogs/, widgets/, core/, utils/
- [ ] UI directory mirrors source organization
- [ ] Build script located at scripts/build.sh
- [ ] CHANGELOG.md exists with historical entries
- [ ] All meson.build files reference correct paths
- [ ] Development build succeeds: `./scripts/build.sh --dev`
- [ ] Production build succeeds: `./scripts/build.sh`
- [ ] Application launches and all features work
- [ ] All documentation updated and accurate
- [ ] Git history preserved for all renamed files
- [ ] Changes committed to feature branch

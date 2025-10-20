# Tasks: Enhance Security and Validation

**Change ID**: enhance-security-and-validation
**Status**: Completed
**Priority**: High (Security & Stability - Phase 1)

## Prerequisites

- [x] Review ANALYSIS.md security findings
- [x] Review current FileValidator.vala implementation
- [x] Create feature branch: `git checkout -b enhance-security-validation`

## Phase 1: Create Constants and Utilities (Foundation)

**Goal**: Establish shared constants and utility classes for validation

### Task Group 1.1: Constants File
- [x] **T001**: Create `src/utils/Constants.vala`
- [x] **T002**: Define magic number constants for all formats:
  ```vala
  public const uint8[] JPEG_MAGIC = {0xFF, 0xD8, 0xFF};
  public const uint8[] PNG_MAGIC = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
  public const uint8[] WEBP_RIFF = {0x52, 0x49, 0x46, 0x46};
  public const uint8[] WEBP_WEBP = {0x57, 0x45, 0x42, 0x50};
  public const uint8[] TIFF_LE = {0x49, 0x49, 0x2A, 0x00};  // Little-endian
  public const uint8[] TIFF_BE = {0x4D, 0x4D, 0x00, 0x2A};  // Big-endian
  ```
- [x] **T003**: Define file size and quality constants:
  ```vala
  public const int64 MAX_FILE_SIZE = 500 * 1024 * 1024;
  public const int JPEG_QUALITY = 95;
  public const int WEBP_QUALITY = 95;
  public const int SECURE_MEMORY_PASSES = 3;
  public const int BATCH_SIZE_LIMIT = 1000;
  ```
- [x] **T004**: Add documentation for each constant
- [x] **T005**: Update meson.build to include Constants.vala

**Validation**: Constants.vala compiles, constants accessible from other files

### Task Group 1.2: Magic Number Validator
- [x] **T011**: Create `src/utils/MagicNumberValidator.vala`
- [x] **T012**: Implement `validate_format(string path, string extension)` method
- [x] **T013**: Implement JPEG validation:
  ```vala
  private static bool validate_jpeg(File file) throws Error {
      var stream = file.read();
      var buffer = new uint8[3];
      stream.read(buffer);
      return memory_compare(buffer, Constants.JPEG_MAGIC, 3);
  }
  ```
- [x] **T014**: Implement PNG validation (8 bytes)
- [x] **T015**: Implement WebP validation (12 bytes, RIFF + WEBP)
- [x] **T016**: Implement TIFF validation (4 bytes, both endianness)
- [x] **T017**: Implement HEIF/HEIC validation (ftyp box check)
- [x] **T018**: Add helper method `memory_compare(uint8[] a, uint8[] b, int len)`
- [x] **T019**: Add comprehensive error messages for each format
- [x] **T020**: Add Vala doc comments for all public methods

**Validation**: Each format validator tested with sample files

## Phase 2: Update FileValidator (Security Hardening)

**Goal**: Enhance FileValidator with symlink handling and safer error sanitization

### Task Group 2.1: Symlink Handling
- [x] **T101**: Add GSettings schema entry for development symlink setting:
  ```xml
  <key name="allow-symlinks-dev" type="b">
    <default>false</default>
    <summary>Allow symlinks in development</summary>
    <description>Development-only setting to allow symbolic links</description>
  </key>
  ```
- [x] **T102**: Update `FileValidator.validate_path()` to check for symlinks
- [x] **T103**: Implement symlink rejection logic:
  ```vala
  if (info.get_is_symlink()) {
      #if DEVELOPMENT
          if (settings.get_boolean("allow-symlinks-dev")) {
              // Resolve and validate target
              var target = file.resolve_relative_path("");
              validate_path(target.get_path());  // Recursive
              return;
          }
      #endif
      throw new FileError.FAILED(_("Symbolic links are not supported for security reasons"));
  }
  ```
- [x] **T104**: Add warning log for symlink attempts
- [x] **T105**: Update error messages for clarity

**Validation**: Symlinks rejected in production, optional in development

### Task Group 2.2: Safe Error Sanitization
- [x] **T111**: Replace regex-based `sanitize_error_message()` with string operations:
  ```vala
  public static string sanitize_error_message(string error_msg) {
      var sanitized = error_msg;

      // Split by forward slash
      var parts = sanitized.split("/");

      // If we have an absolute path (starts with /)
      if (parts.length > 1 && sanitized.has_prefix("/")) {
          // Keep only the descriptive part, replace path
          var last_part = parts[parts.length - 1];
          return "File error: " + last_part;
      }

      return sanitized;
  }
  ```
- [x] **T112**: Test with various path formats (absolute, relative, multiple paths)
- [x] **T113**: Ensure performance < 1ms
- [x] **T114**: Update unit test expectations if tests exist

**Validation**: Path disclosure prevented, performance acceptable

## Phase 3: Integrate Format Validation

**Goal**: Add magic number validation to image loading pipeline

### Task Group 3.1: ImageOperations Integration
- [x] **T201**: Update `ImageOperations.is_supported_format()` to call magic number validator
- [x] **T202**: Modify `save_clean_copy()` to validate format before loading:
  ```vala
  public static bool save_clean_copy(string in_path, string out_path) {
      try {
          // Validate input path
          FileValidator.validate_path(in_path);

          // Validate format by magic numbers
          var ext = get_extension(in_path);
          if (!MagicNumberValidator.validate_format(in_path, ext)) {
              throw new FileError.FAILED(_("File format does not match extension"));
          }

          // Continue with existing logic...
      }
  }
  ```
- [x] **T203**: Add format validation to `Window.load_image()`
- [x] **T204**: Add clear error messages for format mismatch
- [x] **T205**: Log format validation failures at WARNING level

**Validation**: Malicious files with wrong extensions rejected

### Task Group 3.2: Batch Processing Integration
- [x] **T211**: Update `BatchProcessor.process_batch()` to validate each file
- [x] **T212**: Continue processing other files if one fails validation
- [x] **T213**: Include validation errors in BatchResult
- [x] **T214**: Update batch progress dialog to show validation errors

**Validation**: Batch processing handles validation errors gracefully

## Phase 4: Privacy Hardening

**Goal**: Remove unused permissions and enhance privacy posture

### Task Group 4.1: Flatpak Manifest Updates
- [x] **T301**: Remove `--share=network` from `packaging/io.github.tobagin.scramble.Devel.yml`
- [x] **T302**: Remove `--share=network` from `packaging/io.github.tobagin.scramble.yml`
- [x] **T303**: Verify no network-related code exists in codebase:
  ```bash
  rg "http|network|socket|curl|fetch" src/
  ```
- [x] **T304**: Update app metadata to emphasize offline-only operation

**Validation**: App functions identically without network permission

### Task Group 4.2: Security Logging
- [x] **T311**: Add logging utility for security events (if not exists)
- [x] **T312**: Log symlink attempts: `warning("Symlink detected and rejected: %s", sanitized_path)`
- [x] **T313**: Log format mismatches: `warning("Format mismatch: %s claims %s but is %s", filename, claimed, detected)`
- [x] **T314**: Ensure logs don't contain sensitive information
- [x] **T315**: Document logging format for security monitoring

**Validation**: Security events properly logged, no sensitive data leaked

## Phase 5: Build and Testing

**Goal**: Ensure changes compile, function correctly, and don't break existing features

### Task Group 5.1: Build Verification
- [x] **T401**: Clean build: `rm -rf build _build`
- [x] **T402**: Development build: `./scripts/build.sh --dev`
- [x] **T403**: Fix any compilation errors
- [x] **T404**: Production build: `./scripts/build.sh`
- [x] **T405**: Verify both builds complete successfully

**Validation**: Clean builds for dev and production

### Task Group 5.2: Functional Testing
- [x] **T411**: Test valid JPEG file loads correctly
- [x] **T412**: Test valid PNG file loads correctly
- [x] **T413**: Test valid WebP file loads correctly
- [x] **T414**: Test valid TIFF file loads correctly
- [x] **T415**: Test valid HEIF/HEIC file loads correctly

**Validation**: All supported formats work as before

### Task Group 5.3: Security Testing
- [x] **T421**: Create test file with .jpg extension but PNG content
- [x] **T422**: Verify malicious file rejected with clear error
- [x] **T423**: Create symlink to valid image in production mode
- [x] **T424**: Verify symlink rejected in production
- [x] **T425**: Enable dev symlink setting and test symlink loads
- [x] **T426**: Test error messages don't contain full paths
- [x] **T427**: Verify validation completes quickly (< 50ms per file)

**Validation**: Security enhancements working as specified

### Task Group 5.4: Regression Testing
- [x] **T431**: Test batch processing with multiple valid files
- [x] **T432**: Test comparison dialog still works
- [x] **T433**: Test metadata export functions
- [x] **T434**: Test all dialogs (About, Preferences, Shortcuts)
- [x] **T435**: Test drag-and-drop functionality
- [x] **T436**: Test save operations for all formats

**Validation**: No regressions in existing functionality

## Phase 6: Documentation Updates

**Goal**: Update documentation to reflect security changes

### Task Group 6.1: Code Documentation
- [x] **T501**: Add/update Vala doc comments in Constants.vala
- [x] **T502**: Add/update Vala doc comments in MagicNumberValidator.vala
- [x] **T503**: Update FileValidator.vala doc comments
- [x] **T504**: Add security notes to ImageOperations.vala

**Validation**: All public APIs documented

### Task Group 6.2: User Documentation
- [x] **T511**: Update CHANGELOG.md:
  ```markdown
  ## [Unreleased]
  ### Security
  - Enhanced file format validation with magic number checking
  - Improved symlink handling to prevent security vulnerabilities
  - Removed unused network permission for better privacy
  - Safer error message sanitization
  ```
- [x] **T512**: Update README.md security section if exists
- [x] **T513**: Update CLAUDE.md with new validation patterns

**Validation**: Documentation reflects security improvements

### Task Group 6.3: Development Documentation
- [x] **T521**: Document development symlink setting in CONTRIBUTING.md
- [x] **T522**: Add security testing guidelines
- [x] **T523**: Document magic number format for future extensions

**Validation**: Contributors understand security features

## Phase 7: Git Finalization

**Goal**: Commit changes properly

- [x] **T601**: Stage all changes: `git add -A`
- [x] **T602**: Review changes: `git diff --cached --stat`
- [x] **T603**: Commit with descriptive message referencing SEC-001, SEC-002, SEC-003
- [x] **T604**: Push branch: `git push -u origin enhance-security-validation`
- [x] **T605**: Create pull request with security testing checklist

**Validation**: Changes committed, PR ready for review

## Dependencies

### Sequential Dependencies:
- Phase 1 must complete before Phase 2-3 (need Constants and MagicNumberValidator)
- Phase 2-3 can run in parallel (FileValidator and ImageOperations independent)
- Phase 4 depends on Phase 2-3 completion (logging needs validators)
- Phase 5 depends on all implementation phases (1-4)
- Phase 6-7 can overlap with Phase 5 testing

### Parallelizable Work:
- T013-T017 (format validators) can be implemented in parallel
- T201-T205 and T211-T214 (integration points) can be done simultaneously
- T301-T304 (manifest updates) independent of code changes

## Success Criteria

- [x] All security vulnerabilities (SEC-001, SEC-002, SEC-003) addressed
- [x] No regressions in existing functionality
- [x] All builds pass (dev and production)
- [x] Security tests demonstrate protection against attacks
- [x] Performance acceptable (< 50ms validation overhead)
- [x] Documentation complete and accurate
- [x] Code review passed
- [x] Ready for Phase 2 (UX improvements)

## Rollback Plan

If critical issues found:
1. Revert feature branch: `git reset --hard origin/main`
2. Identify specific problematic change
3. Create minimal fix or revert specific commit
4. Re-test thoroughly before re-deploying

## Notes

- Keep changes focused on security - no feature additions
- Maintain backward compatibility for legitimate use cases
- Prioritize correctness over performance
- Document all security decisions
- Coordinate with Phase 2 planning (UX features can build on this foundation)

# Proposal: Enhance Security and Validation (Phase 1)

**Change ID**: `enhance-security-and-validation`
**Status**: Draft
**Created**: 2025-10-20
**Owners**: Development Team
**Priority**: High (Security & Stability)

## Overview

Implement critical security improvements and validation enhancements identified in the comprehensive codebase analysis (ANALYSIS.md). This change focuses on Phase 1 priorities: addressing security vulnerabilities, improving file format validation, and removing unused network permissions.

## Why

The codebase analysis revealed several security concerns that should be addressed before adding new features:

1. **Symlink Handling Vulnerability (SEC-001)**: Current implementation logs symlinks but allows them, creating potential Time-of-Check-Time-of-Use (TOCTOU) race conditions and potential access to sensitive files outside the intended scope.

2. **Missing Format Validation (SEC-003)**: File format detection relies solely on extensions, making the application vulnerable to malicious files disguised with image extensions. No magic number validation exists.

3. **Regex DoS Risk (SEC-002)**: Error message sanitization uses a complex regex pattern that could cause Regular Expression Denial of Service with crafted input.

4. **Unused Network Permission**: Flatpak manifest includes `--share=network` despite no network code existing, violating principle of least privilege.

**Impact if not addressed**:
- Security vulnerabilities could be exploited
- User data could be at risk
- Trust in privacy-focused application undermined
- Potential for crashes or resource exhaustion

## What Changes

### Security Enhancements:
- **SEC-001**: Implement proper symlink handling (reject or resolve & validate)
- **SEC-002**: Replace regex-based sanitization with safer string operations
- **SEC-003**: Add magic number validation for all supported image formats
- **Privacy**: Remove unused `--share=network` permission from Flatpak manifest

### Supporting Changes:
- Add `MagicNumberValidator` utility class
- Create constants for file format signatures
- Update `FileValidator` with enhanced security checks
- Add comprehensive error handling for new validation

## Impact

### Files Affected:
- `src/utils/FileValidator.vala` (enhanced symlink handling, simplified sanitization)
- `src/utils/MagicNumberValidator.vala` (new file, ~150 lines)
- `src/core/ImageOperations.vala` (integrate format validation)
- `src/utils/Constants.vala` (new file, format signatures and constants)
- `packaging/io.github.tobagin.scramble.Devel.yml` (remove network permission)
- `packaging/io.github.tobagin.scramble.yml` (remove network permission)

### User-Facing Changes:
- **Improved security**: Protection against malicious files and symlink attacks
- **Better error messages**: Clear feedback when files fail validation
- **No breaking changes**: Legitimate use cases remain unchanged

### Developer Impact:
- More robust validation framework for future enhancements
- Clearer separation of validation concerns
- Foundation for unit testing implementation

## Dependencies & Constraints

### Technical Dependencies:
- GLib file operations for magic number reading
- Vala 0.56+ for pattern matching features

### Constraints:
- Must maintain backward compatibility with existing workflows
- Cannot break legitimate symlink use cases in development
- Validation must be performant (< 50ms per file)

## Out of Scope

This proposal does NOT include:
- Unit testing framework (will be separate proposal)
- Window.vala refactoring
- New user-facing features (undo/redo, preview, etc.)
- Performance optimizations beyond validation
- Batch operation rate limiting (low priority per analysis)

## Success Criteria

1. ✅ Symlinks properly handled (either rejected or validated)
2. ✅ All supported formats validated by magic numbers
3. ✅ Error sanitization uses safe string operations
4. ✅ Network permission removed from manifests
5. ✅ Application builds and passes manual security tests
6. ✅ No performance regression (file loading < 50ms overhead)
7. ✅ All existing functionality works as before
8. ✅ Clear error messages for validation failures

## Security Considerations

### Threat Model:
- **Threat**: Malicious files with fake extensions
- **Mitigation**: Magic number validation before processing

- **Threat**: Symlink-based TOCTOU attacks
- **Mitigation**: Either reject symlinks or resolve and validate target

- **Threat**: Path disclosure via error messages
- **Mitigation**: Safe string-based sanitization without regex

### Privacy Impact:
- **Positive**: Removes unnecessary network permission
- **Neutral**: No new data collection or external communication

## Alternatives Considered

### Symlink Handling Options:
1. **Reject all symlinks** (chosen for production)
   - Pros: Simplest, most secure
   - Cons: May inconvenience developers

2. **Resolve and validate**
   - Pros: More flexible
   - Cons: Complex, potential performance impact

3. **Allow with enhanced logging**
   - Pros: No behavior change
   - Cons: Doesn't address security concern

**Decision**: Reject symlinks in production, with clear error message. Development builds can use a setting to allow them.

### Format Validation Strategy:
1. **Magic numbers only** (chosen)
   - Pros: Fast, reliable, industry standard
   - Cons: Requires maintenance for new formats

2. **Full file parsing**
   - Pros: Most thorough
   - Cons: Too slow, complex

3. **Extension only** (current)
   - Pros: Fast
   - Cons: Insecure

## Questions & Clarifications

**Q**: Should symlink rejection be configurable?
**A**: Yes, add a development-only setting to allow symlinks for testing.

**Q**: What about new image formats in the future?
**A**: `MagicNumberValidator` designed for easy extension with new format signatures.

**Q**: Performance impact of magic number validation?
**A**: Minimal - only reads first 12 bytes of file. Target < 10ms per file.

## Related Work

- Depends on: None (standalone security improvements)
- Enables: Future unit testing proposal (easier to test validation logic)
- Related to: Phase 2 features (preview dialog will benefit from safer validation)

---

**Next Steps**:
1. Review and approve proposal
2. Implement security enhancements
3. Manual security testing
4. Prepare for Phase 2 (UX improvements)

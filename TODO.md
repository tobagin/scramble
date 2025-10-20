# Scramble - Feature Ideas & TODO

This document tracks potential features and enhancements for the Scramble application, organized by priority and complexity.

**Last Updated**: 2025-10-20

---

## Priority Tier 1: High Impact, Moderate Effort ⭐

### 1. Selective Metadata Removal
**Status**: Not Started
**Estimated Effort**: Medium
**User Value**: Very High

Currently, Scramble is all-or-nothing - you can only remove ALL metadata. Add ability to selectively remove or keep specific metadata fields.

**Potential Implementation**:
- Checkboxes to choose which metadata categories to strip:
  - EXIF only
  - GPS only
  - IPTC only
  - XMP only
  - Camera info only
  - Date/time info only
- Quick action buttons:
  - "Remove GPS only" - strip location while keeping camera settings
  - "Remove device info" - strip camera/phone model
  - "Remove personal data" - smart removal of identifying information
- Metadata editing interface:
  - Edit specific fields (copyright, author, description) before saving
  - Add custom metadata while removing sensitive data
- Save selection as preset for future use

**Use Cases**:
- Photographers who want to keep camera settings but remove GPS
- Content creators who want to add copyright while removing personal data
- Users sharing photos who want to keep date/time but remove device info

---

### 2. Metadata Analysis & Privacy Reporting
**Status**: Not Started
**Estimated Effort**: Medium
**User Value**: Very High

Add analytics and insights about image collection metadata to help users understand privacy exposure.

**Potential Implementation**:
- **Privacy Risk Scoring**:
  - Analyze images for sensitive data (GPS, device info, names)
  - Color-coded risk levels (High/Medium/Low)
  - Dashboard showing: "X files contain GPS data", "Y files have device info"
- **Metadata Statistics Dashboard**:
  - Summary of batch processing results
  - Charts showing metadata distribution
  - Most common cameras/devices in collection
- **Batch Export Reports**:
  - Generate HTML or PDF report of all metadata from batch
  - Include thumbnails and key metadata fields
  - Privacy analysis summary
- **Advanced Analysis**:
  - Duplicate metadata detection (same device/location)
  - Timeline visualization (photos on map/calendar)
  - Anomaly detection (unusual or suspicious metadata)

**Use Cases**:
- Security auditors checking for data leakage before publication
- Photographers analyzing their shooting patterns
- Organizations ensuring privacy compliance
- Journalists protecting sources

---

### 3. Advanced Batch Operations
**Status**: Not Started
**Estimated Effort**: Medium-High
**User Value**: High

Enhance batch processing with more control and flexibility.

**Potential Implementation**:
- **Batch Rename Patterns**:
  - Date-based: `YYYY-MM-DD_original-name.jpg`
  - Sequential: `photo_001.jpg`, `photo_002.jpg`
  - Custom templates with variables: `{date}_{camera}_{sequence}`
- **Preserve Directory Structure**:
  - Option to maintain source folder hierarchy in output
  - Flatten structure option
- **Format Conversion in Batch**:
  - Convert all HEIC to JPEG while removing metadata
  - Bulk format conversion with quality settings
- **Batch Profiles/Presets**:
  - Save favorite settings for different use cases
  - Profiles: "Social Media", "Web Publishing", "Archival", "Professional"
  - Quick-apply presets from UI
- **Resume Interrupted Jobs**:
  - Save state if batch processing fails mid-way
  - Resume from last successful file
  - Persistent batch queue

**Use Cases**:
- Processing hundreds of vacation photos with consistent naming
- Converting iPhone HEIC images to web-friendly JPEG in bulk
- Professional photographers with standardized workflows
- Handling large archives without worrying about interruptions

---

## Priority Tier 2: Good Value, Lower Effort

### 4. Image Comparison Enhancements
**Status**: Not Started
**Estimated Effort**: Low-Medium
**User Value**: Medium

Improve the existing before/after comparison view with better interaction.

**Potential Implementation**:
- **Visual Diff Highlighting**:
  - Show exactly which metadata was removed in highlighted list
  - Red/green indicators for removed fields
- **File Size Comparison**:
  - Display size reduction after metadata removal
  - Show percentage savings
  - Estimate storage saved for batch operations
- **Interactive Comparison**:
  - Slider to swipe between before/after
  - Zoom and pan sync (both images zoom together)
  - Split-screen with adjustable divider
- **Metadata Side-by-Side**:
  - Two-column view showing original vs cleaned metadata
  - Highlight differences
  - Export comparison report

**Use Cases**:
- Users wanting to verify exactly what was removed
- Understanding storage savings from metadata removal
- Detailed inspection of changes before committing

---

### 5. Format & Compression Options
**Status**: Not Started
**Estimated Effort**: Low-Medium
**User Value**: Medium

Provide more control over output format and quality settings.

**Potential Implementation**:
- **Custom Quality Settings**:
  - Per-format quality sliders (not just fixed 95%)
  - Preview file size impact in real-time
  - Quality presets: Low/Medium/High/Maximum/Lossless
- **Smart Compression**:
  - Automatically optimize file size while preserving visual quality
  - AI-powered quality assessment
  - Target file size mode
- **Flexible Output Format**:
  - Choose output format independently from input
  - Format conversion: HEIC → PNG, TIFF → JPEG, etc.
  - Multi-format output (save as JPEG and PNG simultaneously)
- **Lossless Mode**:
  - Guarantee no quality loss for supported formats
  - Warning when lossless isn't possible
- **Advanced Options**:
  - Color profile handling (preserve/remove/convert)
  - Resize images while cleaning metadata
  - Strip embedded thumbnails option

**Use Cases**:
- Users needing smaller files for web publishing
- Professionals requiring specific quality levels
- Users wanting PNG for archival but JPEG for sharing
- Optimizing for specific platforms (Instagram, Facebook, etc.)

---

### 6. User Experience Improvements
**Status**: Not Started
**Estimated Effort**: Low
**User Value**: Medium

Polish the workflow and add convenience features.

**Potential Implementation**:
- **Recent Files List**:
  - Quick access to recently processed images
  - Reopen recent with one click
  - Clear recent history option
- **Favorites/Bookmarks**:
  - Mark frequently used folders
  - Quick access sidebar
  - Project workspaces
- **Enhanced Image Selection**:
  - Grid view for batch selection with thumbnails
  - Multi-select with checkboxes
  - Filter by file type, size, date
- **Visual Polish**:
  - Dark mode toggle (independent of system preference)
  - Custom accent colors
  - Adjustable panel sizes (save layout preference)
- **Window Management**:
  - Multi-window support for comparing multiple images
  - Tabbed interface option
  - Picture-in-picture preview
- **Performance**:
  - Background processing with progress notifications
  - Faster metadata extraction for large batches
  - Memory optimization for large images

**Use Cases**:
- Power users processing many files daily
- Users wanting customized workflows
- Improved accessibility and comfort

---

## Priority Tier 3: Specialized/Advanced Features

### 7. Integration Features
**Status**: Not Started
**Estimated Effort**: Medium-High
**User Value**: Medium (High for specific users)

Integrate Scramble with system and other tools.

**Potential Implementation**:
- **Context Menu Integration**:
  - Right-click images in file manager → "Remove Metadata with Scramble"
  - Send to Scramble option
  - Quick actions in context menu
- **Watch Folder**:
  - Automatically process images added to monitored folder
  - Hot folder workflow
  - Configurable rules per watched folder
- **Cloud Storage Support**:
  - Direct processing from/to cloud services via GNOME Online Accounts
  - Google Drive, Nextcloud, OneDrive integration
  - Auto-clean before upload option
- **Nautilus Extension**:
  - Show metadata privacy status in file manager
  - Emblem for images with/without metadata
  - Column showing metadata presence
- **Command-Line Interface**:
  - Scriptable batch processing: `scramble clean --input dir/ --output out/`
  - Automation and integration with scripts
  - CI/CD pipeline integration
- **Portal Integration**:
  - Native file picker integration
  - Better sandboxing support
  - Share target registration

**Use Cases**:
- Users who want to clean images before uploading to cloud
- Automated workflows in photography studios
- Integration with existing file management habits
- System administrators deploying organization-wide privacy tools

---

### 8. Metadata Templates & Watermarking
**Status**: Not Started
**Estimated Effort**: Medium
**User Value**: Medium (High for professionals)

Add ability to apply custom metadata and visual watermarks.

**Potential Implementation**:
- **Metadata Templates**:
  - Create reusable templates with copyright, author, license info
  - Apply template when saving cleaned images
  - Template library with import/export
  - Quick-apply from dropdown
- **Watermark Overlay**:
  - Add text watermarks with customizable:
    - Font, size, color, opacity
    - Position (corners, center, tiled)
    - Rotation and effects
  - Add image watermarks (logo overlay)
  - Batch watermarking with same settings
- **Attribution Preservation**:
  - Keep only copyright/license while removing personal data
  - Smart preservation of Creative Commons metadata
  - License management
- **Bulk Operations**:
  - Add consistent copyright to entire batch
  - Apply organization branding
  - Standardized metadata for publication

**Use Cases**:
- Professional photographers protecting their work
- Organizations adding branding to published images
- Content creators maintaining attribution while protecting privacy
- Stock photographers preparing images for distribution

---

### 9. Advanced File Handling
**Status**: Not Started
**Estimated Effort**: Medium-High
**User Value**: Medium

Handle more complex file operations and formats.

**Potential Implementation**:
- **Recursive Folder Processing**:
  - Process entire directory trees
  - Maintain or flatten directory structure
  - Skip already-processed files
- **Advanced File Filtering**:
  - Include/exclude files by:
    - Pattern (wildcards, regex)
    - Date range (created, modified, EXIF date)
    - Metadata criteria (has GPS, camera model, etc.)
    - File size range
  - Preview filtered results before processing
- **Undo/History System**:
  - Maintain history of processed files
  - Undo last operation
  - Revert to original from backup
  - Processing history log
- **Safety Features**:
  - Automatic backup before modifying
  - Quarantine suspicious files
  - Dry-run mode (preview without changes)
- **RAW Format Support**:
  - Handle CR2, NEF, DNG, ARW files
  - Read-only metadata view for RAW
  - Extract JPEG preview from RAW
  - Process sidecar files
- **Archive Support**:
  - Process images inside ZIP/TAR archives
  - Create cleaned image archives
  - Batch process from multiple archives

**Use Cases**:
- Processing entire photo archives
- Professional photographers working with RAW files
- Safety-conscious users wanting backups
- Forensic analysis requiring history tracking

---

### 10. Privacy & Security Enhancements
**Status**: Not Started
**Estimated Effort**: Medium-High
**User Value**: Medium (High for security-focused users)

Go beyond current security foundation with advanced privacy features.

**Potential Implementation**:
- **Steganography Detection**:
  - Scan for hidden data in images
  - Warn if steganographic signatures detected
  - Statistical analysis for hidden content
- **Thumbnail Cleanup**:
  - Remove embedded thumbnails that might leak cropped content
  - Detect and warn about thumbnail metadata
  - Preview thumbnail before removal
- **Metadata Anomaly Detection**:
  - Flag unusual or suspicious metadata
  - Detect inconsistencies (date mismatches, impossible GPS)
  - Warn about potentially forged metadata
- **Privacy Report Generation**:
  - Pre-processing analysis of privacy risks in selected files
  - Detailed report of sensitive data found
  - Recommendations for safe sharing
- **Secure Operations**:
  - Secure deletion of original files (shred)
  - Encrypted temporary storage
  - Memory-only processing option (no temp files)
- **Compliance Tools**:
  - GDPR compliance checking
  - Generate privacy compliance reports
  - Audit trail of all operations

**Use Cases**:
- Security researchers analyzing images
- Journalists protecting sources
- Privacy-conscious users wanting maximum protection
- Legal compliance for organizations
- Forensic investigation support

---

### 11. Educational & Transparency Features
**Status**: Not Started
**Estimated Effort**: Low-Medium
**User Value**: Low-Medium

Help users understand metadata and privacy implications.

**Potential Implementation**:
- **Privacy Tips & Education**:
  - Educational tooltips explaining metadata privacy risks
  - "Did you know?" messages about specific metadata types
  - Privacy best practices guide
  - Interactive tutorial on first launch
- **"What's This?" Mode**:
  - Click any metadata field for detailed explanation
  - Learn about EXIF tags, GPS coordinates, camera settings
  - Links to external resources
- **Demo Mode**:
  - Load sample images to explore features
  - Interactive walkthrough
  - Safe experimentation without real files
- **Metadata Dictionary**:
  - Searchable reference of common metadata tags
  - Explanations in plain language
  - Privacy implications of each tag type
- **Detailed Change Logs**:
  - Show exactly what was modified per image
  - Human-friendly format
  - Export operation log
- **Privacy Blog/Tips**:
  - Built-in privacy news and tips
  - Update with best practices
  - Community contributions

**Use Cases**:
- New users learning about metadata privacy
- Educational settings teaching digital privacy
- Users wanting to understand their data
- Building awareness of privacy risks

---

### 12. Advanced Export Options
**Status**: Not Started
**Estimated Effort**: Low-Medium
**User Value**: Low-Medium

Enhance metadata export capabilities beyond basic JSON/CSV.

**Potential Implementation**:
- **XMP Sidecar Export**:
  - Save metadata as separate XMP files
  - Industry-standard format for metadata backup
  - Reimport sidecar files
- **HTML Gallery Export**:
  - Create browsable static HTML gallery
  - Thumbnail view with metadata details
  - Fully offline, self-contained
- **Markdown Export**:
  - Human-readable format for documentation
  - Good for Git repositories
  - Easy to diff and version control
- **Diff Export**:
  - Show before/after metadata changes
  - Side-by-side comparison document
  - Highlight removed fields
- **Archive Creation**:
  - Package images + metadata reports into ZIP
  - Include processing logs
  - Self-documenting archives
- **Database Export**:
  - SQLite database with searchable metadata
  - Query interface for analysis
  - Import into other tools

**Use Cases**:
- Forensic analysis and documentation
- Creating metadata backups before cleaning
- Sharing metadata analysis with others
- Research and data analysis
- Compliance documentation

---

## Feature Requests from Users

*This section will track feature requests from actual users*

### Community Requests
- *None yet - add requests as they come in*

### GitHub Issues
- *Track GitHub issue numbers here*

---

## Completed Features ✅

*Features that have been implemented will be moved here with completion date*

---

## Rejected/Deferred Features

*Features that have been considered but decided against, with reasoning*

### Deferred
- **Social Media Direct Upload**: Conflicts with privacy-first design principle of no network access
- **AI-Powered Image Recognition**: Out of scope, adds complexity and dependencies
- **Video Metadata Support**: Major scope expansion, consider for v2.0
- **Online Metadata Database**: Privacy concerns, conflicts with offline-first design

---

## Implementation Notes

### Development Principles
- Follow GNOME HIG (Human Interface Guidelines)
- Maintain privacy-first design philosophy
- No network access (offline-only operation)
- No data collection or telemetry
- Keep file size under 500 lines per module
- Comprehensive unit tests for new features
- Update README.md and documentation for user-facing features
- Use OpenSpec proposal system for major features

### Before Implementing
1. Check existing work: `openspec list`, `openspec list --specs`
2. Create OpenSpec proposal for major features
3. Update TASK.md with specific implementation tasks
4. Write tests before implementation (TDD approach)
5. Update documentation
6. Test with development build: `./build.sh --dev`

### Architecture Guidelines
- Core logic in `src/core/`
- UI dialogs in `src/dialogs/`
- Widgets in `src/widgets/`
- Utilities in `src/utils/`
- UI definitions in `data/ui/` (Blueprint format)
- Follow existing code patterns

---

## Version Planning

### v1.3.0 - User Control
*Target: Q1 2026*
- Selective metadata removal
- Custom quality settings
- Recent files list

### v1.4.0 - Analysis & Insights
*Target: Q2 2026*
- Privacy risk scoring
- Metadata statistics
- Batch reporting

### v1.5.0 - Advanced Workflows
*Target: Q3 2026*
- Batch presets
- Format conversion
- Advanced filtering

### v2.0.0 - Professional Features
*Target: Q4 2026+*
- Metadata templates
- Watermarking
- RAW format support
- Plugin system

---

## Contributing

If you'd like to implement any of these features:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
2. Create an OpenSpec proposal for major features
3. Open a GitHub issue to discuss the feature
4. Fork and create a feature branch
5. Submit a pull request

For questions or discussion about features, open a GitHub Discussion.

---

**Note**: This is a living document. Features may be added, removed, or reprioritized based on user feedback and project direction.

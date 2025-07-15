# Project Requirements and Planning (PRP)

## Scramble - Privacy-Focused Image Metadata Removal Tool

**Version**: 1.0  
**Date**: 2025-07-15  
**Application ID**: `io.github.tobagin.scramble`

---

## 1. Project Overview

### 1.1 Project Description
**Scramble** is a simple, privacy-focused utility for viewing and removing metadata from images. The application provides a clean, intuitive interface built with GTK4 and Libadwaita, featuring a user-friendly drag-and-drop workflow for metadata inspection and removal.

### 1.2 Project Goals
- Create a secure, offline-only metadata removal tool
- Provide an intuitive GTK4/Libadwaita interface
- Ensure non-destructive workflow (never modify original files)
- Deliver a distributable Flatpak application for the GNOME ecosystem
- Maintain privacy-first approach with zero data collection

### 1.3 Target Audience
- Privacy-conscious users
- Photographers and content creators
- General users sharing images online
- GNOME desktop environment users

---

## 2. Functional Requirements

### 2.1 Core Features

#### 2.1.1 Metadata Inspection
- **FR-01**: Display all readable metadata (EXIF, IPTC, XMP) in a clear, organized list
- **FR-02**: Support drag-and-drop image loading with large drop zone
- **FR-03**: Show image preview alongside metadata information
- **FR-04**: Display metadata in key-value pairs with clear formatting

#### 2.1.2 Metadata Removal
- **FR-05**: One-click metadata scrubbing functionality
- **FR-06**: Create clean copy of image without any metadata
- **FR-07**: Preserve original image quality during scrubbing process
- **FR-08**: User-controlled save location via file chooser dialog

#### 2.1.3 File Format Support
- **FR-09**: Primary support for JPEG and TIFF formats (Phase 1)
- **FR-10**: Extensible architecture for future format support (PNG, WebP, etc.)
- **FR-11**: Graceful handling of unsupported formats with clear error messages

### 2.2 User Interface Requirements

#### 2.2.1 Main Window
- **UI-01**: Large, prominent drag-and-drop area for image loading
- **UI-02**: Image preview pane with appropriate scaling
- **UI-03**: Metadata list view with scrollable interface
- **UI-04**: "Save Clean Copy" button with clear call-to-action
- **UI-05**: Welcome screen for first-time users

#### 2.2.2 Metadata Display
- **UI-06**: Organized metadata rows with key-value formatting
- **UI-07**: Expandable/collapsible metadata categories
- **UI-08**: Search/filter functionality for large metadata sets
- **UI-09**: Copy-to-clipboard functionality for metadata values

#### 2.2.3 User Experience
- **UX-01**: Clear visual distinction between "before" and "after" states
- **UX-02**: Non-ambiguous workflow with clear progress indicators
- **UX-03**: Responsive design adapting to different window sizes
- **UX-04**: Keyboard navigation support for accessibility

---

## 3. Technical Requirements

### 3.1 Technology Stack
- **Language**: Python 3.12
- **UI Toolkit**: GTK4 (version 4.19.3 via GNOME runtime)
- **Widget Library**: LibAdwaita (version 1.7 via GNOME runtime)
- **UI Definition**: Blueprint (using blueprint-compiler v0.18.0)
- **Build System**: Meson
- **Packaging**: Flatpak
- **Distribution**: Flathub

### 3.2 Core Dependencies
- **Pillow (PIL Fork)**: Primary image manipulation library
- **piexif**: Advanced EXIF metadata handling
- **PyGObject**: GTK4 Python bindings

### 3.3 Architecture Requirements

#### 3.3.1 Model-View-Controller Pattern
- **Model**: Pure Python business logic for metadata operations
- **View**: Blueprint-defined UI components with LibAdwaita styling
- **Controller**: Python GTK classes connecting model and view

#### 3.3.2 Security Requirements
- **SEC-01**: No network access (offline-only operation)
- **SEC-02**: Sandboxed Flatpak environment
- **SEC-03**: File access via Flatpak portals only
- **SEC-04**: No temporary file creation in world-readable locations
- **SEC-05**: Secure handling of image data in memory

---

## 4. System Architecture

### 4.1 File Structure
```
scramble/
├── data/
│   ├── io.github.tobagin.scramble.appdata.xml.in
│   ├── io.github.tobagin.scramble.desktop.in
│   ├── io.github.tobagin.scramble.gschema.xml
│   ├── icons/
│   │   ├── hicolor/
│   │   │   ├── scalable/
│   │   │   │   └── apps/
│   │   │   │       └── io.github.tobagin.scramble.svg
│   │   │   └── symbolic/
│   │   │       └── apps/
│   │   │           └── io.github.tobagin.scramble-symbolic.svg
│   ├── resources/
│   │   └── scramble.gresource.xml
│   └── ui/
│       ├── window.blp
│       ├── metadata_row.blp
│       └── preferences_dialog.blp
├── packaging/
│   ├── io.github.tobagin.scramble-local.yml
│   └── io.github.tobagin.scramble.yml
├── po/
│   ├── LINGUAS
│   └── scramble.pot
├── src/
│   ├── __main__.py
│   ├── main.py
│   ├── window.py
│   ├── metadata.py
│   ├── preferences_dialog.py
│   ├── scramble.in
│   └── _version.py
├── subprojects/
├── .gitignore
├── build.sh
├── meson.build
├── meson_post_install.py
├── PRP.md
└── README.md
```

### 4.2 Core Modules

#### 4.2.1 Main Application (`main.py`)
- Application entry point and lifecycle management
- GTK application initialization
- Resource loading and cleanup

#### 4.2.2 Main Window (`window.py`)
- Primary user interface controller
- Drag-and-drop event handling
- Image preview management
- Metadata display coordination

#### 4.2.3 Metadata Handler (`metadata.py`)
- Core metadata extraction logic
- Image processing and scrubbing operations
- File I/O operations with error handling
- Support for multiple metadata formats

#### 4.2.4 UI Components
- `window.blp`: Main window layout and structure
- `metadata_row.blp`: Individual metadata entry template
- `preferences_dialog.blp`: Application settings interface

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements
- **PERF-01**: Image loading response time < 2 seconds for files up to 50MB
- **PERF-02**: Metadata extraction < 1 second for typical image files
- **PERF-03**: Memory usage < 100MB for single image processing
- **PERF-04**: Startup time < 3 seconds on typical hardware

### 5.2 Usability Requirements
- **USE-01**: Intuitive interface requiring no user manual
- **USE-02**: Clear error messages with actionable guidance
- **USE-03**: Consistent with GNOME Human Interface Guidelines
- **USE-04**: Accessibility support (keyboard navigation, screen readers)

### 5.3 Reliability Requirements
- **REL-01**: Graceful handling of corrupted image files
- **REL-02**: No data loss during metadata removal process
- **REL-03**: Consistent behavior across different image formats
- **REL-04**: Proper error recovery and user notification

### 5.4 Compatibility Requirements
- **COMP-01**: GNOME 45+ runtime compatibility
- **COMP-02**: Support for Wayland and X11 display servers
- **COMP-03**: Cross-architecture support (x86_64, aarch64)
- **COMP-04**: Flatpak portal API compliance

---

## 6. Flatpak Packaging Requirements

### 6.1 Manifest Configuration
- **Runtime**: `org.gnome.Platform` version 48
- **SDK**: `org.gnome.Sdk` version 48
- **Command**: `scramble`
- **Finish Arguments**: Minimal permissions for file access and display

### 6.2 Build Modules
1. **blueprint-compiler**: GTK UI compilation
2. **python3-packages**: Vendored Python dependencies
3. **scramble**: Main application module

### 6.3 Distribution Strategy
- **Development**: Local manifest for rapid iteration
- **Production**: Tagged release manifest for Flathub submission
- **Build Script**: Automated build process with development/production modes

---

## 7. Privacy and Security Design

### 7.1 Privacy Principles
- **Zero Data Collection**: No user data, analytics, or telemetry
- **Offline Operation**: No network connectivity required or used
- **Local Processing**: All operations performed on local machine
- **Transparent Operation**: Clear documentation of all data handling

### 7.2 Security Measures
- **Sandboxed Environment**: Flatpak security model
- **Minimal Permissions**: Only essential file access permissions
- **Portal Integration**: Secure file access via system portals
- **Memory Safety**: Careful handling of image data in memory

### 7.3 Data Handling
- **Non-Destructive**: Original files never modified
- **Secure Cleanup**: Proper memory cleanup after operations
- **User Control**: User determines all file save locations
- **No Persistence**: No application data stored between sessions

---

## 8. Development Workflow

### 8.1 Build Process
1. **Development Build**: `./build.sh --dev --install`
2. **Production Build**: `./build.sh --force-clean`
3. **Testing**: `flatpak run io.github.tobagin.scramble`

### 8.2 Quality Assurance
- **Code Standards**: PEP 8 compliance for Python code
- **UI Standards**: GNOME Human Interface Guidelines
- **Testing**: Manual testing across different image formats
- **Documentation**: Comprehensive README and user documentation

### 8.3 Release Process
1. Version tagging and changelog updates
2. Production manifest testing
3. Flathub submission preparation
4. Community testing and feedback

---

## 9. Future Enhancements

### 9.1 Phase 2 Features
- **Additional Formats**: PNG, WebP, RAW format support
- **Batch Processing**: Multiple image processing capability
- **Metadata Editing**: Selective metadata modification
- **Reporting**: Metadata analysis and reporting features

### 9.2 Advanced Features
- **Metadata Templates**: Common metadata removal profiles
- **Integration**: GNOME Files integration
- **Automation**: Command-line interface for scripting
- **Plugins**: Extensible architecture for custom processors

---

## 10. Success Criteria

### 10.1 Technical Success
- Successful Flatpak build and installation
- Reliable metadata removal across supported formats
- Stable performance with various image sizes
- Zero security vulnerabilities in security review

### 10.2 User Experience Success
- Intuitive workflow requiring minimal learning
- Positive user feedback in initial testing
- Accessibility compliance verification
- Documentation completeness and clarity

### 10.3 Distribution Success
- Successful Flathub submission and approval
- Positive community reception
- Sustainable maintenance model
- Growth in user adoption

---

## 11. Risk Assessment

### 11.1 Technical Risks
- **Image Format Compatibility**: Mitigation through comprehensive testing
- **Performance Issues**: Mitigation through profiling and optimization
- **Dependency Conflicts**: Mitigation through vendored dependencies
- **Platform Compatibility**: Mitigation through CI/CD testing

### 11.2 User Experience Risks
- **Complexity**: Mitigation through user testing and iteration
- **Accessibility**: Mitigation through accessibility testing
- **Documentation**: Mitigation through clear documentation strategy

### 11.3 Distribution Risks
- **Flathub Approval**: Mitigation through compliance with guidelines
- **Maintenance**: Mitigation through sustainable development practices
- **Security**: Mitigation through security-first design principles

---

## 12. Conclusion

This PRP document provides a comprehensive roadmap for developing **Scramble**, a privacy-focused image metadata removal tool. The project emphasizes user privacy, security, and usability while leveraging modern GTK4 and Flatpak technologies for a robust, distributable application.

The document serves as the primary reference for development decisions, feature implementation, and quality assurance throughout the project lifecycle.
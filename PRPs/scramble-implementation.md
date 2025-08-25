name: "Scramble Implementation PRP - Complete GTK4 Image Metadata Removal Tool"
description: |
  Complete implementation of Scramble, a privacy-focused image metadata removal tool with GTK4/Libadwaita interface.
  This PRP provides comprehensive context and validation loops for successful one-pass implementation.

---

## Goal
Complete the implementation of Scramble - a privacy-focused utility for viewing and removing metadata from images with a clean GTK4/Libadwaita interface, packaged as a secure Flatpak application.

## Why
- **Privacy Protection**: Help users remove sensitive metadata from images before sharing online
- **User Experience**: Provide an intuitive drag-and-drop interface following GNOME HIG
- **Security**: Maintain non-destructive workflow that never modifies original files
- **Distribution**: Create a distributable Flatpak application for the GNOME ecosystem

## What
A complete GTK4 application that allows users to:
1. Drag and drop images to view all metadata (EXIF, IPTC, XMP)
2. Preview images alongside organized metadata display
3. Create clean copies without metadata via one-click save operation
4. Maintain secure, offline-only operation with sandboxed file access

### Success Criteria
- [ ] Functional drag-and-drop image loading
- [ ] Complete metadata extraction and display for JPEG/TIFF files
- [ ] Working save clean copy functionality with file chooser
- [ ] Successful Flatpak build and installation
- [ ] All UI components properly connected and responsive
- [ ] Error handling for unsupported formats and corrupted files

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Include these in your context window
- url: https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html
  why: JPEG/TIFF metadata handling, preservation/removal capabilities
  critical: Metadata preserved by default when saving - need explicit removal
  
- url: https://piexif.readthedocs.io/en/latest/
  why: EXIF API patterns (load/dump/remove), supported formats
  critical: Use piexif.remove() for clean metadata removal
  
- url: https://docs.gtk.org/gtk4/class.DropTarget.html
  why: Drag-and-drop implementation patterns for file handling
  critical: Handle GFile objects and connect to "drop" signal properly
  
- url: https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/class.StatusPage.html
  why: Welcome screen implementation patterns
  critical: Use for empty state before image is loaded

- file: /home/tobagin/Documents/Projects/Scramble/PLANNING.md
  why: Project architecture, naming conventions, build patterns
  critical: Follow MVC pattern, use Blueprint templates with @Gtk.Template

- file: /home/tobagin/Documents/Projects/Scramble/data/ui/window.blp
  why: Complete UI structure already defined with proper widget IDs
  critical: Use exact widget IDs (metadata_list, save_button, image_preview, etc.)

- file: /home/tobagin/Documents/Projects/Scramble/data/ui/metadata_row.blp
  why: Template for metadata display rows with copy functionality
  critical: Use MetadataRow class with key_name and value_text properties
```

### Current Codebase Tree
```bash
scramble/
├── data/
│   ├── ui/
│   │   ├── window.blp              # ✅ Complete UI layout
│   │   ├── metadata_row.blp        # ✅ Complete row template
│   │   └── preferences_dialog.blp  # ✅ Settings dialog
│   ├── icons/                      # ✅ Application icons
│   ├── resources/                  # ✅ GResource configuration
│   └── [desktop/appdata files]     # ✅ Complete metadata
├── packaging/
│   ├── *.yml                       # ✅ Flatpak manifests ready
├── src/
│   ├── main.py                     # ✅ Basic application structure
│   ├── window.py                   # ⚠️  INCOMPLETE - needs full implementation
│   ├── metadata.py                 # ⚠️  INCOMPLETE - needs error handling/formats
│   └── [other support files]      # ✅ Version, entry point ready
├── meson.build                     # ✅ Complete build configuration
└── build.sh                       # ✅ Ready build script
```

### Desired Codebase Tree (Files to Complete)
```bash
# FILES NEEDING IMPLEMENTATION:
src/window.py - Complete GTK window controller
  ├── Drag-and-drop event handling
  ├── Image preview loading and display
  ├── Metadata list population
  ├── Save button event handling
  ├── File chooser integration
  └── Error handling and user feedback

src/metadata.py - Enhanced metadata handler
  ├── Robust error handling for corrupted files
  ├── Support for JPEG and TIFF formats
  ├── Proper metadata formatting for display
  ├── Clean image saving without metadata
  └── Format validation and user feedback

# NEW FILES TO CREATE:
src/metadata_row.py - Metadata row widget class
  ├── Implement @Gtk.Template binding
  ├── Copy-to-clipboard functionality
  └── Property binding for key_name/value_text
```

### Known Gotchas & Library Quirks
```python
# CRITICAL: GTK4 Template Loading
# Templates must be loaded as resources, not file paths
# Use @Gtk.Template(resource_path='/path/to/resource') decorator

# CRITICAL: Pillow Metadata Preservation  
# By default, Pillow preserves metadata when saving
# For clean images, create new Image and copy pixel data only
# DON'T use img.save() directly - metadata will be preserved

# CRITICAL: piexif vs Pillow Integration
# piexif.load() can fail on corrupted EXIF data
# Always wrap in try/except and provide fallback
# Use piexif.remove() for reliable metadata stripping

# CRITICAL: GFile Drag-and-Drop
# DropTarget returns Gio.File objects, not string paths
# Use file.get_path() to get filesystem path
# Check if file.get_path() returns None (e.g., remote files)

# CRITICAL: Blueprint Template Compilation
# Templates compile to .ui files in build process
# Reference compiled .ui files in resource paths
# Widget IDs in Blueprint become accessible as template children

# CRITICAL: Flatpak File Permissions
# Limited filesystem access via portals
# File chooser automatically grants permission to selected files
# Drag-dropped files need user permission confirmation
```

## Implementation Blueprint

### Data Models and Structure
```python
# MetadataRow widget for displaying key-value pairs
@Gtk.Template(resource_path='/io/github/tobagin/scramble/ui/metadata_row.ui')
class MetadataRow(Adw.ActionRow):
    __gtype_name__ = 'MetadataRow'
    
    def __init__(self, key_name: str, value_text: str):
        super().__init__()
        self.props.title = key_name
        self.props.subtitle = value_text

# Enhanced metadata structure for organized display
MetadataSection = Dict[str, Dict[str, str]]  # section -> {key: value}
```

### List of Tasks (Implementation Order)

```yaml
Task 1 - Complete MetadataRow Widget:
MODIFY src/window.py:
  - ADD import for MetadataRow class
  
CREATE src/metadata_row.py:
  - IMPLEMENT @Gtk.Template decorator with resource path
  - ADD copy button signal handler
  - BIND key_name and value_text properties
  - MIRROR pattern from existing GTK4 composite templates

Task 2 - Complete Window Template Loading:
MODIFY src/window.py:
  - FIX @Gtk.Template resource path to compiled .ui file
  - ADD template children references for all widgets
  - IMPLEMENT proper super().__init__(**kwargs) call
  - PRESERVE existing MetadataHandler initialization

Task 3 - Implement Drag-and-Drop Handler:
MODIFY src/window.py in on_drop method:
  - ADD Gio.File path validation (check get_path() != None)
  - ADD file format validation before processing
  - ADD error handling for permission denied
  - REPLACE stub with complete image loading flow

Task 4 - Complete Image Preview Loading:
MODIFY src/window.py in load_image method:
  - ADD GdkPixbuf loading for image preview
  - ADD image scaling and fit-to-container logic
  - ADD toggle visibility of welcome_page vs image_preview
  - ADD error handling for unsupported image formats

Task 5 - Implement Metadata Display:
MODIFY src/window.py in update_metadata_display method:
  - CLEAR existing metadata_list children
  - ITERATE through metadata sections (EXIF, GPS, etc.)
  - CREATE MetadataRow widgets for each key-value pair
  - ADD rows to metadata_list with proper organization

Task 6 - Complete Save Clean Copy:
MODIFY src/window.py in on_save_clean_copy method:
  - ADD Gtk.FileChooserNative dialog for save location
  - ADD file extension handling (.jpg, .tiff)
  - ADD MetadataHandler.remove_metadata call
  - ADD success/error toast notifications

Task 7 - Enhance Metadata Handler:
MODIFY src/metadata.py:
  - IMPROVE extract_metadata error handling
  - ADD support for both piexif and Pillow metadata
  - ADD metadata section organization (EXIF/GPS/etc.)
  - FIX remove_metadata to use piexif.remove() for reliability

Task 8 - Add UI Event Bindings:
MODIFY src/window.py __init__ method:
  - CONNECT save_button "clicked" signal to on_save_clean_copy
  - CONNECT drag-and-drop events to proper handlers
  - ADD keyboard shortcut support (Ctrl+S for save)
  - ENABLE save_button only when image is loaded

Task 9 - Complete Resource Loading:
MODIFY data/resources/scramble.gresource.xml:
  - VERIFY all .ui files are included in resources
  - ENSURE proper resource paths match code references
  - ADD any missing UI files to resource compilation

Task 10 - Final Integration Testing:
TEST complete application workflow:
  - BUILD using ./build.sh --dev --install
  - VERIFY drag-and-drop functionality
  - TEST metadata display for various image types
  - CONFIRM save functionality works correctly
```

### Critical Implementation Details per Task

```python
# Task 2: Template Loading Pattern
@Gtk.Template(resource_path='/io/github/tobagin/scramble/ui/window.ui')
class ScrambleWindow(Adw.ApplicationWindow):
    __gtype_name__ = 'ScrambleWindow'
    
    # Template children - must match Blueprint widget IDs
    metadata_list = Gtk.Template.Child()
    save_button = Gtk.Template.Child()
    image_preview = Gtk.Template.Child()
    welcome_page = Gtk.Template.Child()
    toast_overlay = Gtk.Template.Child()

# Task 3: Drag-and-Drop Implementation
def on_drop(self, drop_target, value, x, y):
    if isinstance(value, Gio.File):
        file_path = value.get_path()
        if file_path and self.metadata_handler.is_supported_format(file_path):
            self.load_image(file_path)
            return True
        else:
            self.show_error_toast("Unsupported file format")
    return False

# Task 5: Metadata Display Pattern
def update_metadata_display(self, metadata: Dict[str, Any]):
    # Clear existing rows
    while child := self.metadata_list.get_first_child():
        self.metadata_list.remove(child)
    
    # Add metadata rows by section
    for section_name, section_data in metadata.items():
        if isinstance(section_data, dict):
            for key, value in section_data.items():
                row = MetadataRow(key, str(value))
                self.metadata_list.append(row)

# Task 6: File Chooser Pattern
def on_save_clean_copy(self, button):
    dialog = Gtk.FileChooserNative.new(
        title="Save Clean Image",
        parent=self,
        action=Gtk.FileChooserAction.SAVE
    )
    dialog.connect("response", self.on_save_response)
    dialog.show()

# Task 7: Reliable Metadata Removal
def remove_metadata(self, input_path: str, output_path: str) -> bool:
    try:
        # Use piexif for reliable EXIF removal
        piexif.remove(input_path, output_path)
        return True
    except Exception as e:
        # Fallback to Pillow method
        with Image.open(input_path) as img:
            # Create clean copy without metadata
            clean_img = Image.new(img.mode, img.size)
            clean_img.putdata(list(img.getdata()))
            clean_img.save(output_path, optimize=True, quality=95)
        return True
```

### Integration Points
```yaml
RESOURCES:
  - verify: data/resources/scramble.gresource.xml includes all .ui files
  - ensure: resource paths match @Gtk.Template decorators
  
UI_BINDINGS:
  - connect: All Blueprint widget IDs to template children
  - implement: Signal handlers for user interactions
  
ERROR_HANDLING:
  - add: Toast notifications for user feedback
  - implement: Graceful fallbacks for corrupted files
  
FILE_ACCESS:
  - use: Flatpak portals for secure file operations
  - implement: Permission handling for drag-dropped files
```

## Validation Loop

### Level 1: Syntax & Style
```bash
# Run these FIRST - fix any errors before proceeding
cd /home/tobagin/Documents/Projects/Scramble

# Python syntax and imports
python3 -m py_compile src/main.py
python3 -m py_compile src/window.py  
python3 -m py_compile src/metadata.py

# Expected: No compilation errors. If errors, READ and fix syntax issues.
```

### Level 2: Blueprint Compilation
```bash
# Test Blueprint to UI compilation
cd /home/tobagin/Documents/Projects/Scramble
meson setup builddir
meson compile -C builddir

# Expected: Successful compilation of .blp to .ui files
# If errors: Check Blueprint syntax and widget references
```

### Level 3: Flatpak Build Test
```bash
# Test complete application build
cd /home/tobagin/Documents/Projects/Scramble
./build.sh --dev --force-clean

# Expected: Successful Flatpak build without errors
# If errors: Check dependencies, manifests, and build configuration
```

### Level 4: Functional Testing
```bash
# Install and test application
cd /home/tobagin/Documents/Projects/Scramble
./build.sh --dev --install

# Test complete workflow
flatpak run io.github.tobagin.scramble

# Manual Test Cases:
# 1. Application launches without errors
# 2. Welcome screen displays correctly
# 3. Drag-and-drop accepts JPEG/TIFF files
# 4. Image preview displays correctly
# 5. Metadata list populates with readable data
# 6. Save button becomes enabled after loading image
# 7. File chooser opens when clicking save
# 8. Clean copy saves successfully without metadata
```

### Level 5: Metadata Verification
```bash
# Verify metadata removal effectiveness
# After saving a clean copy through the app:

# Check original file has metadata
exiftool test_image.jpg | wc -l
# Expected: Multiple lines of metadata

# Check cleaned file has no metadata  
exiftool test_image_clean.jpg | wc -l
# Expected: Minimal lines (just file info, no EXIF/GPS data)
```

## Final Validation Checklist
- [ ] Application builds successfully: `./build.sh --dev`
- [ ] No Python syntax errors: `python3 -m py_compile src/*.py`
- [ ] Blueprint compilation works: `meson compile -C builddir`
- [ ] Application installs: `./build.sh --dev --install`
- [ ] Drag-and-drop functionality works
- [ ] Image preview displays correctly
- [ ] Metadata extraction and display works
- [ ] Save clean copy removes all metadata
- [ ] Error handling for unsupported formats
- [ ] Toast notifications provide user feedback
- [ ] UI follows GNOME HIG patterns

---

## Anti-Patterns to Avoid
- ❌ Don't use file paths directly with templates - use GResource paths
- ❌ Don't assume drag-dropped files are local - check get_path() return
- ❌ Don't save images with img.save() directly - metadata will persist
- ❌ Don't ignore piexif exceptions - provide graceful fallbacks
- ❌ Don't hardcode widget references - use template children
- ❌ Don't skip error handling for file operations
- ❌ Don't modify original files - maintain non-destructive workflow

## Confidence Score: 9/10
This PRP provides comprehensive context, specific implementation patterns from existing codebase, detailed validation loops, and addresses all known gotchas. The existing project structure and UI definitions significantly reduce implementation complexity. Success likelihood is high with careful attention to the validation steps.
import gi
import os

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Gio, Adw, GdkPixbuf
from scramble.metadata import MetadataHandler
from scramble.metadata_row import MetadataRow
from scramble.security_validators import create_security_validator
from scramble.security_hardening import get_security_hardening


@Gtk.Template(resource_path='/io/github/tobagin/scramble/window.ui')
class ScrambleWindow(Adw.ApplicationWindow):
    __gtype_name__ = 'ScrambleWindow'
    
    # Template children - must match Blueprint widget IDs
    toast_overlay = Gtk.Template.Child()
    welcome_page = Gtk.Template.Child()
    image_preview = Gtk.Template.Child()
    metadata_list = Gtk.Template.Child()
    save_button = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.metadata_handler = MetadataHandler()
        self.security_validator = create_security_validator()
        self.security_hardening = get_security_hardening()
        self.current_image_path = None
        self.current_metadata = None
        self.setup_drag_and_drop()
        self.setup_ui_bindings()
        self.setup_focus_management()

    def setup_drag_and_drop(self):
        """Setup drag and drop functionality for image files."""
        drop_target = Gtk.DropTarget.new(Gio.File, 0)
        drop_target.connect('drop', self.on_drop)
        self.add_controller(drop_target)
    
    def setup_ui_bindings(self):
        """Connect UI event handlers and keyboard shortcuts."""
        # Connect save button signal
        self.save_button.connect('clicked', self.on_save_clean_copy)
        
        # Add keyboard shortcut for save (Ctrl+S)
        shortcut_controller = Gtk.ShortcutController()
        save_shortcut = Gtk.Shortcut.new(
            Gtk.ShortcutTrigger.parse_string('<Control>s'),
            Gtk.CallbackAction.new(self.on_save_shortcut)
        )
        shortcut_controller.add_shortcut(save_shortcut)
        self.add_controller(shortcut_controller)

    def on_drop(self, drop_target, value, x, y):
        """Handle drag-and-drop events for image files."""
        if isinstance(value, Gio.File):
            file_path = value.get_path()
            if file_path:
                # Security validation for dropped file
                validation_result = self.security_validator.validate_file_security(file_path)
                if validation_result is not None:
                    error_msg = validation_result.get('error', 'File validation failed')
                    self.show_error_toast(_("Security validation failed: {}").format(error_msg))
                    return False
                
                # Additional format check
                if self.metadata_handler.is_supported_format(file_path):
                    self.load_image(file_path)
                    return True
                else:
                    self.show_error_toast(_("Unsupported file format. Please use JPEG or TIFF files."))
                    return False
            else:
                if file_path:
                    self.show_error_toast(_("Unsupported file format. Please use JPEG or TIFF files."))
                else:
                    self.show_error_toast(_("Cannot access the dropped file."))
        return False

    def load_image(self, file_path):
        """Load image file, display preview, and extract metadata."""
        try:
            self.current_image_path = file_path
            
            # Load and display image preview
            self.load_image_preview(file_path)
            
            # Extract and display metadata
            metadata = self.metadata_handler.extract_metadata(file_path)
            if 'error' in metadata:
                self.show_error_toast(_("Failed to read metadata: {}").format(metadata['error']))
                self.current_metadata = None
            else:
                self.current_metadata = metadata
                self.update_metadata_display(metadata)
                
            # Toggle UI state
            self.welcome_page.set_visible(False)
            self.image_preview.set_visible(True)
            self.save_button.set_sensitive(True)
            
        except Exception as e:
            self.show_error_toast(_("Error loading image: {}").format(str(e)))
            self.reset_ui_state()

    def load_image_preview(self, file_path):
        """Load and display image preview with proper scaling."""
        try:
            # Load image using GdkPixbuf
            pixbuf = GdkPixbuf.Pixbuf.new_from_file(file_path)
            
            # Set maximum size for preview
            max_width, max_height = 400, 400
            width, height = pixbuf.get_width(), pixbuf.get_height()
            
            # Calculate scaling to fit within bounds while maintaining aspect ratio
            if width > max_width or height > max_height:
                scale = min(max_width / width, max_height / height)
                new_width = int(width * scale)
                new_height = int(height * scale)
                pixbuf = pixbuf.scale_simple(new_width, new_height, GdkPixbuf.InterpType.BILINEAR)
            
            # Set the pixbuf to the image preview widget
            self.image_preview.set_pixbuf(pixbuf)
            
            # Update accessibility information
            filename = os.path.basename(file_path)
            alt_text = f"Preview of {filename} ({width}x{height} pixels)"
            if hasattr(self.image_preview, 'set_accessible_name'):
                self.image_preview.set_accessible_name(alt_text)
            
        except Exception as e:
            self.show_error_toast(_("Error loading image preview: {}").format(str(e)))
            
    def update_metadata_display(self, metadata):
        """Update the metadata list view with extracted metadata."""
        # Clear existing rows
        while child := self.metadata_list.get_first_child():
            self.metadata_list.remove(child)
        
        total_entries = 0
        
        # Add metadata rows by section
        for section_name, section_data in metadata.items():
            if isinstance(section_data, dict) and section_data:
                # Add section header
                section_header = Adw.ActionRow()
                section_header.set_title(f"{section_name.upper()} Data")
                section_header.add_css_class("property")
                # Accessibility for section headers
                if hasattr(section_header, 'set_accessible_role'):
                    section_header.set_accessible_role('heading')
                if hasattr(section_header, 'set_accessible_name'):
                    section_header.set_accessible_name(f"{section_name} section")
                self.metadata_list.append(section_header)
                
                # Add metadata entries
                for key, value in section_data.items():
                    if value:  # Only show non-empty values
                        row = MetadataRow(key, str(value))
                        self.metadata_list.append(row)
                        total_entries += 1
        
        # If no metadata found, show a message
        if total_entries == 0:
            no_data_row = Adw.ActionRow()
            no_data_row.set_title(_("No metadata found"))
            no_data_row.set_subtitle(_("This image does not contain readable metadata"))
            if hasattr(no_data_row, 'set_accessible_name'):
                no_data_row.set_accessible_name(_("No metadata found in this image"))
            self.metadata_list.append(no_data_row)
        
        # Announce to screen readers
        announcement = _("Loaded {} metadata entries").format(total_entries) if total_entries > 0 else _("No metadata found")
        self.announce_to_screen_reader(announcement)

    def on_save_clean_copy(self, button):
        """Open file chooser and save a clean copy without metadata."""
        if not self.current_image_path:
            return
            
        # Create file chooser dialog
        dialog = Gtk.FileChooserNative.new(
            title=_("Save Clean Image"),
            parent=self,
            action=Gtk.FileChooserAction.SAVE
        )
        
        # Set default filename
        original_name = os.path.basename(self.current_image_path)
        name_without_ext, ext = os.path.splitext(original_name)
        default_name = f"{name_without_ext}_clean{ext}"
        dialog.set_current_name(default_name)
        
        # Add file filters
        jpeg_filter = Gtk.FileFilter()
        jpeg_filter.set_name(_("JPEG Images"))
        jpeg_filter.add_mime_type("image/jpeg")
        jpeg_filter.add_pattern("*.jpg")
        jpeg_filter.add_pattern("*.jpeg")
        dialog.add_filter(jpeg_filter)
        
        tiff_filter = Gtk.FileFilter()
        tiff_filter.set_name(_("TIFF Images"))
        tiff_filter.add_mime_type("image/tiff")
        tiff_filter.add_pattern("*.tiff")
        tiff_filter.add_pattern("*.tif")
        dialog.add_filter(tiff_filter)
        
        all_filter = Gtk.FileFilter()
        all_filter.set_name(_("All Files"))
        all_filter.add_pattern("*")
        dialog.add_filter(all_filter)
        
        # Connect response signal and show dialog
        dialog.connect("response", self.on_save_response)
        dialog.show()
    
    def on_save_response(self, dialog, response):
        """Handle file chooser response and save the clean image."""
        if response == Gtk.ResponseType.ACCEPT:
            output_path = dialog.get_file().get_path()
            
            if output_path:
                # Save clean copy without metadata
                success = self.metadata_handler.remove_metadata(
                    self.current_image_path, output_path
                )
                
                if success:
                    self.show_success_toast(_("Clean image saved to {}").format(os.path.basename(output_path)))
                else:
                    self.show_error_toast(_("Failed to save clean image"))
            else:
                self.show_error_toast(_("Invalid save location"))
        
        dialog.destroy()
    
    def on_save_shortcut(self, widget, args):
        """Handle Ctrl+S keyboard shortcut."""
        if self.save_button.get_sensitive():
            self.on_save_clean_copy(self.save_button)
        return True
    
    def show_error_toast(self, message):
        """Show error toast notification."""
        toast = Adw.Toast.new(message)
        toast.set_timeout(3)
        self.toast_overlay.add_toast(toast)
    
    def show_success_toast(self, message):
        """Show success toast notification."""
        toast = Adw.Toast.new(message)
        toast.set_timeout(2)
        self.toast_overlay.add_toast(toast)
    
    def announce_to_screen_reader(self, message):
        """Announce a message to screen readers."""
        try:
            # Create a very brief toast for screen reader announcement
            toast = Adw.Toast.new(message)
            toast.set_timeout(1)  # Very short timeout, just for screen reader
            self.toast_overlay.add_toast(toast)
        except Exception:
            # Fallback: just log the message
            print(f"Screen reader announcement: {message}")
    
    def setup_focus_management(self):
        """Setup proper focus management for keyboard navigation."""
        # Make sure the metadata list can receive focus
        if hasattr(self.metadata_list, 'set_can_focus'):
            self.metadata_list.set_can_focus(True)
        
        # Set initial focus capabilities
        if hasattr(self.welcome_page, 'set_can_focus'):
            self.welcome_page.set_can_focus(True)
    
    def reset_ui_state(self):
        """Reset UI to initial state."""
        self.welcome_page.set_visible(True)
        self.image_preview.set_visible(False)
        self.save_button.set_sensitive(False)
        self.current_image_path = None
        self.current_metadata = None
        
        # Clear metadata list
        while child := self.metadata_list.get_first_child():
            self.metadata_list.remove(child)
        
        # Reset focus to welcome screen
        try:
            if hasattr(self.welcome_page, 'grab_focus'):
                self.welcome_page.grab_focus()
        except Exception:
            pass
        
        # Announce state change
        self.announce_to_screen_reader(_("Returned to welcome screen"))
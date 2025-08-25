import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw, Gdk, GObject


@Gtk.Template(resource_path='/io/github/tobagin/scramble/metadata_row.ui')
class MetadataRow(Adw.ActionRow):
    """A custom widget for displaying metadata key-value pairs with copy functionality."""
    
    __gtype_name__ = 'MetadataRow'
    
    # Template children
    copy_button = Gtk.Template.Child()
    
    # Properties for template binding
    key_name = GObject.Property(type=str, default='')
    value_text = GObject.Property(type=str, default='')
    
    def __init__(self, key_name: str = '', value_text: str = '', **kwargs):
        """Initialize MetadataRow with key-value pair.
        
        Args:
            key_name: The metadata key name to display
            value_text: The metadata value to display
        """
        super().__init__(**kwargs)
        self.props.key_name = key_name
        self.props.value_text = value_text
        
        # Update title and subtitle
        self.props.title = key_name
        self.props.subtitle = value_text
        
        # Connect copy button signal
        self.copy_button.connect('clicked', self.on_copy_clicked)
    
    def on_copy_clicked(self, button):
        """Copy the metadata value to clipboard when copy button is clicked."""
        clipboard = Gdk.Display.get_default().get_clipboard()
        clipboard.set_text(self.props.value_text)
        
        # Show visual feedback (could add toast notification here if needed)
        button.set_sensitive(False)
        GObject.timeout_add(1000, lambda: button.set_sensitive(True))
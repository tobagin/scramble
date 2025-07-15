import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Gio, Adw, GdkPixbuf
from scramble.metadata import MetadataHandler


@Gtk.Template(resource_path='/io/github/tobagin/scramble/ui/window.ui')
class ScrambleWindow(Adw.ApplicationWindow):
    __gtype_name__ = 'ScrambleWindow'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.metadata_handler = MetadataHandler()
        self.current_image_path = None
        self.setup_drag_and_drop()

    def setup_drag_and_drop(self):
        # Setup drag and drop functionality
        drop_target = Gtk.DropTarget.new(Gio.File, Gtk.DropTargetFlags.NONE)
        drop_target.connect('drop', self.on_drop)
        self.add_controller(drop_target)

    def on_drop(self, drop_target, value, x, y):
        if isinstance(value, Gio.File):
            self.load_image(value.get_path())
        return True

    def load_image(self, file_path):
        self.current_image_path = file_path
        # Load and display image preview
        # Extract and display metadata
        metadata = self.metadata_handler.extract_metadata(file_path)
        self.update_metadata_display(metadata)

    def update_metadata_display(self, metadata):
        # Update the metadata list view
        pass

    def on_save_clean_copy(self, button):
        if self.current_image_path:
            # Open file chooser for save location
            # Create clean copy without metadata
            pass
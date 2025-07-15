import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Adw


@Gtk.Template(resource_path='/io/github/tobagin/scramble/ui/preferences_dialog.ui')
class PreferencesDialog(Adw.PreferencesDialog):
    __gtype_name__ = 'PreferencesDialog'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.setup_preferences()
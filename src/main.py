import gi
import locale
import gettext

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Gio, Adw
from scramble.window import ScrambleWindow
from scramble.security_hardening import cleanup_security


class ScrambleApplication(Adw.Application):
    def __init__(self):
        super().__init__(application_id='io.github.tobagin.scramble',
                         flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        win = self.props.active_window
        if not win:
            win = ScrambleWindow(application=self)
        win.present()

    def do_startup(self):
        Adw.Application.do_startup(self)
        
        # Set up internationalization
        try:
            locale.setlocale(locale.LC_ALL, '')
        except locale.Error:
            pass
        
        gettext.textdomain('scramble')
        gettext.bindtextdomain('scramble', '/usr/share/locale')
        
        # Make gettext available globally
        import builtins
        builtins._ = gettext.gettext


def main():
    app = ScrambleApplication()
    try:
        return app.run()
    finally:
        # Cleanup security resources on exit
        cleanup_security()
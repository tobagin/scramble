import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Gio, Adw
from scramble.window import ScrambleWindow


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


def main():
    app = ScrambleApplication()
    return app.run()
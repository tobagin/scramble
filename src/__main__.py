import sys
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gio
from scramble import main

if __name__ == '__main__':
    app = main.ScrambleApplication()
    app.run(sys.argv)
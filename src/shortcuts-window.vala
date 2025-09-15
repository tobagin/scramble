using Gtk;
using Adw;

namespace Scramble {

#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/scramble/Devel/shortcuts-window.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/scramble/shortcuts-window.ui")]
#endif
    public class ShortcutsWindow : Adw.Dialog {

        public ShortcutsWindow(Gtk.Window parent) {
            Object();
        }
    }
}
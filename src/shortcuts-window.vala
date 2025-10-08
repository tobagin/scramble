using Gtk;
using Adw;

namespace Scramble {
    /**
     * Creates and shows a keyboard shortcuts dialog using Builder
     */
    public class ShortcutsWindow : Object {

        public static void show(Gtk.Window parent) {
            var builder = new Gtk.Builder();

            try {
#if DEVELOPMENT
                builder.add_from_resource("/io/github/tobagin/scramble/Devel/shortcuts-window.ui");
#else
                builder.add_from_resource("/io/github/tobagin/scramble/shortcuts-window.ui");
#endif
                var shortcuts_dialog = builder.get_object("shortcuts_window") as Adw.ShortcutsDialog;
                if (shortcuts_dialog != null) {
                    shortcuts_dialog.present(parent);
                }
            } catch (Error e) {
                warning("Failed to load shortcuts dialog: %s", e.message);
            }
        }
    }
}

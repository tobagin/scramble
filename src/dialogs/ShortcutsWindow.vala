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
                builder.add_from_resource("/io/github/tobagin/scramble/Devel/shortcuts_window.ui");
#else
                builder.add_from_resource("/io/github/tobagin/scramble/shortcuts_window.ui");
#endif
                var shortcuts_dialog = builder.get_object("shortcuts_window") as Gtk.ShortcutsWindow;
                if (shortcuts_dialog != null) {
                    shortcuts_dialog.set_transient_for(parent);
                    shortcuts_dialog.present();
                }
            } catch (Error e) {
                warning("Failed to load shortcuts dialog: %s", e.message);
            }
        }
    }
}

using Gtk;

namespace Scramble {
    /**
     * Creates and shows a keyboard shortcuts window using Builder
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
                var shortcuts_window = builder.get_object("shortcuts_window") as Gtk.ShortcutsWindow;
                if (shortcuts_window != null) {
                    shortcuts_window.set_transient_for(parent);
                    shortcuts_window.present();
                }
            } catch (Error e) {
                warning("Failed to load shortcuts window: %s", e.message);
            }
        }
    }
}

using Gtk;
using Adw;

namespace Scramble {

#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/scramble/Devel/preferences_dialog.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/scramble/preferences_dialog.ui")]
#endif
    public class Preferences : Adw.PreferencesDialog {
        [GtkChild] private unowned Gtk.SpinButton quality_spin;
        [GtkChild] private unowned Adw.SwitchRow preserve_timestamps;
        [GtkChild] private unowned Gtk.Switch secure_memory_switch;

        private GLib.Settings settings;

        public Preferences() {
            Object();
            settings = new GLib.Settings(Config.APP_ID);

            // Bind settings
            settings.bind("image-quality", quality_spin, "value", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("preserve-timestamps", preserve_timestamps, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("secure-memory", secure_memory_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        }
    }
}

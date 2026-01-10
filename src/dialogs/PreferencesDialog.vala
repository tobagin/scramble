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
        
        // Metadata removal switches
        [GtkChild] private unowned Adw.SwitchRow remove_gps_switch;
        [GtkChild] private unowned Adw.SwitchRow remove_camera_switch;
        [GtkChild] private unowned Adw.SwitchRow remove_datetime_switch;
        [GtkChild] private unowned Adw.SwitchRow remove_software_switch;
        [GtkChild] private unowned Adw.SwitchRow remove_author_switch;

        private GLib.Settings settings;

        public Preferences() {
            Object();
            settings = new GLib.Settings(Config.APP_ID);

            // Bind settings
            settings.bind("image-quality", quality_spin, "value", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("preserve-timestamps", preserve_timestamps, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("secure-memory", secure_memory_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            
            // Bind metadata removal settings
            settings.bind("remove-gps", remove_gps_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("remove-camera", remove_camera_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("remove-datetime", remove_datetime_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("remove-software", remove_software_switch, "active", GLib.SettingsBindFlags.DEFAULT);
            settings.bind("remove-author", remove_author_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        }
    }
}

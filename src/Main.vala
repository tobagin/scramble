using Gtk;
using Adw;

namespace Scramble {
    public class Application : Adw.Application {
        private Window? main_window = null;
        private GLib.Settings? settings = null;

        public Application() {
            Object(application_id: Config.APP_ID,
                   flags: GLib.ApplicationFlags.HANDLES_OPEN);
        }

        protected override void startup() {
            base.startup();

            // i18n
            GLib.Intl.setlocale(GLib.LocaleCategory.ALL, "");
            GLib.Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            GLib.Intl.textdomain(Config.GETTEXT_PACKAGE);

            // Initialize Settings now that GTK is initialized
            settings = new GLib.Settings(Config.APP_ID);

            // Actions for app menu
            var act_prefs = new GLib.SimpleAction("preferences", null);
            act_prefs.activate.connect((param) => {
                var win = this.active_window as Window;
                if (win == null) {
                    win = new Window(this);
                }
                var dlg = new Preferences();
                dlg.present(win);
            });
            this.add_action(act_prefs);

            var act_about = new GLib.SimpleAction("about", null);
            act_about.activate.connect((param) => {
                AboutDialog.show(this.active_window);
            });
            this.add_action(act_about);

            var act_quit = new GLib.SimpleAction("quit", null);
            act_quit.activate.connect((param) => {
                this.quit();
            });
            this.add_action(act_quit);
        }


        protected override void activate() {
            // Create window if it doesn't exist
            if (main_window == null) {
                main_window = new Window(this);
                main_window.present();

                // Check if we should show What's New dialog
                check_and_show_whats_new();
            } else {
                // Show the existing window (it might be hidden)
                main_window.set_visible(true);
                main_window.present();
            }
        }

        protected override void open(GLib.File[] files, string hint) {
            activate();

            // Open the first supported file
            foreach (var file in files) {
                string? path = file.get_path();
                if (path != null) {
                    main_window.load_image(path);
                    // We only support opening one file at a time for now
                    break;
                }
            }
        }

        private void check_and_show_whats_new() {
            // Check if this is a new version and show release notes automatically
            if (should_show_release_notes()) {
                // Small delay to ensure main window is fully presented
                Timeout.add(500, () => {
                    if (main_window != null && !main_window.in_destruction()) {
                        AboutDialog.show_with_release_notes(main_window);
                    }
                    return false;
                });
            }
        }

        private bool should_show_release_notes() {
            if (settings == null) {
                return false;
            }

            try {
                string last_version = settings.get_string("last-version-shown");
                string current_version = Config.VERSION;

                // Show if this is the first run (empty last version) or version has changed
                if (last_version == "" || last_version != current_version) {
                    settings.set_string("last-version-shown", current_version);
                    return true;
                }
            } catch (Error e) {
                warning("Failed to check last version shown: %s", e.message);
            }

            return false;
        }
    }

    public static int main(string[] args) {
        Gtk.init();
        var app = new Application();
        return app.run(args);
    }
}

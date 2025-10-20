using Gtk;
using Adw;
using GLib;

namespace Scramble {
    public class AboutDialog : Object {
        public static void show(Gtk.Window? parent) {
            string[] developers = { "Thiago Fernandes" };
            string[] designers = { "Thiago Fernandes" };
            string[] artists = { "Thiago Fernandes" };

            string app_name = "Scramble";
            string comments = "A GTK4/LibAdwaita application to view and remove metadata from images";

            if (Config.APP_ID.contains("Devel")) {
                app_name = "Scramble (Development)";
                comments = "A GTK4/LibAdwaita application to view and remove metadata from images (Development Version)";
            }

            var about = new Adw.AboutDialog() {
                application_name = app_name,
                application_icon = Config.APP_ID,
                developer_name = "The Scramble Team",
                version = Config.VERSION,
                developers = developers,
                designers = designers,
                artists = artists,
                license_type = Gtk.License.GPL_3_0,
                website = "https://tobagin.github.io/apps/scramble",
                issue_url = "https://github.com/tobagin/scramble/issues",
                support_url = "https://github.com/tobagin/scramble/discussions",
                comments = comments
            };

            // Load and set release notes from metainfo
            load_release_notes(about);

            // Set copyright
            about.set_copyright("© 2025 The Scramble Team");

            // Add acknowledgement section
            about.add_acknowledgement_section(
                "Special Thanks",
                {
                    "The GNOME Project",
                    "The GExiv2 Team",
                    "LibAdwaita Contributors",
                    "Vala Programming Language Team"
                }
            );

            // Set translator credits
            about.set_translator_credits("Thiago Fernandes");

            // Add Source link
            about.add_link("Source", "https://github.com/tobagin/scramble");

            if (parent != null && !parent.in_destruction()) {
                about.present(parent);
            }
        }

        public static void show_with_release_notes(Gtk.Window? parent) {
            // Open the about dialog first (regular method)
            show(parent);

            // Wait for the dialog to appear and be fully rendered
            Timeout.add(500, () => {
                simulate_tab_navigation();

                // Simulate Enter key press after another delay to open release notes
                Timeout.add(300, () => {
                    simulate_enter_activation();
                    return false;
                });
                return false;
            });
        }

        private static void load_release_notes(Adw.AboutDialog about) {
            try {
                string[] possible_paths = {
                    Path.build_filename("/app/share/metainfo", @"$(Config.APP_ID).metainfo.xml"),
                    Path.build_filename("/usr/share/metainfo", @"$(Config.APP_ID).metainfo.xml"),
                    Path.build_filename(Environment.get_user_data_dir(), "metainfo", @"$(Config.APP_ID).metainfo.xml")
                };

                foreach (string metainfo_path in possible_paths) {
                    var file = File.new_for_path(metainfo_path);

                    if (file.query_exists()) {
                        uint8[] contents;
                        file.load_contents(null, out contents, null);
                        string xml_content = (string) contents;

                        // Parse the XML to find the release matching Config.VERSION
                        var parser = new Regex("<release version=\"%s\"[^>]*>(.*?)</release>".printf(Regex.escape_string(Config.VERSION)),
                                               RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);
                        MatchInfo match_info;

                        if (parser.match(xml_content, 0, out match_info)) {
                            string release_section = match_info.fetch(1);

                            // Extract description content
                            var desc_parser = new Regex("<description>(.*?)</description>",
                                                        RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);
                            MatchInfo desc_match;

                            if (desc_parser.match(release_section, 0, out desc_match)) {
                                string release_notes = desc_match.fetch(1).strip();
                                about.set_release_notes(release_notes);
                                about.set_release_notes_version(Config.VERSION);
                            }
                        }
                        break;
                    }
                }
            } catch (Error e) {
                // If we can't load release notes from metainfo, that's okay
                warning("Could not load release notes from metainfo: %s", e.message);
            }
        }

        private static void simulate_tab_navigation() {
            // Get the currently focused window (should be the about dialog)
            var app = GLib.Application.get_default() as Gtk.Application;
            if (app != null) {
                var focused_window = app.get_active_window();
                if (focused_window != null) {
                    // Try multiple approaches to navigate to the release notes button
                    var success = focused_window.child_focus(Gtk.DirectionType.TAB_FORWARD);
                    if (!success) {
                        // For LibAdwaita dialogs, the focus should automatically navigate
                        // to the appropriate elements when tabbing
                    }
                }
            }
        }

        private static void simulate_enter_activation() {
            // Get the currently active window (should be the about dialog)
            var app = GLib.Application.get_default() as Gtk.Application;
            if (app != null) {
                var focused_window = app.get_active_window();
                if (focused_window != null) {
                    // Get the focused widget within the active window
                    var focused_widget = focused_window.get_focus();

                    if (focused_widget != null) {
                        // If it's a button, click it
                        if (focused_widget is Gtk.Button) {
                            ((Gtk.Button)focused_widget).activate();
                        }
                        // For other widgets, try to activate the default action
                        else {
                            focused_widget.activate_default();
                        }
                    } else {
                        // Try to activate the default widget of the window
                        if (focused_window is Gtk.Window) {
                            var default_widget = ((Gtk.Window)focused_window).get_default_widget();
                            if (default_widget != null) {
                                default_widget.activate();
                            }
                        }
                    }
                }
            }
        }

    }
}

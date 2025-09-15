using Gtk;
using Adw;

namespace Scramble {
    #if DEVELOPMENT
[GtkTemplate (ui = "/io/github/tobagin/scramble/Devel/metadata_row.ui")]
#else
[GtkTemplate (ui = "/io/github/tobagin/scramble/metadata_row.ui")]
#endif
    public class MetadataRow : Adw.ActionRow {
        [GtkChild] private unowned Gtk.Button copy_button;

        public string key_name { get; set; default = ""; }
        public string value_text { get; set; default = ""; }

        public MetadataRow(string key_name = "", string value_text = "") {
            Object();
            this.key_name = key_name;
            this.value_text = value_text;
            this.title = key_name;
            this.subtitle = value_text;

            copy_button.clicked.connect(() => {
                var display = Gdk.Display.get_default();
                if (display != null) {
                    var cb = display.get_clipboard();
                    cb.set_text(this.value_text);
                }
                copy_button.sensitive = false;
                GLib.Timeout.add(1000, () => { copy_button.sensitive = true; return GLib.Source.REMOVE; });
            });
        }

        public void set_icon(string icon_name) {
            this.add_prefix(new Gtk.Image.from_icon_name(icon_name));
        }

        public void update_value(string new_value) {
            this.value_text = new_value;
            this.subtitle = new_value;
        }
    }
}

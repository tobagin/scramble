using Gtk;
using Adw;
using Gdk;

namespace Scramble {
#if DEVELOPMENT
[GtkTemplate (ui = "/io/github/tobagin/scramble/Devel/window.ui")]
#else
[GtkTemplate (ui = "/io/github/tobagin/scramble/window.ui")]
#endif
public class Window : Adw.ApplicationWindow {
        [GtkChild] private unowned Adw.ToastOverlay toast_overlay;
        [GtkChild] private unowned Adw.StatusPage welcome_page;
        [GtkChild] private unowned Gtk.Box image_container;
        [GtkChild] private unowned Gtk.Picture image_preview;
        [GtkChild] private unowned Gtk.ListBox metadata_list;

        // Header bar buttons
        [GtkChild] private unowned Gtk.Button open_file_button_header;
        [GtkChild] private unowned Gtk.Button save_button_header;
        [GtkChild] private unowned Gtk.Button clear_button_header;
        [GtkChild] private unowned Gtk.Separator header_separator;

        private string? current_image_path;
        private GLib.Settings settings;
        private MetadataDisplay metadata_display;

        public Window(Adw.Application app) {
            Object(application: app);
            settings = new GLib.Settings(Config.APP_ID);

            // Setup actions and shortcuts
            setup_actions();

            // Setup drag and drop
            setup_drag_and_drop();

            // Initialize metadata display
            metadata_display = new MetadataDisplay(metadata_list);


            // Header bar buttons - connect to same functions
            open_file_button_header.clicked.connect(() => on_open_file_clicked());
            save_button_header.clicked.connect(() => on_save_clicked());
            clear_button_header.clicked.connect(() => on_clear_clicked());
        }

        private void setup_drag_and_drop() {
            var drop_target = new Gtk.DropTarget(typeof(GLib.File), Gdk.DragAction.COPY);
            drop_target.drop.connect(on_drop);

            // Use a more direct approach to avoid the add_controller issue
            var event_controller = drop_target as Gtk.EventController;
            if (event_controller != null) {
                var widget = this as Gtk.Widget;
                widget.add_controller(event_controller);
            }
        }

        private void setup_actions() {
            // Window actions
            var open_action = new GLib.SimpleAction("open", null);
            open_action.activate.connect(() => on_open_file_clicked());
            this.add_action(open_action);

            var clear_action = new GLib.SimpleAction("clear", null);
            clear_action.activate.connect(() => on_clear_clicked());
            this.add_action(clear_action);

            var save_action = new GLib.SimpleAction("save", null);
            save_action.activate.connect(() => {
                if (save_button_header.sensitive) on_save_clicked();
            });
            this.add_action(save_action);

            var shortcuts_action = new GLib.SimpleAction("show-shortcuts", null);
            shortcuts_action.activate.connect(() => show_shortcuts_window());
            this.add_action(shortcuts_action);

            // Setup keyboard accelerators
            var app = this.application as Adw.Application;
            if (app != null) {
                app.set_accels_for_action("win.open", {"<Primary>o"});
                app.set_accels_for_action("win.clear", {"<Primary><Shift>c"});
                app.set_accels_for_action("win.save", {"<Primary>s"});
                app.set_accels_for_action("win.show-shortcuts", {"<Primary>question"});
            }
        }

        private void show_shortcuts_window() {
            var shortcuts_window = new ShortcutsWindow(this);
            shortcuts_window.present(this);
        }

        private bool on_drop(Gtk.DropTarget target, GLib.Value value, double x, double y) {
            if (value.holds(typeof(GLib.File))) {
                var file = (GLib.File) value.get_object();
                string? path = file.get_path();

                if (path != null && ImageOperations.is_supported_format(path)) {
                    load_image(path);
                    return true;
                } else if (path != null) {
                    show_error_toast(_("Unsupported file format. Please use JPEG, PNG, TIFF, or WebP files."));
                } else {
                    show_error_toast(_("Cannot access the dropped file."));
                }
            }
            return false;
        }

        private void on_open_file_clicked() {
            var dlg = new Gtk.FileChooserNative(_("Open Image File"), this, Gtk.FileChooserAction.OPEN, _("_Open"), _("_Cancel"));

            // Add file filters for supported formats
            var f_images = new Gtk.FileFilter();
            f_images.name = _("Image Files");
            f_images.add_mime_type("image/jpeg");
            f_images.add_mime_type("image/png");
            f_images.add_mime_type("image/webp");
            f_images.add_mime_type("image/tiff");
            f_images.add_mime_type("image/heif");
            f_images.add_mime_type("image/heic");
            f_images.add_pattern("*.jpg");
            f_images.add_pattern("*.jpeg");
            f_images.add_pattern("*.png");
            f_images.add_pattern("*.webp");
            f_images.add_pattern("*.tif");
            f_images.add_pattern("*.tiff");
            f_images.add_pattern("*.heif");
            f_images.add_pattern("*.heic");
            dlg.add_filter(f_images);

            var f_all = new Gtk.FileFilter();
            f_all.name = _("All Files");
            f_all.add_pattern("*");
            dlg.add_filter(f_all);

            dlg.response.connect((res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    var file = dlg.get_file();
                    string? path = file?.get_path();
                    if (path != null && ImageOperations.is_supported_format(path)) {
                        load_image(path);
                    } else if (path != null) {
                        show_error_toast(_("Unsupported file format. Please use JPEG, PNG, TIFF, or WebP files."));
                    }
                }
                dlg.destroy();
            });
            dlg.show();
        }

        private void load_image(string path) {
            try {
                // Validate file path for security
                FileValidator.validate_path(path);

                current_image_path = path;

                // Preview
                image_preview.set_filename(path);
                image_container.visible = true;
                welcome_page.visible = false;
                save_button_header.sensitive = true;

                // Show header bar buttons when image is loaded
                header_separator.visible = true;
                save_button_header.visible = true;
                save_button_header.sensitive = true;
                clear_button_header.visible = true;

                // Metadata
                metadata_display.update_from_file(path);
            } catch (Error e) {
                // Sanitize error message to avoid path disclosure
                var safe_msg = FileValidator.sanitize_error_message(e.message);
                show_error_toast(_("Error loading image: %s").printf(safe_msg));
            }
        }

        private void on_clear_clicked() {
            // Clear current image state
            current_image_path = null;

            // Hide image and show welcome screen
            image_container.visible = false;
            welcome_page.visible = true;

            // Disable save button header
            save_button_header.sensitive = false;

            // Hide header bar action buttons
            header_separator.visible = false;
            save_button_header.visible = false;
            clear_button_header.visible = false;

            // Clear metadata display
            metadata_display.clear();

            // Clear image preview
            image_preview.set_filename(null);
        }

        private void on_save_clicked() {
            if (current_image_path == null)
                return;

            var dlg = new Gtk.FileChooserNative(_("Save Clean Image"), this, Gtk.FileChooserAction.SAVE, _("_Save"), _("_Cancel"));

            // Default name
            var basename = GLib.Path.get_basename(current_image_path);
            var dot = basename.last_index_of(".");
            string name = basename;
            string ext = "";
            if (dot > 0) {
                name = basename.substring(0, dot);
                ext = basename.substring(dot);
            }
            dlg.set_current_name("%s_clean%s".printf(name, ext));

            // Filters
            var f_jpeg = new Gtk.FileFilter();
            f_jpeg.name = _("JPEG Images");
            f_jpeg.add_mime_type("image/jpeg");
            f_jpeg.add_pattern("*.jpg");
            f_jpeg.add_pattern("*.jpeg");
            dlg.add_filter(f_jpeg);

            var f_png = new Gtk.FileFilter();
            f_png.name = _("PNG Images");
            f_png.add_mime_type("image/png");
            f_png.add_pattern("*.png");
            dlg.add_filter(f_png);

            var f_webp = new Gtk.FileFilter();
            f_webp.name = _("WebP Images");
            f_webp.add_mime_type("image/webp");
            f_webp.add_pattern("*.webp");
            dlg.add_filter(f_webp);

            var f_tiff = new Gtk.FileFilter();
            f_tiff.name = _("TIFF Images");
            f_tiff.add_mime_type("image/tiff");
            f_tiff.add_pattern("*.tif");
            f_tiff.add_pattern("*.tiff");
            dlg.add_filter(f_tiff);

            var f_heif = new Gtk.FileFilter();
            f_heif.name = _("HEIF/HEIC Images");
            f_heif.add_mime_type("image/heif");
            f_heif.add_mime_type("image/heic");
            f_heif.add_pattern("*.heif");
            f_heif.add_pattern("*.heic");
            dlg.add_filter(f_heif);

            dlg.response.connect((res) => {
                if (res == Gtk.ResponseType.ACCEPT) {
                    var out = dlg.get_file();
                    string? out_path = out?.get_path();
                    if (out_path != null && ImageOperations.save_clean_copy(current_image_path, out_path)) {
                        show_success_toast(_("Clean image saved to %s").printf(GLib.Path.get_basename(out_path)));
                    } else {
                        show_error_toast(_("Failed to save clean image"));
                    }
                }
                dlg.destroy();
            });
            dlg.show();
        }

        private void show_error_toast(string msg) {
            var t = new Adw.Toast(msg);
            t.timeout = 3;
            toast_overlay.add_toast(t);
        }
        private void show_success_toast(string msg) {
            var t = new Adw.Toast(msg);
            t.timeout = 2;
            toast_overlay.add_toast(t);
        }
    }
}

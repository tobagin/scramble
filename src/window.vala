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

        // Predefined metadata rows
        private MetadataRow filename_row;
        private MetadataRow filesize_row;
        private MetadataRow dimensions_row;
        private MetadataRow camera_row;
        private MetadataRow datetime_row;
        private MetadataRow location_row;

        // Raw metadata section
        private Adw.ExpanderRow raw_metadata_row;

        public Window(Adw.Application app) {
            Object(application: app);
            settings = new GLib.Settings(Config.APP_ID);

            // Setup actions and shortcuts
            setup_actions();

            // Setup drag and drop
            setup_drag_and_drop();

            // Initialize predefined metadata rows
            setup_metadata_rows();


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

        private void setup_metadata_rows() {
            // Create predefined metadata rows with icons and empty values
            filename_row = new MetadataRow(_("Filename"), "");
            filename_row.set_icon("document-properties-symbolic");
            metadata_list.append(filename_row);

            filesize_row = new MetadataRow(_("File Size"), "");
            filesize_row.set_icon("folder-symbolic");
            metadata_list.append(filesize_row);

            dimensions_row = new MetadataRow(_("Dimensions"), "");
            dimensions_row.set_icon("image-x-generic-symbolic");
            metadata_list.append(dimensions_row);

            camera_row = new MetadataRow(_("Camera"), "");
            camera_row.set_icon("camera-photo-symbolic");
            metadata_list.append(camera_row);

            datetime_row = new MetadataRow(_("Date Taken"), "");
            datetime_row.set_icon("appointment-soon-symbolic");
            metadata_list.append(datetime_row);

            location_row = new MetadataRow(_("Location"), "");
            location_row.set_icon("mark-location-symbolic");
            metadata_list.append(location_row);

            // Add expandable raw metadata section
            raw_metadata_row = new Adw.ExpanderRow();
            raw_metadata_row.set_title(_("Raw Metadata"));
            raw_metadata_row.set_subtitle(_("Complete EXIF, XMP, and IPTC data"));
            raw_metadata_row.add_prefix(new Gtk.Image.from_icon_name("text-x-generic-symbolic"));
            raw_metadata_row.enable_expansion = false;  // Start as non-expandable
            metadata_list.append(raw_metadata_row);
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

                if (path != null && is_supported_format(path)) {
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
                    if (path != null && is_supported_format(path)) {
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
                update_metadata_display(path);
            } catch (Error e) {
                show_error_toast(_("Error loading image: %s").printf(e.message));
            }
        }

        private void update_metadata_display(string path) {
            // Update predefined rows with actual data

            // Basic file info
            try {
                var texture = Gdk.Texture.from_file(GLib.File.new_for_path(path));
                var f = GLib.File.new_for_path(path);
                var info = f.query_info("standard::size", GLib.FileQueryInfoFlags.NONE);
                var size = info.get_size();

                // Update filename
                filename_row.update_value(GLib.Path.get_basename(path));

                // Update file size
                string size_str;
                if (size < 1024) {
                    size_str = "%s bytes".printf(size.to_string());
                } else if (size < 1024*1024) {
                    size_str = "%.1f KB".printf(size/1024.0);
                } else {
                    size_str = "%.1f MB".printf(size/(1024.0*1024.0));
                }
                filesize_row.update_value(size_str);

                // Update dimensions
                dimensions_row.update_value("%d × %d pixels".printf(texture.get_width(), texture.get_height()));

            } catch (Error e) {
                // Handle file info errors
                filename_row.update_value(_("Unable to read"));
                filesize_row.update_value(_("Unknown"));
                dimensions_row.update_value(_("Unknown"));
            }

#if HAVE_GEXIV2
            // EXIF/XMP/IPTC via GExiv2
            try {
                var m = new GExiv2.Metadata();
                m.open_path(path);

                // Update camera info
                string camera_info = "";
                var make = m.get_tag_string("Exif.Image.Make");
                var model = m.get_tag_string("Exif.Image.Model");
                if (make != null && model != null) {
                    camera_info = "%s %s".printf(make.strip(), model.strip());
                } else if (model != null) {
                    camera_info = model.strip();
                } else if (make != null) {
                    camera_info = make.strip();
                }
                camera_row.update_value(camera_info != "" ? camera_info : _("Unknown"));

                // Update date/time
                string datetime_info = "";
                var datetime_original = m.get_tag_string("Exif.Photo.DateTimeOriginal");
                var datetime = m.get_tag_string("Exif.Image.DateTime");
                if (datetime_original != null) {
                    datetime_info = datetime_original.strip();
                } else if (datetime != null) {
                    datetime_info = datetime.strip();
                }
                datetime_row.update_value(datetime_info != "" ? datetime_info : _("Unknown"));

                // Update GPS location
                string location_info = "";
                try {
                    double lat, lon, alt;
                    if (m.get_gps_info(out lat, out lon, out alt)) {
                        location_info = "%.6f, %.6f".printf(lat, lon);
                    }
                } catch (Error e) {
                    // GPS info not available
                }
                location_row.update_value(location_info != "" ? location_info : _("Not available"));

                // Populate raw metadata section
                populate_raw_metadata(m);

            } catch (Error e) {
                // If metadata reading fails, set default values
                camera_row.update_value(_("No metadata"));
                datetime_row.update_value(_("No metadata"));
                location_row.update_value(_("No metadata"));
                clear_raw_metadata();
            }
#else
            {
                var row = new Adw.ActionRow();
                row.title = _("No metadata support");
                row.subtitle = _("GExiv2 not available at build time");
                metadata_list.append(row);
            }
#endif
        }

        private void append_kv(string key, string value) {
            var row = new MetadataRow(key, value);
            metadata_list.append(row);
        }

        private void populate_raw_metadata(GExiv2.Metadata metadata) {
            // Clear any existing raw metadata children
            clear_raw_metadata();

            // Add EXIF tags
            var exif_tags = metadata.get_exif_tags();
            var tag_count = 0;
            foreach (var tag in exif_tags) {
                var value = metadata.get_tag_string(tag);
                if (value != null && value.strip() != "") {
                    var raw_row = new MetadataRow(tag, value.strip());
                    raw_metadata_row.add_row(raw_row);
                    tag_count++;
                }
            }

            // Add XMP tags if available
            var xmp_tags = metadata.get_xmp_tags();
            foreach (var tag in xmp_tags) {
                var value = metadata.get_tag_string(tag);
                if (value != null && value.strip() != "") {
                    var raw_row = new MetadataRow(tag, value.strip());
                    raw_metadata_row.add_row(raw_row);
                    tag_count++;
                }
            }

            // Add IPTC tags if available
            var iptc_tags = metadata.get_iptc_tags();
            foreach (var tag in iptc_tags) {
                var value = metadata.get_tag_string(tag);
                if (value != null && value.strip() != "") {
                    var raw_row = new MetadataRow(tag, value.strip());
                    raw_metadata_row.add_row(raw_row);
                    tag_count++;
                }
            }

            // Update the subtitle to show count and enable expansion if there are items
            raw_metadata_row.set_subtitle(_("Complete EXIF, XMP, and IPTC data (%d items)").printf(tag_count));
            raw_metadata_row.enable_expansion = (tag_count > 0);
        }

        private void clear_raw_metadata() {
            // Simple approach: recreate the raw metadata row entirely
            var parent = raw_metadata_row.get_parent() as Gtk.ListBox;
            if (parent != null) {
                parent.remove(raw_metadata_row);

                // Create a new raw metadata row
                raw_metadata_row = new Adw.ExpanderRow();
                raw_metadata_row.set_title(_("Raw Metadata"));
                raw_metadata_row.set_subtitle(_("Complete EXIF, XMP, and IPTC data"));
                raw_metadata_row.enable_expansion = false;  // No content, so not expandable

                parent.append(raw_metadata_row);
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

            // Reset predefined metadata rows to empty values
            filename_row.update_value("");
            filesize_row.update_value("");
            dimensions_row.update_value("");
            camera_row.update_value("");
            datetime_row.update_value("");
            location_row.update_value("");

            // Clear raw metadata
            clear_raw_metadata();

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
                    if (out_path != null && save_clean_copy(current_image_path, out_path)) {
                        show_success_toast(_("Clean image saved to %s").printf(GLib.Path.get_basename(out_path)));
                    } else {
                        show_error_toast(_("Failed to save clean image"));
                    }
                }
                dlg.destroy();
            });
            dlg.show();
        }

        private bool save_clean_copy(string in_path, string out_path) {
            try {
                // Load the image using GdkPixbuf to strip metadata
                var pixbuf = new Gdk.Pixbuf.from_file(in_path);

                // Determine output format from file extension
                string format = infer_image_type(out_path);

                // Ensure output path has correct extension
                string final_out_path = ensure_extension(out_path, format);

                // Save without any metadata
                // Note: Using null instead of {} for empty arrays to ensure proper null-termination
                if (format == "jpeg") {
                    pixbuf.savev(final_out_path, "jpeg", {"quality", null}, {"95", null});
                } else if (format == "png") {
                    pixbuf.savev(final_out_path, "png", null, null);
                } else if (format == "webp") {
                    pixbuf.savev(final_out_path, "webp", {"quality", null}, {"95", null});
                } else if (format == "tiff") {
                    pixbuf.savev(final_out_path, "tiff", {"compression", null}, {"1", null});
                } else {
                    // Default to JPEG if format is unknown
                    pixbuf.savev(final_out_path, "jpeg", {"quality", null}, {"95", null});
                }

                return true;
            } catch (Error e) {
                warning("Save failed: %s", e.message);
                return false;
            }
        }

        private string ensure_extension(string path, string format) {
            // Get the expected extension for this format
            string expected_ext = "";
            switch (format) {
                case "jpeg":
                    expected_ext = ".jpg";
                    break;
                case "png":
                    expected_ext = ".png";
                    break;
                case "webp":
                    expected_ext = ".webp";
                    break;
                case "tiff":
                    expected_ext = ".tiff";
                    break;
                default:
                    expected_ext = ".jpg";
                    break;
            }

            // Check if path already has correct extension
            var lower = path.down();
            if (format == "jpeg" && (lower.has_suffix(".jpg") || lower.has_suffix(".jpeg"))) {
                return path;
            } else if (format == "png" && lower.has_suffix(".png")) {
                return path;
            } else if (format == "webp" && lower.has_suffix(".webp")) {
                return path;
            } else if (format == "tiff" && (lower.has_suffix(".tif") || lower.has_suffix(".tiff"))) {
                return path;
            }

            // Path doesn't have correct extension, add it
            return path + expected_ext;
        }

        private static string infer_image_type(string path) {
            var lower = path.down();
            if (lower.has_suffix(".jpg") || lower.has_suffix(".jpeg")) return "jpeg";
            if (lower.has_suffix(".png")) return "png";
            if (lower.has_suffix(".webp")) return "webp";
            if (lower.has_suffix(".tif") || lower.has_suffix(".tiff")) return "tiff";
            // default to jpeg
            return "jpeg";
        }

        private static bool is_supported_format(string path) {
            var lower = path.down();
            return lower.has_suffix(".jpg") || lower.has_suffix(".jpeg") ||
                   lower.has_suffix(".png") || lower.has_suffix(".webp") ||
                   lower.has_suffix(".tif") || lower.has_suffix(".tiff") ||
                   lower.has_suffix(".heif") || lower.has_suffix(".heic");
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

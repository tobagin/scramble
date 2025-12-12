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

            var batch_action = new GLib.SimpleAction("batch-process", null);
            batch_action.activate.connect(() => on_batch_process_clicked());
            this.add_action(batch_action);

            var export_action = new GLib.SimpleAction("export-metadata", null);
            export_action.activate.connect(() => {
                if (current_image_path != null) on_export_metadata_clicked();
            });
            this.add_action(export_action);

            var compare_action = new GLib.SimpleAction("compare", null);
            compare_action.activate.connect(() => {
                if (current_image_path != null) on_compare_clicked();
            });
            this.add_action(compare_action);

            // Setup keyboard accelerators
            var app = this.application as Adw.Application;
            if (app != null) {
                app.set_accels_for_action("win.open", {"<Primary>o"});
                app.set_accels_for_action("win.clear", {"<Primary><Shift>c"});
                app.set_accels_for_action("win.save", {"<Primary>s"});
                app.set_accels_for_action("win.batch-process", {"<Primary>b"});
                app.set_accels_for_action("win.export-metadata", {"<Primary>e"});
                app.set_accels_for_action("win.compare", {"<Primary>r"});
                app.set_accels_for_action("win.show-shortcuts", {"<Primary>question"});
            }
        }

        private void show_shortcuts_window() {
            ShortcutsWindow.show(this);
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
            var dlg = new Gtk.FileDialog();
            dlg.title = _("Open Image File");

            // Add file filters for supported formats
            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));

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
            filters.append(f_images);

            var f_all = new Gtk.FileFilter();
            f_all.name = _("All Files");
            f_all.add_pattern("*");
            filters.append(f_all);

            dlg.filters = filters;
            dlg.default_filter = f_images;

            dlg.open.begin(this, null, (obj, res) => {
                try {
                    var file = dlg.open.end(res);
                    string? path = file.get_path();
                    if (path != null && ImageOperations.is_supported_format(path)) {
                        load_image(path);
                    } else if (path != null) {
                        show_error_toast(_("Unsupported file format. Please use JPEG, PNG, TIFF, or WebP files."));
                    }
                } catch (Error e) {
                    // User cancelled or error occurred - silently ignore
                }
            });
        }

        internal void load_image(string path) {
            try {
                // Validate file path for security
                FileValidator.validate_path(path);

                // Validate format by magic numbers (SEC-003)
                var ext = ImageOperations.is_supported_format(path) ? get_file_extension(path) : "";
                if (ext != "") {
                    if (!MagicNumberValidator.validate_format(path, ext)) {
                        var error_msg = MagicNumberValidator.get_validation_error_message(path, ext);
                        throw new FileError.FAILED(error_msg);
                    }
                }

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

            var dlg = new Gtk.FileDialog();
            dlg.title = _("Save Clean Image");

            // Default name
            var basename = GLib.Path.get_basename(current_image_path);
            var dot = basename.last_index_of(".");
            string name = basename;
            string ext = "";
            if (dot > 0) {
                name = basename.substring(0, dot);
                ext = basename.substring(dot);
            }
            dlg.initial_name = "%s_clean%s".printf(name, ext);

            // Filters
            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));

            var f_jpeg = new Gtk.FileFilter();
            f_jpeg.name = _("JPEG Images");
            f_jpeg.add_mime_type("image/jpeg");
            f_jpeg.add_pattern("*.jpg");
            f_jpeg.add_pattern("*.jpeg");
            filters.append(f_jpeg);

            var f_png = new Gtk.FileFilter();
            f_png.name = _("PNG Images");
            f_png.add_mime_type("image/png");
            f_png.add_pattern("*.png");
            filters.append(f_png);

            var f_webp = new Gtk.FileFilter();
            f_webp.name = _("WebP Images");
            f_webp.add_mime_type("image/webp");
            f_webp.add_pattern("*.webp");
            filters.append(f_webp);

            var f_tiff = new Gtk.FileFilter();
            f_tiff.name = _("TIFF Images");
            f_tiff.add_mime_type("image/tiff");
            f_tiff.add_pattern("*.tif");
            f_tiff.add_pattern("*.tiff");
            filters.append(f_tiff);

            var f_heif = new Gtk.FileFilter();
            f_heif.name = _("HEIF/HEIC Images");
            f_heif.add_mime_type("image/heif");
            f_heif.add_mime_type("image/heic");
            f_heif.add_pattern("*.heif");
            f_heif.add_pattern("*.heic");
            filters.append(f_heif);

            dlg.filters = filters;

            dlg.save.begin(this, null, (obj, res) => {
                try {
                    var out = dlg.save.end(res);
                    string? out_path = out.get_path();

                    if (out_path != null) {
                        // Debug logging
                        debug("Saving to path: %s", out_path);

                        if (ImageOperations.save_clean_copy(current_image_path, out_path)) {
                            show_success_toast(_("Clean image saved to %s").printf(GLib.Path.get_basename(out_path)));
                        } else {
                            show_error_toast(_("Failed to save clean image"));
                        }
                    } else {
                        show_error_toast(_("No output path selected"));
                    }
                } catch (Error e) {
                    // User cancelled - silently ignore
                    debug("Save cancelled or error: %s", e.message);
                }
            });
        }

        private void on_batch_process_clicked() {
            // Open file dialog to select multiple files
            var dlg = new Gtk.FileDialog();
            dlg.title = _("Select Images for Batch Processing");

            // Filters
            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));

            var f_images = new Gtk.FileFilter();
            f_images.name = _("All Supported Images");
            f_images.add_mime_type("image/jpeg");
            f_images.add_mime_type("image/png");
            f_images.add_mime_type("image/webp");
            f_images.add_mime_type("image/tiff");
            f_images.add_mime_type("image/heif");
            f_images.add_mime_type("image/heic");
            filters.append(f_images);

            dlg.filters = filters;

            // Use open_multiple to select multiple files
            dlg.open_multiple.begin(this, null, (obj, res) => {
                try {
                    var files = dlg.open_multiple.end(res);
                    if (files == null) {
                        return;
                    }

                    // Convert GLib.ListModel to List<string>
                    var paths = new List<string>();
                    for (uint i = 0; i < files.get_n_items(); i++) {
                        var file = files.get_item(i) as GLib.File;
                        if (file != null) {
                            string? path = file.get_path();
                            if (path != null && ImageOperations.is_supported_format(path)) {
                                paths.append(path);
                            }
                        }
                    }

                    if (paths.length() == 0) {
                        show_error_toast(_("No valid images selected"));
                        return;
                    }

                    // Now ask for output directory
                    var dir_dlg = new Gtk.FileDialog();
                    dir_dlg.title = _("Select Output Directory");

                    dir_dlg.select_folder.begin(this, null, (obj2, res2) => {
                        try {
                            var output_dir = dir_dlg.select_folder.end(res2);
                            string? output_path = output_dir.get_path();

                            if (output_path != null) {
                                process_batch(paths, output_path);
                            }
                        } catch (Error e) {
                            debug("Output directory selection cancelled: %s", e.message);
                        }
                    });
                } catch (Error e) {
                    debug("File selection cancelled: %s", e.message);
                }
            });
        }

        private void process_batch(List<string> paths, string output_dir) {
            show_success_toast(_("Processing %d images...").printf((int)paths.length()));

            // Process on main thread - GdkPixbuf is not thread-safe
            var results = BatchProcessor.process_batch(paths, output_dir, (current, total, filename) => {
                show_success_toast(_("Processing %d/%d: %s").printf(current, total, filename));
            });

            // Show final report
            int success_count, failed_count;
            BatchProcessor.get_summary(results, out success_count, out failed_count);

            if (failed_count == 0) {
                show_success_toast(_("Successfully processed %d images!").printf(success_count));
            } else {
                show_error_toast(_("Processed %d images (%d failed)").printf(success_count, failed_count));

                // Show detailed report in a dialog
                var report_dialog = new Adw.AlertDialog(_("Batch Processing Complete"), BatchProcessor.generate_report(results));
                report_dialog.add_response("ok", _("OK"));
                report_dialog.default_response = "ok";
                report_dialog.present(this);
            }
        }

        private void on_export_metadata_clicked() {
            if (current_image_path == null)
                return;

            // Show format selection dialog
            var format_dialog = new Adw.AlertDialog(
                _("Export Metadata"),
                _("Choose the export format for metadata:")
            );
            format_dialog.add_response("json", _("JSON"));
            format_dialog.add_response("csv", _("CSV"));
            format_dialog.add_response("cancel", _("Cancel"));
            format_dialog.default_response = "json";
            format_dialog.close_response = "cancel";

            format_dialog.response.connect((response_id) => {
                if (response_id == "json" || response_id == "csv") {
                    export_metadata_with_format(response_id);
                }
            });

            format_dialog.present(this);
        }

        private void export_metadata_with_format(string format_name) {
            if (current_image_path == null)
                return;

            var dlg = new Gtk.FileDialog();
            dlg.title = _("Export Metadata");

            // Default name
            var basename = GLib.Path.get_basename(current_image_path);
            var dot = basename.last_index_of(".");
            string name = basename;
            if (dot > 0) {
                name = basename.substring(0, dot);
            }
            dlg.initial_name = "%s_metadata.%s".printf(name, format_name);

            // Filters
            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));

            var filter = new Gtk.FileFilter();
            if (format_name == "json") {
                filter.name = _("JSON Files");
                filter.add_mime_type("application/json");
                filter.add_pattern("*.json");
            } else if (format_name == "csv") {
                filter.name = _("CSV Files");
                filter.add_mime_type("text/csv");
                filter.add_pattern("*.csv");
            }
            filters.append(filter);

            dlg.filters = filters;

            dlg.save.begin(this, null, (obj, res) => {
                try {
                    var out = dlg.save.end(res);
                    string? out_path = out.get_path();

                    if (out_path != null) {
                        var format = format_name == "json" ?
                            MetadataExporter.ExportFormat.JSON :
                            MetadataExporter.ExportFormat.CSV;

                        if (MetadataExporter.export_to_file(current_image_path, out_path, format)) {
                            show_success_toast(_("Metadata exported to %s").printf(GLib.Path.get_basename(out_path)));
                        } else {
                            show_error_toast(_("Failed to export metadata"));
                        }
                    }
                } catch (Error e) {
                    debug("Export cancelled or error: %s", e.message);
                }
            });
        }

        private void on_compare_clicked() {
            if (current_image_path == null)
                return;

            var comparison_dialog = new ComparisonDialog(this, current_image_path);
            comparison_dialog.present();
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

        /**
         * Get file extension from path
         *
         * @param path File path
         * @return File extension (e.g., "jpg", "png") without the dot
         */
        private string get_file_extension(string path) {
            var lower = path.down();
            if (lower.has_suffix(".jpg")) return "jpg";
            if (lower.has_suffix(".jpeg")) return "jpeg";
            if (lower.has_suffix(".png")) return "png";
            if (lower.has_suffix(".webp")) return "webp";
            if (lower.has_suffix(".tif")) return "tif";
            if (lower.has_suffix(".tiff")) return "tiff";
            if (lower.has_suffix(".heif")) return "heif";
            if (lower.has_suffix(".heic")) return "heic";

            // Fallback: extract extension after last dot
            var parts = path.split(".");
            if (parts.length > 1) {
                return parts[parts.length - 1].down();
            }

            return "";
        }
    }
}

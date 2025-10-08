using Gtk;
using Adw;
using Gdk;

namespace Scramble {
    /**
     * Dialog for comparing original and cleaned images side-by-side
     */
    public class ComparisonDialog : Adw.Window {
        private Gtk.Picture original_picture;
        private Gtk.Picture cleaned_picture;
        private Adw.ToastOverlay toast_overlay;
        private string original_path;
        private string? cleaned_path = null;

        public ComparisonDialog(Gtk.Window parent, string original_image_path) {
            Object(
                transient_for: parent,
                modal: true,
                default_width: 1000,
                default_height: 700,
                title: _("Compare Original and Clean")
            );

            this.original_path = original_image_path;

            // Build UI
            build_ui();

            // Load original image
            load_original_image();
        }

        private void build_ui() {
            var toolbar_view = new Adw.ToolbarView();
            this.content = toolbar_view;

            // Header bar
            var header_bar = new Adw.HeaderBar();
            toolbar_view.add_top_bar(header_bar);

            // Save clean copy button
            var save_button = new Gtk.Button.with_label(_("Save Clean Copy"));
            save_button.add_css_class("suggested-action");
            save_button.clicked.connect(() => on_save_clicked());
            header_bar.pack_end(save_button);

            // Main content with toast overlay
            toast_overlay = new Adw.ToastOverlay();
            toolbar_view.content = toast_overlay;

            // Paned view for side-by-side comparison
            var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            paned.position = 500;
            paned.shrink_start_child = false;
            paned.shrink_end_child = false;
            toast_overlay.child = paned;

            // Original image side
            var original_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            original_box.margin_top = 12;
            original_box.margin_bottom = 12;
            original_box.margin_start = 12;
            original_box.margin_end = 6;

            var original_label = new Gtk.Label(_("Original (with metadata)"));
            original_label.add_css_class("title-2");
            original_box.append(original_label);

            var original_scroll = new Gtk.ScrolledWindow();
            original_scroll.vexpand = true;
            original_scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            original_scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;

            original_picture = new Gtk.Picture();
            original_picture.can_shrink = true;
            original_picture.content_fit = Gtk.ContentFit.CONTAIN;
            original_scroll.child = original_picture;

            original_box.append(original_scroll);
            paned.start_child = original_box;

            // Cleaned image side
            var cleaned_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            cleaned_box.margin_top = 12;
            cleaned_box.margin_bottom = 12;
            cleaned_box.margin_start = 6;
            cleaned_box.margin_end = 12;

            var cleaned_label = new Gtk.Label(_("Clean (metadata removed)"));
            cleaned_label.add_css_class("title-2");
            cleaned_box.append(cleaned_label);

            var cleaned_scroll = new Gtk.ScrolledWindow();
            cleaned_scroll.vexpand = true;
            cleaned_scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            cleaned_scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;

            cleaned_picture = new Gtk.Picture();
            cleaned_picture.can_shrink = true;
            cleaned_picture.content_fit = Gtk.ContentFit.CONTAIN;
            cleaned_scroll.child = cleaned_picture;

            // Generate preview button
            var generate_button = new Gtk.Button.with_label(_("Generate Preview"));
            generate_button.halign = Gtk.Align.CENTER;
            generate_button.valign = Gtk.Align.CENTER;
            generate_button.add_css_class("pill");
            generate_button.add_css_class("suggested-action");
            generate_button.clicked.connect(() => generate_cleaned_preview());

            var cleaned_overlay = new Gtk.Overlay();
            cleaned_overlay.child = cleaned_scroll;
            cleaned_overlay.add_overlay(generate_button);

            cleaned_box.append(cleaned_overlay);
            paned.end_child = cleaned_box;
        }

        private void load_original_image() {
            try {
                var file = File.new_for_path(original_path);
                original_picture.set_file(file);
            } catch (Error e) {
                show_error_toast(_("Failed to load original image: %s").printf(e.message));
            }
        }

        private void generate_cleaned_preview() {
            show_success_toast(_("Generating clean preview..."));

            // Create temporary file for cleaned version
            try {
                // Generate temp file path
                var basename = Path.get_basename(original_path);
                var temp_dir = Environment.get_tmp_dir();
                cleaned_path = Path.build_filename(temp_dir, "scramble_preview_%s".printf(basename));

                // Save clean copy
                if (ImageOperations.save_clean_copy(original_path, cleaned_path)) {
                    // Load cleaned image
                    var file = File.new_for_path(cleaned_path);
                    cleaned_picture.set_file(file);
                    show_success_toast(_("Preview generated successfully"));
                } else {
                    show_error_toast(_("Failed to generate clean preview"));
                }
            } catch (Error e) {
                show_error_toast(_("Error: %s").printf(e.message));
            }
        }

        private void on_save_clicked() {
            if (cleaned_path == null) {
                show_error_toast(_("Please generate preview first"));
                return;
            }

            var dlg = new Gtk.FileDialog();
            dlg.title = _("Save Clean Image");

            // Default name
            var basename = GLib.Path.get_basename(original_path);
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

            dlg.filters = filters;

            dlg.save.begin(this, null, (obj, res) => {
                try {
                    var out = dlg.save.end(res);
                    string? out_path = out.get_path();

                    if (out_path != null) {
                        // Copy temp file to final location
                        var source = File.new_for_path(cleaned_path);
                        var dest = File.new_for_path(out_path);
                        source.copy(dest, FileCopyFlags.OVERWRITE);

                        show_success_toast(_("Clean image saved to %s").printf(GLib.Path.get_basename(out_path)));
                    }
                } catch (Error e) {
                    show_error_toast(_("Failed to save: %s").printf(e.message));
                }
            });
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

        public override void dispose() {
            // Clean up temp file
            if (cleaned_path != null) {
                try {
                    var file = File.new_for_path(cleaned_path);
                    if (file.query_exists()) {
                        file.delete();
                    }
                } catch (Error e) {
                    warning("Failed to delete temp file: %s", e.message);
                }
            }
            base.dispose();
        }
    }
}

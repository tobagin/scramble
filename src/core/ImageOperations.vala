using Gdk;

namespace Scramble {
    /**
     * Handles image file operations and format conversions
     */
    public class ImageOperations : Object {

        /**
         * Check if a file format is supported
         *
         * @param path File path to check
         * @return true if format is supported
         */
        public static bool is_supported_format(string path) {
            var lower = path.down();
            return lower.has_suffix(".jpg") || lower.has_suffix(".jpeg") ||
                   lower.has_suffix(".png") || lower.has_suffix(".webp") ||
                   lower.has_suffix(".tif") || lower.has_suffix(".tiff") ||
                   lower.has_suffix(".heif") || lower.has_suffix(".heic");
        }

        /**
         * Save a clean copy of an image without metadata
         *
         * @param in_path Source image path
         * @param out_path Destination path for clean image
         * @return true on success, false on failure
         */
        public static bool save_clean_copy(string in_path, string out_path) {
            try {
                debug("save_clean_copy: input=%s, output=%s", in_path, out_path);

                // Validate input path
                FileValidator.validate_path(in_path);

                // Validate output path (basic checks only - don't check file size)
                FileValidator.validate_output_path(out_path);

                // Validate format by magic numbers (SEC-003)
                var ext = get_file_extension(in_path);
                if (!MagicNumberValidator.validate_format(in_path, ext)) {
                    var error_msg = MagicNumberValidator.get_validation_error_message(in_path, ext);
                    warning("Format validation failed: %s", error_msg);
                    throw new FileError.FAILED(error_msg);
                }

                debug("Validation passed, loading image...");

                // Load the image using GdkPixbuf to strip metadata
                var pixbuf = new Gdk.Pixbuf.from_file(in_path);
                debug("Image loaded: %dx%d", pixbuf.get_width(), pixbuf.get_height());

                // Determine output format from file extension
                string format = infer_image_type(out_path);

                // Ensure output path has correct extension
                string final_out_path = ensure_extension(out_path, format);

                // Save without any metadata using GFile for Flatpak portal compatibility
                debug("Saving as %s to: %s", format, final_out_path);

                // Use GFile-based save for portal compatibility
                var out_file = GLib.File.new_for_path(final_out_path);
                var output_stream = out_file.replace(null, false, GLib.FileCreateFlags.NONE);

                // Save with appropriate format
                if (format == "jpeg") {
                    debug("Saving as JPEG");
                    pixbuf.save_to_streamv(output_stream, "jpeg", {"quality"}, {"95"});
                } else if (format == "png") {
                    debug("Saving as PNG");
                    pixbuf.save_to_streamv(output_stream, "png", null, null);
                } else if (format == "webp") {
                    debug("Saving as WebP");
                    pixbuf.save_to_streamv(output_stream, "webp", {"quality"}, {"95"});
                } else if (format == "tiff") {
                    // TIFF not supported with save_to_streamv, convert to PNG (lossless)
                    warning("TIFF format not supported with portals, converting to PNG");
                    output_stream.close();

                    // Change extension to .png
                    var png_path = final_out_path.replace(".tiff", ".png").replace(".tif", ".png");

                    var png_file = GLib.File.new_for_path(png_path);
                    var png_stream = png_file.replace(null, false, GLib.FileCreateFlags.NONE);
                    pixbuf.save_to_streamv(png_stream, "png", null, null);
                    png_stream.close();
                    debug("Saved as PNG: %s", png_path);
                    return true;
                } else {
                    // Default to JPEG if format is unknown
                    debug("Unknown format, defaulting to JPEG");
                    pixbuf.save_to_streamv(output_stream, "jpeg", {"quality"}, {"95"});
                }

                output_stream.close();
                debug("Save completed successfully");

                // Secure memory clearing if enabled
                var settings = new GLib.Settings(Config.APP_ID);
                if (SecureMemory.is_enabled(settings)) {
                    SecureMemory.clear_pixbuf(pixbuf);
                }

                return true;
            } catch (Error e) {
                warning("Save failed: %s", e.message);
                return false;
            }
        }

        /**
         * Ensure file path has correct extension for format
         */
        private static string ensure_extension(string path, string format) {
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

            return path + expected_ext;
        }

        /**
         * Infer image type from file extension
         */
        private static string infer_image_type(string path) {
            var lower = path.down();
            if (lower.has_suffix(".jpg") || lower.has_suffix(".jpeg")) return "jpeg";
            if (lower.has_suffix(".png")) return "png";
            if (lower.has_suffix(".webp")) return "webp";
            if (lower.has_suffix(".tif") || lower.has_suffix(".tiff")) return "tiff";
            return "jpeg";
        }

        /**
         * Get file extension from path
         *
         * @param path File path
         * @return File extension (e.g., "jpg", "png") without the dot
         */
        private static string get_file_extension(string path) {
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

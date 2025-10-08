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
                // Validate paths
                FileValidator.validate_path(in_path);
                FileValidator.validate_output_path(out_path);

                // Load the image using GdkPixbuf to strip metadata
                var pixbuf = new Gdk.Pixbuf.from_file(in_path);

                // Determine output format from file extension
                string format = infer_image_type(out_path);

                // Ensure output path has correct extension
                string final_out_path = ensure_extension(out_path, format);

                // Save without any metadata
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
    }
}

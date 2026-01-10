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

                // Get settings to check metadata removal preferences
                var settings = new GLib.Settings(Config.APP_ID);
                
                // Determine output format from file extension
                string format = infer_image_type(out_path);
                
                // Ensure output path has correct extension
                string final_out_path = ensure_extension(out_path, format);
                
#if HAVE_GEXIV2
                // Check if we need selective metadata removal
                if (!MetadataFilter.is_remove_all(settings)) {
                    // Use GExiv2-based approach for selective removal
                    return save_with_selective_metadata(in_path, final_out_path, format, settings);
                }
#endif
                
                // Default: Use GdkPixbuf approach to strip ALL metadata (fastest)
                return save_stripped(in_path, final_out_path, format, settings);
                
            } catch (Error e) {
                warning("Save failed: %s", e.message);
                return false;
            }
        }
        
        /**
         * Save image with all metadata stripped using GdkPixbuf
         * This is the fastest approach when removing all metadata
         */
        private static bool save_stripped(string in_path, string out_path, string format, GLib.Settings settings) throws Error {
            // Load the image using GdkPixbuf to strip metadata
            var pixbuf = new Gdk.Pixbuf.from_file(in_path);
            debug("Image loaded: %dx%d", pixbuf.get_width(), pixbuf.get_height());

            // Save without any metadata using GFile for Flatpak portal compatibility
            debug("Saving as %s to: %s", format, out_path);

            // Use GFile-based save for portal compatibility
            var out_file = GLib.File.new_for_path(out_path);
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
                var png_path = out_path.replace(".tiff", ".png").replace(".tif", ".png");

                var png_file = GLib.File.new_for_path(png_path);
                var png_stream = png_file.replace(null, false, GLib.FileCreateFlags.NONE);
                pixbuf.save_to_streamv(png_stream, "png", null, null);
                png_stream.close();
                debug("Saved as PNG: %s", png_path);
                
                // Secure memory clearing if enabled
                if (SecureMemory.is_enabled(settings)) {
                    SecureMemory.clear_pixbuf(pixbuf);
                }
                return true;
            } else {
                // Default to JPEG if format is unknown
                debug("Unknown format, defaulting to JPEG");
                pixbuf.save_to_streamv(output_stream, "jpeg", {"quality"}, {"95"});
            }

            output_stream.close();
            debug("Save completed successfully");

            // Secure memory clearing if enabled
            if (SecureMemory.is_enabled(settings)) {
                SecureMemory.clear_pixbuf(pixbuf);
            }

            return true;
        }
        
#if HAVE_GEXIV2
        /**
         * Save image with selective metadata removal using GExiv2
         * Used when user wants to preserve some metadata categories
         */
        private static bool save_with_selective_metadata(string in_path, string out_path, string format, GLib.Settings settings) throws Error {
            debug("Using selective metadata removal");
            
            // First, load the image with GdkPixbuf (to save with correct format)
            var pixbuf = new Gdk.Pixbuf.from_file(in_path);
            debug("Image loaded: %dx%d", pixbuf.get_width(), pixbuf.get_height());
            
            // Load metadata from original file
            var metadata = new GExiv2.Metadata();
            metadata.open_path(in_path);
            
            // Apply selective filter based on settings
            int removed = MetadataFilter.apply_filter(metadata, settings);
            debug("Removed %d metadata tags based on filter settings", removed);
            
            // Save the image first (without metadata)
            var out_file = GLib.File.new_for_path(out_path);
            var output_stream = out_file.replace(null, false, GLib.FileCreateFlags.NONE);
            
            // Save with appropriate format
            if (format == "jpeg") {
                pixbuf.save_to_streamv(output_stream, "jpeg", {"quality"}, {"95"});
            } else if (format == "png") {
                pixbuf.save_to_streamv(output_stream, "png", null, null);
            } else if (format == "webp") {
                pixbuf.save_to_streamv(output_stream, "webp", {"quality"}, {"95"});
            } else if (format == "tiff") {
                // Convert to PNG for TIFF
                warning("TIFF format not supported with portals, converting to PNG");
                output_stream.close();
                var png_path = out_path.replace(".tiff", ".png").replace(".tif", ".png");
                var png_file = GLib.File.new_for_path(png_path);
                var png_stream = png_file.replace(null, false, GLib.FileCreateFlags.NONE);
                pixbuf.save_to_streamv(png_stream, "png", null, null);
                png_stream.close();
                
                // Write filtered metadata to the PNG file
                metadata.save_file(png_path);
                debug("Saved PNG with selective metadata: %s", png_path);
                
                if (SecureMemory.is_enabled(settings)) {
                    SecureMemory.clear_pixbuf(pixbuf);
                }
                return true;
            } else {
                pixbuf.save_to_streamv(output_stream, "jpeg", {"quality"}, {"95"});
            }
            
            output_stream.close();
            
            // Now write the filtered metadata back to the saved file
            metadata.save_file(out_path);
            debug("Saved image with selective metadata: %s", out_path);
            
            // Secure memory clearing if enabled
            if (SecureMemory.is_enabled(settings)) {
                SecureMemory.clear_pixbuf(pixbuf);
            }
            
            return true;
        }
#endif

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

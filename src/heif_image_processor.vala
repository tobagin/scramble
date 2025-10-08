/**
 * HEIF Image Processing Implementation
 *
 * Implements the HeifImageProcessor interface using GdkPixbuf with
 * heif-gdk-pixbuf loader for loading, displaying, and saving HEIF/HEIC images.
 */

using Scramble.Contracts;

namespace Scramble {

    public class HeifImageProcessorImpl : Object, HeifImageProcessor {

        /**
         * Load HEIF/HEIC image for display in GTK Picture widget
         */
        public Gdk.Pixbuf load_image(string file_path) throws IOError, ImageError {
            var file = File.new_for_path(file_path);
            if (!file.query_exists()) {
                throw new IOError.NOT_FOUND("File not found: %s".printf(file_path));
            }

            try {
                // Use GdkPixbuf to load the HEIF image
                // This will work automatically if heif-gdk-pixbuf loader is installed
                var pixbuf = new Gdk.Pixbuf.from_file(file_path);

                if (pixbuf == null) {
                    throw new ImageError.DECODE_FAILED("Failed to decode HEIF image: %s".printf(file_path));
                }

                return pixbuf;

            } catch (GLib.Error e) {
                if ("heif" in e.message.down() || "codec" in e.message.down()) {
                    throw new ImageError.MISSING_CODEC("HEIF codec not available: %s".printf(e.message));
                } else if ("memory" in e.message.down()) {
                    throw new ImageError.INSUFFICIENT_MEMORY("Insufficient memory to load image: %s".printf(e.message));
                } else {
                    throw new ImageError.DECODE_FAILED("Failed to load HEIF image: %s".printf(e.message));
                }
            }
        }

        /**
         * Load specific image from HEIF sequence
         */
        public Gdk.Pixbuf load_image_by_index(string file_path, int image_index) throws IOError, ImageError, IndexError {
            // For now, only support single images (index 0)
            if (image_index != 0) {
                throw new IndexError.OUT_OF_RANGE("Image index %d out of range for single image file".printf(image_index));
            }

            return load_image(file_path);
        }

        /**
         * Save clean copy of HEIF/HEIC image without metadata
         */
        public void save_clean_copy(string source_path, string output_path, ImageFormat output_format, int quality = 90) throws IOError, ImageError {
            // Load the image
            var pixbuf = load_image(source_path);

            // Save without metadata
            try {
                string format_name = get_format_name(output_format);
                string[]? option_keys = null;
                string[]? option_values = null;

                // Set quality for lossy formats with properly null-terminated arrays
                if (QualitySettings.is_lossy_format(output_format)) {
                    option_keys = {"quality", null};
                    option_values = {quality.to_string(), null};
                }

                // Save the pixbuf (this strips metadata automatically)
                pixbuf.savev(output_path, format_name, option_keys, option_values);

            } catch (Error e) {
                throw new ImageError.ENCODE_FAILED("Failed to save clean copy: %s".printf(e.message));
            }
        }

        /**
         * Save clean copy of specific image from HEIF sequence
         */
        public void save_clean_copy_by_index(string source_path, int image_index, string output_path, ImageFormat output_format, int quality = 90) throws IOError, ImageError, IndexError {
            // For now, only support single images (index 0)
            if (image_index != 0) {
                throw new IndexError.OUT_OF_RANGE("Image index %d out of range for single image file".printf(image_index));
            }

            save_clean_copy(source_path, output_path, output_format, quality);
        }

        /**
         * Get image dimensions without loading full image data
         */
        public ImageDimensions get_image_dimensions(string file_path) throws IOError, ImageError {
            var file = File.new_for_path(file_path);
            if (!file.query_exists()) {
                throw new IOError.NOT_FOUND("File not found: %s".printf(file_path));
            }

            try {
                // Use GdkPixbuf.get_file_info for efficient dimension reading
                int width, height;
                var format = Gdk.Pixbuf.get_file_info(file_path, out width, out height);

                if (format == null) {
                    throw new ImageError.DECODE_FAILED("Cannot read image information");
                }

                return ImageDimensions(width, height);

            } catch (Error e) {
                throw new ImageError.DECODE_FAILED("Failed to get image dimensions: %s".printf(e.message));
            }
        }

        /**
         * Check if HEIF file can be processed by current system
         */
        public ProcessingCapability check_processing_capability(string file_path) throws IOError {
            var file = File.new_for_path(file_path);
            if (!file.query_exists()) {
                throw new IOError.NOT_FOUND("File not found: %s".printf(file_path));
            }

            // Check if GdkPixbuf can handle HEIF format
            bool has_heif_support = false;
            SList<weak Gdk.PixbufFormat> formats = Gdk.Pixbuf.get_formats();

            foreach (var format in formats) {
                string[] mime_types = format.get_mime_types();
                foreach (string mime_type in mime_types) {
                    if (mime_type == "image/heif" || mime_type == "image/heic") {
                        has_heif_support = true;
                        break;
                    }
                }
                if (has_heif_support) break;
            }

            if (!has_heif_support) {
                return ProcessingCapability.NO_SUPPORT;
            }

            // Try to load basic information
            try {
                int width, height;
                var format = Gdk.Pixbuf.get_file_info(file_path, out width, out height);
                if (format == null) {
                    return ProcessingCapability.NO_SUPPORT;
                }

                // Check if we can actually load the image
                var pixbuf = new Gdk.Pixbuf.from_file_at_scale(file_path, 100, 100, true);
                if (pixbuf == null) {
                    return ProcessingCapability.METADATA_ONLY;
                }

                return ProcessingCapability.FULL_SUPPORT;

            } catch (Error e) {
                // If we can get info but not load, metadata only
                try {
                    int width, height;
                    Gdk.Pixbuf.get_file_info(file_path, out width, out height);
                    return ProcessingCapability.METADATA_ONLY;
                } catch (Error e2) {
                    return ProcessingCapability.NO_SUPPORT;
                }
            }
        }

        /**
         * Validate HEIF file integrity
         */
        public bool validate_file_integrity(string file_path) throws IOError {
            var file = File.new_for_path(file_path);
            if (!file.query_exists()) {
                throw new IOError.NOT_FOUND("File not found: %s".printf(file_path));
            }

            try {
                // Try to get basic file information
                int width, height;
                var format = Gdk.Pixbuf.get_file_info(file_path, out width, out height);

                if (format == null || width <= 0 || height <= 0) {
                    return false;
                }

                // Try to load a small thumbnail to verify integrity
                var pixbuf = new Gdk.Pixbuf.from_file_at_scale(file_path, 100, 100, true);
                return (pixbuf != null);

            } catch (Error e) {
                warning("File validation failed: %s", e.message);
                return false;
            }
        }

        /**
         * Convert ImageFormat enum to GdkPixbuf format name
         */
        private string get_format_name(ImageFormat format) throws ImageError {
            switch (format) {
                case ImageFormat.JPEG:
                    return "jpeg";
                case ImageFormat.PNG:
                    return "png";
                case ImageFormat.WEBP:
                    return "webp";
                case ImageFormat.TIFF:
                    return "tiff";
                case ImageFormat.HEIF:
                    return "heif";
                default:
                    throw new ImageError.UNSUPPORTED_FORMAT("Unsupported output format");
            }
        }
    }
}
/**
 * HEIF Format Detection Implementation
 *
 * Implements the HeifFormatDetector interface for detecting and validating
 * HEIF/HEIC image files in the Scramble application.
 */

using Scramble.Contracts;

namespace Scramble {

    public class HeifFormatDetectorImpl : Object, HeifFormatDetector {

        /**
         * Check if a file is a supported HEIF/HEIC format
         */
        public bool is_heif_format(string file_path) throws IOError, FormatError {
            // Check if file exists
            var file = File.new_for_path(file_path);
            if (!file.query_exists()) {
                throw new IOError.NOT_FOUND("File not found: %s".printf(file_path));
            }

            // Check file extension first (quick check)
            string lower_path = file_path.down();
            if (!lower_path.has_suffix(".heif") && !lower_path.has_suffix(".heic")) {
                return false;
            }

            // Try to read file header to validate it's actually a HEIF file
            try {
                var file_stream = file.read();
                var data_stream = new DataInputStream(file_stream);

                // Read first 12 bytes to check HEIF signature
                uint8[] buffer = new uint8[12];
                size_t bytes_read = data_stream.read(buffer);

                if (bytes_read < 12) {
                    return false;
                }

                // Check for HEIF file signature
                // HEIF files start with a 4-byte size, then "ftyp", then brand
                if (buffer[4] == 'f' && buffer[5] == 't' &&
                    buffer[6] == 'y' && buffer[7] == 'p') {

                    // Check for HEIF-specific brands
                    string brand = ((string) buffer[8:12]).make_valid();
                    return (brand == "heic" || brand == "heix" ||
                           brand == "hevc" || brand == "hevx" ||
                           brand == "heim" || brand == "heis" ||
                           brand == "avif" || brand == "avis");
                }

                file_stream.close();
            } catch (Error e) {
                throw new FormatError.CORRUPTED_FILE("Cannot read file header: %s".printf(e.message));
            }

            return false;
        }

        /**
         * Determine the specific HEIF variant (HEIF vs HEIC)
         */
        public HeifVariant get_heif_variant(string file_path) throws IOError, FormatError {
            if (!is_heif_format(file_path)) {
                throw new FormatError.UNSUPPORTED_FORMAT("File is not a valid HEIF format: %s".printf(file_path));
            }

            string lower_path = file_path.down();
            if (lower_path.has_suffix(".heic")) {
                return HeifVariant.HEIC;
            } else if (lower_path.has_suffix(".heif")) {
                return HeifVariant.HEIF;
            }

            // Fallback to checking file content
            try {
                var file = File.new_for_path(file_path);
                var file_stream = file.read();
                var data_stream = new DataInputStream(file_stream);

                uint8[] buffer = new uint8[12];
                data_stream.read(buffer);

                string brand = ((string) buffer[8:12]).make_valid();
                if (brand == "heic" || brand == "heix") {
                    return HeifVariant.HEIC;
                } else if (brand == "hevc" || brand == "hevx") {
                    return HeifVariant.HEIF;
                }

                file_stream.close();
            } catch (Error e) {
                // If we can't determine from content, fall back to unknown
            }

            return HeifVariant.UNKNOWN;
        }

        /**
         * Check if GdkPixbuf has HEIF loader support available
         */
        public bool has_gdkpixbuf_heif_support() {
            // Check if heif-gdk-pixbuf loader is available
            try {
                // Try to get supported formats from GdkPixbuf
                SList<weak Gdk.PixbufFormat> formats = Gdk.Pixbuf.get_formats();

                foreach (var format in formats) {
                    string[] mime_types = format.get_mime_types();
                    foreach (string mime_type in mime_types) {
                        if (mime_type == "image/heif" || mime_type == "image/heic") {
                            return true;
                        }
                    }

                    string[] extensions = format.get_extensions();
                    foreach (string ext in extensions) {
                        if (ext == "heif" || ext == "heic") {
                            return true;
                        }
                    }
                }
            } catch (Error e) {
                warning("Error checking GdkPixbuf HEIF support: %s", e.message);
            }

            return false;
        }

        /**
         * Detect if HEIF file contains multiple images (sequence)
         *
         * Note: This is a basic implementation. A full implementation would
         * require libheif integration to properly parse the container.
         */
        public int get_image_count(string file_path) throws IOError, FormatError {
            if (!is_heif_format(file_path)) {
                throw new FormatError.UNSUPPORTED_FORMAT("File is not a valid HEIF format: %s".printf(file_path));
            }

            // For now, return 1 for single images
            // TODO: Implement proper sequence detection using libheif
            // This would require:
            // 1. Initialize heif_context
            // 2. Read file into context
            // 3. Call heif_context_get_number_of_top_level_images()
            // 4. Return the count

            // Basic implementation - assume single image for now
            return 1;
        }

        /**
         * Get the index of the primary image in a HEIF sequence
         */
        public int get_primary_image_index(string file_path) throws IOError, FormatError {
            if (!is_heif_format(file_path)) {
                throw new FormatError.UNSUPPORTED_FORMAT("File is not a valid HEIF format: %s".printf(file_path));
            }

            // For single images, primary index is always 0
            int image_count = get_image_count(file_path);
            if (image_count == 1) {
                return 0;
            }

            // TODO: Implement proper primary image detection using libheif
            // This would require:
            // 1. Get all top-level image handles
            // 2. Check which one is marked as primary
            // 3. Return its index

            // Basic implementation - assume first image is primary
            return 0;
        }
    }
}
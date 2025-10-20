using GLib;

namespace Scramble {
    /**
     * Validates image file formats using magic number (file signature) analysis
     *
     * This class provides security-critical format validation by checking file
     * headers against known magic numbers, preventing malicious files with fake
     * extensions from being processed.
     */
    public class MagicNumberValidator : Object {

        /**
         * Validate that a file's actual format matches its claimed extension
         *
         * @param path File path to validate
         * @param extension Expected file extension (e.g., "jpg", "png")
         * @return true if format matches extension, false otherwise
         * @throws Error if file cannot be read or format validation fails
         */
        public static bool validate_format(string path, string extension) throws Error {
            var file = File.new_for_path(path);

            if (!file.query_exists()) {
                throw new FileError.NOENT(_("File does not exist: %s").printf(path));
            }

            var ext_lower = extension.down().replace(".", "");

            // Validate format based on extension
            switch (ext_lower) {
                case "jpg":
                case "jpeg":
                    return validate_jpeg(file);

                case "png":
                    return validate_png(file);

                case "webp":
                    return validate_webp(file);

                case "tif":
                case "tiff":
                    return validate_tiff(file);

                case "heif":
                case "heic":
                    return validate_heif(file);

                default:
                    warning("Unknown format extension: %s", extension);
                    return false;
            }
        }

        /**
         * Validate JPEG format by checking magic number
         *
         * JPEG files start with 0xFF 0xD8 0xFF
         *
         * @param file File to validate
         * @return true if valid JPEG, false otherwise
         * @throws Error if file cannot be read
         */
        private static bool validate_jpeg(File file) throws Error {
            var stream = file.read();
            var buffer = new uint8[3];

            size_t bytes_read;
            stream.read_all(buffer, out bytes_read);

            if (bytes_read < 3) {
                warning("JPEG validation failed: insufficient bytes (%zu)", bytes_read);
                return false;
            }

            bool is_valid = memory_compare(buffer, Constants.JPEG_MAGIC, 3);

            if (!is_valid) {
                warning("JPEG magic number mismatch. Expected: FF D8 FF, Got: %02X %02X %02X",
                        buffer[0], buffer[1], buffer[2]);
            }

            stream.close();
            return is_valid;
        }

        /**
         * Validate PNG format by checking magic number
         *
         * PNG files start with 0x89 'P' 'N' 'G' '\r' '\n' 0x1A '\n'
         *
         * @param file File to validate
         * @return true if valid PNG, false otherwise
         * @throws Error if file cannot be read
         */
        private static bool validate_png(File file) throws Error {
            var stream = file.read();
            var buffer = new uint8[8];

            size_t bytes_read;
            stream.read_all(buffer, out bytes_read);

            if (bytes_read < 8) {
                warning("PNG validation failed: insufficient bytes (%zu)", bytes_read);
                return false;
            }

            bool is_valid = memory_compare(buffer, Constants.PNG_MAGIC, 8);

            if (!is_valid) {
                warning("PNG magic number mismatch. Expected PNG signature");
            }

            stream.close();
            return is_valid;
        }

        /**
         * Validate WebP format by checking RIFF container and WEBP signature
         *
         * WebP files start with:
         * - Bytes 0-3: 'R' 'I' 'F' 'F' (container)
         * - Bytes 4-7: file size (little-endian)
         * - Bytes 8-11: 'W' 'E' 'B' 'P' (format)
         *
         * @param file File to validate
         * @return true if valid WebP, false otherwise
         * @throws Error if file cannot be read
         */
        private static bool validate_webp(File file) throws Error {
            var stream = file.read();
            var buffer = new uint8[12];

            size_t bytes_read;
            stream.read_all(buffer, out bytes_read);

            if (bytes_read < 12) {
                warning("WebP validation failed: insufficient bytes (%zu)", bytes_read);
                return false;
            }

            // Check RIFF header (bytes 0-3)
            var riff_buffer = buffer[0:4];
            bool has_riff = memory_compare(riff_buffer, Constants.WEBP_RIFF, 4);

            // Check WEBP signature (bytes 8-11)
            var webp_buffer = buffer[8:12];
            bool has_webp = memory_compare(webp_buffer, Constants.WEBP_WEBP, 4);

            bool is_valid = has_riff && has_webp;

            if (!is_valid) {
                warning("WebP validation failed. RIFF: %s, WEBP: %s",
                        has_riff.to_string(), has_webp.to_string());
            }

            stream.close();
            return is_valid;
        }

        /**
         * Validate TIFF format by checking magic number (both endianness)
         *
         * TIFF files can be:
         * - Little-endian: 'I' 'I' 0x2A 0x00
         * - Big-endian: 'M' 'M' 0x00 0x2A
         *
         * @param file File to validate
         * @return true if valid TIFF, false otherwise
         * @throws Error if file cannot be read
         */
        private static bool validate_tiff(File file) throws Error {
            var stream = file.read();
            var buffer = new uint8[4];

            size_t bytes_read;
            stream.read_all(buffer, out bytes_read);

            if (bytes_read < 4) {
                warning("TIFF validation failed: insufficient bytes (%zu)", bytes_read);
                return false;
            }

            // Check for either little-endian or big-endian TIFF
            bool is_le = memory_compare(buffer, Constants.TIFF_LE, 4);
            bool is_be = memory_compare(buffer, Constants.TIFF_BE, 4);

            bool is_valid = is_le || is_be;

            if (!is_valid) {
                warning("TIFF magic number mismatch. Got: %02X %02X %02X %02X",
                        buffer[0], buffer[1], buffer[2], buffer[3]);
            }

            stream.close();
            return is_valid;
        }

        /**
         * Validate HEIF/HEIC format by checking ftyp box and brand
         *
         * HEIF/HEIC files are ISO Base Media File Format (BMFF) containers:
         * - Bytes 0-3: Box size (big-endian uint32)
         * - Bytes 4-7: 'f' 't' 'y' 'p' (box type)
         * - Bytes 8-11: Major brand (e.g., "heic", "mif1")
         *
         * @param file File to validate
         * @return true if valid HEIF/HEIC, false otherwise
         * @throws Error if file cannot be read
         */
        private static bool validate_heif(File file) throws Error {
            var stream = file.read();
            var buffer = new uint8[12];

            size_t bytes_read;
            stream.read_all(buffer, out bytes_read);

            if (bytes_read < 12) {
                warning("HEIF validation failed: insufficient bytes (%zu)", bytes_read);
                return false;
            }

            // Check ftyp box signature (bytes 4-7)
            var ftyp_buffer = buffer[4:8];
            bool has_ftyp = memory_compare(ftyp_buffer, Constants.HEIF_FTYP, 4);

            if (!has_ftyp) {
                warning("HEIF validation failed: missing ftyp box");
                return false;
            }

            // Extract brand (bytes 8-11)
            var brand = "%c%c%c%c".printf(buffer[8], buffer[9], buffer[10], buffer[11]);

            // Check if brand matches known HEIF brands
            bool valid_brand = false;
            foreach (var known_brand in Constants.HEIF_BRANDS) {
                if (brand == known_brand) {
                    valid_brand = true;
                    break;
                }
            }

            if (!valid_brand) {
                warning("HEIF validation: unrecognized brand '%s'", brand);
            }

            stream.close();
            return valid_brand;
        }

        /**
         * Compare two byte arrays for equality
         *
         * @param a First byte array
         * @param b Second byte array
         * @param len Number of bytes to compare
         * @return true if arrays match for len bytes, false otherwise
         */
        private static bool memory_compare(uint8[] a, uint8[] b, int len) {
            if (a.length < len || b.length < len) {
                return false;
            }

            for (int i = 0; i < len; i++) {
                if (a[i] != b[i]) {
                    return false;
                }
            }

            return true;
        }

        /**
         * Get a human-readable error message for format validation failure
         *
         * @param path File path that failed validation
         * @param claimed_ext Extension the file claimed to be
         * @return Localized error message
         */
        public static string get_validation_error_message(string path, string claimed_ext) {
            var filename = Path.get_basename(path);
            return _("File '%s' does not appear to be a valid %s image. The file may be corrupted or have an incorrect extension.")
                   .printf(filename, claimed_ext.up());
        }
    }
}

/**
 * HEIF/HEIC Format Detection Interface
 *
 * Defines the contract for detecting and validating HEIF/HEIC image files.
 * This interface extends the existing format detection system in Scramble.
 */

namespace Scramble.Contracts {

    /**
     * Interface for HEIF/HEIC format detection and validation
     */
    public interface HeifFormatDetector : Object {

        /**
         * Check if a file is a supported HEIF/HEIC format
         *
         * @param file_path Absolute path to the file to check
         * @return true if file is a valid HEIF/HEIC image, false otherwise
         * @throws IOError if file cannot be accessed
         * @throws FormatError if file is corrupted or invalid
         */
        public abstract bool is_heif_format(string file_path) throws IOError, FormatError;

        /**
         * Determine the specific HEIF variant (HEIF vs HEIC)
         *
         * @param file_path Absolute path to the validated HEIF file
         * @return HeifVariant enum indicating specific format type
         * @throws IOError if file cannot be accessed
         * @throws FormatError if file is not a valid HEIF file
         */
        public abstract HeifVariant get_heif_variant(string file_path) throws IOError, FormatError;

        /**
         * Check if GdkPixbuf has HEIF loader support available
         *
         * @return true if heif-gdk-pixbuf loader is installed and functional
         */
        public abstract bool has_gdkpixbuf_heif_support();

        /**
         * Detect if HEIF file contains multiple images (sequence)
         *
         * @param file_path Absolute path to the HEIF file
         * @return number of images in the container (1 for single images)
         * @throws IOError if file cannot be accessed
         * @throws FormatError if file structure is invalid
         */
        public abstract int get_image_count(string file_path) throws IOError, FormatError;

        /**
         * Get the index of the primary image in a HEIF sequence
         *
         * @param file_path Absolute path to the HEIF file
         * @return zero-based index of the primary image
         * @throws IOError if file cannot be accessed
         * @throws FormatError if file has no primary image designated
         */
        public abstract int get_primary_image_index(string file_path) throws IOError, FormatError;
    }

    /**
     * HEIF format variant enumeration
     */
    public enum HeifVariant {
        HEIF,   // Standard HEIF format
        HEIC,   // Apple's HEIC implementation
        UNKNOWN // Could not determine specific variant
    }

    /**
     * Format-related error conditions
     */
    public errordomain FormatError {
        UNSUPPORTED_FORMAT,
        CORRUPTED_FILE,
        MISSING_DEPENDENCY,
        INVALID_SEQUENCE
    }
}
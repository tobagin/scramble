/**
 * HEIF/HEIC Image Processing Interface
 *
 * Defines the contract for loading, displaying, and saving HEIF/HEIC images.
 * Integrates with GdkPixbuf for seamless image handling in the GTK4 application.
 */

namespace Scramble.Contracts {

    /**
     * Interface for HEIF/HEIC image processing operations
     */
    public interface HeifImageProcessor : Object {

        /**
         * Load HEIF/HEIC image for display in GTK Picture widget
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return GdkPixbuf that can be displayed in Gtk.Picture
         * @throws IOError if file cannot be accessed
         * @throws ImageError if image cannot be decoded
         */
        public abstract Gdk.Pixbuf load_image(string file_path) throws IOError, ImageError;

        /**
         * Load specific image from HEIF sequence
         *
         * @param file_path Absolute path to the HEIF file
         * @param image_index Zero-based index of the image to load
         * @return GdkPixbuf for the specified image
         * @throws IOError if file cannot be accessed
         * @throws ImageError if image cannot be decoded
         * @throws IndexError if image_index is out of range
         */
        public abstract Gdk.Pixbuf load_image_by_index(string file_path, int image_index) throws IOError, ImageError, IndexError;

        /**
         * Save clean copy of HEIF/HEIC image without metadata
         *
         * @param source_path Path to original HEIF/HEIC file
         * @param output_path Path where clean copy should be saved
         * @param output_format Target format for clean copy (JPEG, PNG, etc.)
         * @param quality Quality setting for lossy formats (0-100)
         * @throws IOError if files cannot be accessed
         * @throws ImageError if image processing fails
         */
        public abstract void save_clean_copy(string source_path, string output_path, ImageFormat output_format, int quality = 90) throws IOError, ImageError;

        /**
         * Save clean copy of specific image from HEIF sequence
         *
         * @param source_path Path to original HEIF file
         * @param image_index Zero-based index of the image to save
         * @param output_path Path where clean copy should be saved
         * @param output_format Target format for clean copy
         * @param quality Quality setting for lossy formats (0-100)
         * @throws IOError if files cannot be accessed
         * @throws ImageError if image processing fails
         * @throws IndexError if image_index is out of range
         */
        public abstract void save_clean_copy_by_index(string source_path, int image_index, string output_path, ImageFormat output_format, int quality = 90) throws IOError, ImageError, IndexError;

        /**
         * Get image dimensions without loading full image data
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return ImageDimensions struct with width and height
         * @throws IOError if file cannot be accessed
         * @throws ImageError if image headers cannot be read
         */
        public abstract ImageDimensions get_image_dimensions(string file_path) throws IOError, ImageError;

        /**
         * Check if HEIF file can be processed by current system
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return ProcessingCapability indicating what operations are supported
         * @throws IOError if file cannot be accessed
         */
        public abstract ProcessingCapability check_processing_capability(string file_path) throws IOError;

        /**
         * Validate HEIF file integrity
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return true if file is valid and can be processed
         * @throws IOError if file cannot be accessed
         */
        public abstract bool validate_file_integrity(string file_path) throws IOError;
    }

    /**
     * Image dimensions structure
     */
    public struct ImageDimensions {
        public int width;
        public int height;

        public ImageDimensions(int w, int h) {
            width = w;
            height = h;
        }

        public string to_string() {
            return "%d × %d".printf(width, height);
        }
    }

    /**
     * Supported output formats for clean copies
     */
    public enum ImageFormat {
        JPEG,
        PNG,
        WEBP,
        TIFF,
        HEIF  // For format-preserving clean copies
    }

    /**
     * Processing capability levels
     */
    public enum ProcessingCapability {
        FULL_SUPPORT,      // Complete read/write/metadata operations
        READ_ONLY,         // Can load and display but not save
        METADATA_ONLY,     // Can extract metadata but not display
        NO_SUPPORT         // Cannot process this file
    }

    /**
     * Image processing error conditions
     */
    public errordomain ImageError {
        DECODE_FAILED,
        ENCODE_FAILED,
        UNSUPPORTED_FORMAT,
        CORRUPTED_IMAGE,
        INSUFFICIENT_MEMORY,
        MISSING_CODEC
    }

    /**
     * Quality settings for different output formats
     */
    public class QualitySettings : Object {
        public static int get_default_quality(ImageFormat format) {
            switch (format) {
                case ImageFormat.JPEG:
                    return 90;
                case ImageFormat.WEBP:
                    return 85;
                case ImageFormat.PNG:
                    return 100;  // PNG is lossless
                case ImageFormat.TIFF:
                    return 100;  // TIFF is typically lossless
                case ImageFormat.HEIF:
                    return 90;
                default:
                    return 90;
            }
        }

        public static bool is_lossy_format(ImageFormat format) {
            return format == ImageFormat.JPEG || format == ImageFormat.WEBP || format == ImageFormat.HEIF;
        }

        public static string get_file_extension(ImageFormat format) {
            switch (format) {
                case ImageFormat.JPEG:
                    return ".jpg";
                case ImageFormat.PNG:
                    return ".png";
                case ImageFormat.WEBP:
                    return ".webp";
                case ImageFormat.TIFF:
                    return ".tiff";
                case ImageFormat.HEIF:
                    return ".heif";
                default:
                    return ".jpg";
            }
        }
    }
}
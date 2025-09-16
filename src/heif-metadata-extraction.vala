/**
 * HEIF/HEIC Metadata Extraction Interface
 *
 * Defines the contract for extracting metadata from HEIF/HEIC image files.
 * Extends the existing GExiv2-based metadata system to support HEIF formats.
 */

namespace Scramble.Contracts {

    /**
     * Interface for HEIF/HEIC metadata extraction operations
     */
    public interface HeifMetadataExtractor : Object {

        /**
         * Extract all metadata from a HEIF/HEIC file
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return HeifMetadataInfo containing all extracted metadata
         * @throws IOError if file cannot be accessed
         * @throws MetadataError if metadata cannot be extracted
         */
        public abstract HeifMetadataInfo extract_metadata(string file_path) throws IOError, MetadataError;

        /**
         * Extract metadata from specific image in a HEIF sequence
         *
         * @param file_path Absolute path to the HEIF file
         * @param image_index Zero-based index of the image in sequence
         * @return HeifMetadataInfo containing metadata for the specified image
         * @throws IOError if file cannot be accessed
         * @throws MetadataError if metadata cannot be extracted
         * @throws IndexError if image_index is out of range
         */
        public abstract HeifMetadataInfo extract_metadata_by_index(string file_path, int image_index) throws IOError, MetadataError, IndexError;

        /**
         * Check if file contains any metadata
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return true if any EXIF, XMP, or IPTC metadata is present
         * @throws IOError if file cannot be accessed
         */
        public abstract bool has_metadata(string file_path) throws IOError;

        /**
         * Get list of all metadata tags present in file
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @return Array of tag names (EXIF, XMP, IPTC format)
         * @throws IOError if file cannot be accessed
         * @throws MetadataError if metadata cannot be read
         */
        public abstract string[] get_available_tags(string file_path) throws IOError, MetadataError;

        /**
         * Extract specific metadata tag value
         *
         * @param file_path Absolute path to the HEIF/HEIC file
         * @param tag_name Name of the metadata tag to extract
         * @return String value of the tag, or null if not present
         * @throws IOError if file cannot be accessed
         * @throws MetadataError if tag cannot be read
         */
        public abstract string? get_tag_value(string file_path, string tag_name) throws IOError, MetadataError;
    }

    /**
     * Comprehensive metadata information extracted from HEIF/HEIC files
     */
    public class HeifMetadataInfo : Object {

        // File Information
        public string file_path { get; set; }
        public string file_name { get; set; }
        public int64 file_size { get; set; }
        public DateTime? file_modified { get; set; }

        // Image Properties
        public int image_width { get; set; }
        public int image_height { get; set; }
        public string color_profile { get; set; }
        public int bit_depth { get; set; }

        // Camera Information (EXIF)
        public string? camera_make { get; set; }
        public string? camera_model { get; set; }
        public string? lens_model { get; set; }
        public string? focal_length { get; set; }
        public string? aperture { get; set; }
        public string? shutter_speed { get; set; }
        public string? iso_speed { get; set; }
        public DateTime? date_taken { get; set; }

        // Location Information (GPS)
        public double? gps_latitude { get; set; }
        public double? gps_longitude { get; set; }
        public double? gps_altitude { get; set; }
        public string? location_name { get; set; }

        // Descriptive Metadata (IPTC/XMP)
        public string? title { get; set; }
        public string? description { get; set; }
        public string? keywords { get; set; }
        public string? copyright { get; set; }
        public string? creator { get; set; }

        // Raw Metadata Collections
        public HashTable<string, string> exif_tags { get; set; }
        public HashTable<string, string> xmp_tags { get; set; }
        public HashTable<string, string> iptc_tags { get; set; }

        // HEIF-Specific Information
        public bool is_sequence { get; set; }
        public int image_count { get; set; }
        public int current_image_index { get; set; }
        public HeifVariant format_variant { get; set; }

        public HeifMetadataInfo() {
            exif_tags = new HashTable<string, string>(str_hash, str_equal);
            xmp_tags = new HashTable<string, string>(str_hash, str_equal);
            iptc_tags = new HashTable<string, string>(str_hash, str_equal);
        }

        /**
         * Check if any metadata is present
         */
        public bool has_any_metadata() {
            return exif_tags.size() > 0 || xmp_tags.size() > 0 || iptc_tags.size() > 0;
        }

        /**
         * Get formatted location string if GPS data is available
         */
        public string? get_formatted_location() {
            if (gps_latitude != null && gps_longitude != null) {
                return "%.6f, %.6f".printf(gps_latitude, gps_longitude);
            }
            return location_name;
        }

        /**
         * Get formatted camera information string
         */
        public string? get_formatted_camera() {
            if (camera_make != null && camera_model != null) {
                return "%s %s".printf(camera_make, camera_model);
            }
            return camera_make ?? camera_model;
        }
    }

    /**
     * Metadata extraction error conditions
     */
    public errordomain MetadataError {
        EXTRACTION_FAILED,
        UNSUPPORTED_FORMAT,
        CORRUPTED_METADATA,
        MISSING_BMFF_SUPPORT
    }

    /**
     * Index-related error conditions
     */
    public errordomain IndexError {
        OUT_OF_RANGE,
        INVALID_INDEX
    }
}
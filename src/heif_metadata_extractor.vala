/**
 * HEIF Metadata Extraction Implementation
 *
 * Implements the HeifMetadataExtractor interface using GExiv2 with BMFF support
 * to extract metadata from HEIF/HEIC image files.
 */

using Scramble.Contracts;

namespace Scramble {

    public class HeifMetadataExtractorImpl : Object, HeifMetadataExtractor {

        /**
         * Extract all metadata from a HEIF/HEIC file
         */
        public HeifMetadataInfo extract_metadata(string file_path) throws IOError, MetadataError {
            // Verify file exists
            var file = File.new_for_path(file_path);
            if (!file.query_exists()) {
                throw new IOError.NOT_FOUND("File not found: %s".printf(file_path));
            }

            // Create metadata info object
            var metadata_info = new HeifMetadataInfo();
            metadata_info.file_path = file_path;
            metadata_info.file_name = file.get_basename();

            try {
                // Get file information
                var file_info = file.query_info(FileAttribute.STANDARD_SIZE + "," +
                                               FileAttribute.TIME_MODIFIED,
                                               FileQueryInfoFlags.NONE);
                metadata_info.file_size = file_info.get_size();
                metadata_info.file_modified = file_info.get_modification_date_time();

                // Initialize GExiv2 metadata
                var gexiv_metadata = new GExiv2.Metadata();

                // Open the HEIF file with GExiv2 (requires BMFF support)
                if (!gexiv_metadata.open_path(file_path)) {
                    throw new MetadataError.EXTRACTION_FAILED("Cannot open file with GExiv2: %s".printf(file_path));
                }

                // Extract basic image properties
                extract_image_properties(gexiv_metadata, metadata_info);

                // Extract EXIF metadata
                extract_exif_metadata(gexiv_metadata, metadata_info);

                // Extract XMP metadata
                extract_xmp_metadata(gexiv_metadata, metadata_info);

                // Extract IPTC metadata
                extract_iptc_metadata(gexiv_metadata, metadata_info);

                // Set HEIF-specific information
                metadata_info.format_variant = get_format_variant(file_path);
                metadata_info.is_sequence = false; // TODO: Implement sequence detection
                metadata_info.image_count = 1;     // TODO: Get actual count
                metadata_info.current_image_index = 0;

            } catch (GLib.Error e) {
                if ("BMFF" in e.message || "not supported" in e.message) {
                    throw new MetadataError.MISSING_BMFF_SUPPORT("GExiv2 BMFF support not enabled: %s".printf(e.message));
                }
                throw new MetadataError.EXTRACTION_FAILED("Metadata extraction failed: %s".printf(e.message));
            }

            return metadata_info;
        }

        /**
         * Extract metadata from specific image in a HEIF sequence
         */
        public HeifMetadataInfo extract_metadata_by_index(string file_path, int image_index) throws IOError, MetadataError, IndexError {
            // For now, only support single images (index 0)
            if (image_index != 0) {
                throw new IndexError.OUT_OF_RANGE("Image index %d out of range for single image file".printf(image_index));
            }

            var metadata_info = extract_metadata(file_path);
            metadata_info.current_image_index = image_index;
            return metadata_info;
        }

        /**
         * Check if file contains any metadata
         */
        public bool has_metadata(string file_path) throws IOError {
            try {
                var gexiv_metadata = new GExiv2.Metadata();
                if (!gexiv_metadata.open_path(file_path)) {
                    return false;
                }

                // Check for any EXIF, XMP, or IPTC tags
                string[] exif_tags = gexiv_metadata.get_exif_tags();
                string[] xmp_tags = gexiv_metadata.get_xmp_tags();
                string[] iptc_tags = gexiv_metadata.get_iptc_tags();

                return (exif_tags.length > 0 || xmp_tags.length > 0 || iptc_tags.length > 0);

            } catch (Error e) {
                warning("Error checking metadata presence: %s", e.message);
                return false;
            }
        }

        /**
         * Get list of all metadata tags present in file
         */
        public string[] get_available_tags(string file_path) throws IOError, MetadataError {
            try {
                var gexiv_metadata = new GExiv2.Metadata();
                if (!gexiv_metadata.open_path(file_path)) {
                    throw new MetadataError.EXTRACTION_FAILED("Cannot open file with GExiv2");
                }

                // Collect all tags
                string[] all_tags = {};

                string[] exif_tags = gexiv_metadata.get_exif_tags();
                foreach (string tag in exif_tags) {
                    all_tags += tag;
                }

                string[] xmp_tags = gexiv_metadata.get_xmp_tags();
                foreach (string tag in xmp_tags) {
                    all_tags += tag;
                }

                string[] iptc_tags = gexiv_metadata.get_iptc_tags();
                foreach (string tag in iptc_tags) {
                    all_tags += tag;
                }

                return all_tags;

            } catch (Error e) {
                throw new MetadataError.EXTRACTION_FAILED("Failed to get tags: %s".printf(e.message));
            }
        }

        /**
         * Extract specific metadata tag value
         */
        public string? get_tag_value(string file_path, string tag_name) throws IOError, MetadataError {
            try {
                var gexiv_metadata = new GExiv2.Metadata();
                if (!gexiv_metadata.open_path(file_path)) {
                    throw new MetadataError.EXTRACTION_FAILED("Cannot open file with GExiv2");
                }

                if (gexiv_metadata.has_tag(tag_name)) {
                    return gexiv_metadata.get_tag_string(tag_name);
                }

                return null;

            } catch (Error e) {
                throw new MetadataError.EXTRACTION_FAILED("Failed to get tag value: %s".printf(e.message));
            }
        }

        /**
         * Extract basic image properties
         */
        private void extract_image_properties(GExiv2.Metadata gexiv_metadata, HeifMetadataInfo metadata_info) {
            // Get image dimensions
            if (gexiv_metadata.has_tag("Exif.Photo.PixelXDimension")) {
                metadata_info.image_width = (int)gexiv_metadata.get_tag_long("Exif.Photo.PixelXDimension");
            }
            if (gexiv_metadata.has_tag("Exif.Photo.PixelYDimension")) {
                metadata_info.image_height = (int)gexiv_metadata.get_tag_long("Exif.Photo.PixelYDimension");
            }

            // Try alternative dimension tags if main ones are not available
            if (metadata_info.image_width == 0 && gexiv_metadata.has_tag("Exif.Image.ImageWidth")) {
                metadata_info.image_width = (int)gexiv_metadata.get_tag_long("Exif.Image.ImageWidth");
            }
            if (metadata_info.image_height == 0 && gexiv_metadata.has_tag("Exif.Image.ImageLength")) {
                metadata_info.image_height = (int)gexiv_metadata.get_tag_long("Exif.Image.ImageLength");
            }

            // Get color profile information
            if (gexiv_metadata.has_tag("Exif.ColorSpace.ColorSpace")) {
                string color_space = gexiv_metadata.get_tag_string("Exif.ColorSpace.ColorSpace");
                metadata_info.color_profile = color_space;
            }
        }

        /**
         * Extract EXIF metadata
         */
        private void extract_exif_metadata(GExiv2.Metadata gexiv_metadata, HeifMetadataInfo metadata_info) {
            // Camera information
            if (gexiv_metadata.has_tag("Exif.Image.Make")) {
                metadata_info.camera_make = gexiv_metadata.get_tag_string("Exif.Image.Make");
            }
            if (gexiv_metadata.has_tag("Exif.Image.Model")) {
                metadata_info.camera_model = gexiv_metadata.get_tag_string("Exif.Image.Model");
            }

            // Lens information
            if (gexiv_metadata.has_tag("Exif.Photo.LensModel")) {
                metadata_info.lens_model = gexiv_metadata.get_tag_string("Exif.Photo.LensModel");
            }

            // Camera settings
            if (gexiv_metadata.has_tag("Exif.Photo.FocalLength")) {
                metadata_info.focal_length = gexiv_metadata.get_tag_string("Exif.Photo.FocalLength");
            }
            if (gexiv_metadata.has_tag("Exif.Photo.FNumber")) {
                metadata_info.aperture = gexiv_metadata.get_tag_string("Exif.Photo.FNumber");
            }
            if (gexiv_metadata.has_tag("Exif.Photo.ExposureTime")) {
                metadata_info.shutter_speed = gexiv_metadata.get_tag_string("Exif.Photo.ExposureTime");
            }
            if (gexiv_metadata.has_tag("Exif.Photo.ISOSpeedRatings")) {
                metadata_info.iso_speed = gexiv_metadata.get_tag_string("Exif.Photo.ISOSpeedRatings");
            }

            // Date taken
            if (gexiv_metadata.has_tag("Exif.Photo.DateTimeOriginal")) {
                string date_str = gexiv_metadata.get_tag_string("Exif.Photo.DateTimeOriginal");
                metadata_info.date_taken = parse_exif_datetime(date_str);
            } else if (gexiv_metadata.has_tag("Exif.Image.DateTime")) {
                string date_str = gexiv_metadata.get_tag_string("Exif.Image.DateTime");
                metadata_info.date_taken = parse_exif_datetime(date_str);
            }

            // GPS information
            if (gexiv_metadata.has_tag("Exif.GPSInfo.GPSLatitude")) {
                metadata_info.gps_latitude = gexiv_metadata.get_gps_latitude();
            }
            if (gexiv_metadata.has_tag("Exif.GPSInfo.GPSLongitude")) {
                metadata_info.gps_longitude = gexiv_metadata.get_gps_longitude();
            }
            if (gexiv_metadata.has_tag("Exif.GPSInfo.GPSAltitude")) {
                metadata_info.gps_altitude = gexiv_metadata.get_gps_altitude();
            }

            // Collect all EXIF tags
            string[] exif_tags = gexiv_metadata.get_exif_tags();
            foreach (string tag in exif_tags) {
                string value = gexiv_metadata.get_tag_string(tag);
                metadata_info.exif_tags.insert(tag, value);
            }
        }

        /**
         * Extract XMP metadata
         */
        private void extract_xmp_metadata(GExiv2.Metadata gexiv_metadata, HeifMetadataInfo metadata_info) {
            // Descriptive metadata
            if (gexiv_metadata.has_tag("Xmp.dc.title")) {
                metadata_info.title = gexiv_metadata.get_tag_string("Xmp.dc.title");
            }
            if (gexiv_metadata.has_tag("Xmp.dc.description")) {
                metadata_info.description = gexiv_metadata.get_tag_string("Xmp.dc.description");
            }
            if (gexiv_metadata.has_tag("Xmp.dc.subject")) {
                metadata_info.keywords = gexiv_metadata.get_tag_string("Xmp.dc.subject");
            }
            if (gexiv_metadata.has_tag("Xmp.dc.rights")) {
                metadata_info.copyright = gexiv_metadata.get_tag_string("Xmp.dc.rights");
            }
            if (gexiv_metadata.has_tag("Xmp.dc.creator")) {
                metadata_info.creator = gexiv_metadata.get_tag_string("Xmp.dc.creator");
            }

            // Collect all XMP tags
            string[] xmp_tags = gexiv_metadata.get_xmp_tags();
            foreach (string tag in xmp_tags) {
                string value = gexiv_metadata.get_tag_string(tag);
                metadata_info.xmp_tags.insert(tag, value);
            }
        }

        /**
         * Extract IPTC metadata
         */
        private void extract_iptc_metadata(GExiv2.Metadata gexiv_metadata, HeifMetadataInfo metadata_info) {
            // Collect all IPTC tags
            string[] iptc_tags = gexiv_metadata.get_iptc_tags();
            foreach (string tag in iptc_tags) {
                string value = gexiv_metadata.get_tag_string(tag);
                metadata_info.iptc_tags.insert(tag, value);
            }
        }

        /**
         * Parse EXIF datetime string into DateTime object
         */
        private DateTime? parse_exif_datetime(string datetime_str) {
            try {
                // EXIF datetime format: "YYYY:MM:DD HH:MM:SS"
                var parts = datetime_str.split(" ");
                if (parts.length != 2) return null;

                var date_parts = parts[0].split(":");
                var time_parts = parts[1].split(":");

                if (date_parts.length != 3 || time_parts.length != 3) return null;

                int year = int.parse(date_parts[0]);
                int month = int.parse(date_parts[1]);
                int day = int.parse(date_parts[2]);
                int hour = int.parse(time_parts[0]);
                int minute = int.parse(time_parts[1]);
                int second = int.parse(time_parts[2]);

                return new DateTime.local(year, month, day, hour, minute, second);

            } catch (Error e) {
                warning("Failed to parse EXIF datetime: %s", e.message);
                return null;
            }
        }

        /**
         * Get format variant from file path
         */
        private HeifVariant get_format_variant(string file_path) {
            string lower_path = file_path.down();
            if (lower_path.has_suffix(".heic")) {
                return HeifVariant.HEIC;
            } else if (lower_path.has_suffix(".heif")) {
                return HeifVariant.HEIF;
            }
            return HeifVariant.UNKNOWN;
        }
    }
}
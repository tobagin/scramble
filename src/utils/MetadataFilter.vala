/**
 * MetadataFilter - Selective metadata removal utility
 * 
 * Provides functionality to selectively remove metadata categories
 * from images using GExiv2, based on user preferences.
 */

namespace Scramble {
    /**
     * Handles selective metadata removal based on user settings
     */
    public class MetadataFilter : Object {
        
        // GPS/Location related tag prefixes
        private static string[] GPS_TAGS = {
            "Exif.GPSInfo",
            "Exif.Image.GPSTag",
            "Xmp.exif.GPS",
            "Iptc.Application2.LocationCode",
            "Iptc.Application2.LocationName",
            "Xmp.iptc.Location",
            "Xmp.photoshop.City",
            "Xmp.photoshop.State",
            "Xmp.photoshop.Country"
        };
        
        // Camera/Device related tag prefixes
        private static string[] CAMERA_TAGS = {
            "Exif.Image.Make",
            "Exif.Image.Model",
            "Exif.Image.BodySerialNumber",
            "Exif.Photo.LensModel",
            "Exif.Photo.LensMake",
            "Exif.Photo.LensSerialNumber",
            "Exif.Photo.CameraOwnerName",
            "Exif.Photo.BodySerialNumber",
            "Exif.Canon",
            "Exif.Nikon",
            "Exif.Sony",
            "Exif.Fujifilm",
            "Exif.Olympus",
            "Exif.Panasonic",
            "Exif.Pentax",
            "Exif.Samsung",
            "Exif.MakerNote",
            "Xmp.aux.Lens",
            "Xmp.aux.SerialNumber",
            "Xmp.exifEX.LensModel",
            "Xmp.exifEX.LensMake"
        };
        
        // Date/Time related tag prefixes
        private static string[] DATETIME_TAGS = {
            "Exif.Image.DateTime",
            "Exif.Photo.DateTimeOriginal",
            "Exif.Photo.DateTimeDigitized",
            "Exif.Image.DateTimeOriginal",
            "Xmp.exif.DateTimeOriginal",
            "Xmp.exif.DateTimeDigitized",
            "Xmp.photoshop.DateCreated",
            "Xmp.xmp.CreateDate",
            "Xmp.xmp.ModifyDate",
            "Xmp.xmp.MetadataDate",
            "Iptc.Application2.DateCreated",
            "Iptc.Application2.TimeCreated",
            "Iptc.Application2.DigitizationDate",
            "Iptc.Application2.DigitizationTime"
        };
        
        // Software/Processing related tag prefixes
        private static string[] SOFTWARE_TAGS = {
            "Exif.Image.Software",
            "Exif.Image.ProcessingSoftware",
            "Xmp.xmp.CreatorTool",
            "Xmp.xmpMM.History",
            "Xmp.xmpMM.DerivedFrom",
            "Xmp.xmpMM.InstanceID",
            "Xmp.xmpMM.DocumentID",
            "Xmp.xmpMM.OriginalDocumentID",
            "Xmp.crs",  // Camera Raw Settings
            "Xmp.tiff.Software"
        };
        
        // Author/Copyright related tag prefixes
        private static string[] AUTHOR_TAGS = {
            "Exif.Image.Artist",
            "Exif.Image.Copyright",
            "Exif.Photo.CameraOwnerName",
            "Iptc.Application2.Byline",
            "Iptc.Application2.BylineTitle",
            "Iptc.Application2.Credit",
            "Iptc.Application2.Source",
            "Iptc.Application2.Copyright",
            "Iptc.Application2.Contact",
            "Xmp.dc.creator",
            "Xmp.dc.rights",
            "Xmp.dc.publisher",
            "Xmp.photoshop.AuthorsPosition",
            "Xmp.photoshop.Credit",
            "Xmp.photoshop.Source",
            "Xmp.xmpRights",
            "Xmp.plus"  // PLUS licensing
        };
        
        /**
         * Apply metadata filter based on user settings
         * 
         * @param metadata GExiv2 metadata object to modify
         * @param settings GLib.Settings to read preferences from
         * @return Number of tags removed
         */
        public static int apply_filter(GExiv2.Metadata metadata, GLib.Settings settings) {
            int removed_count = 0;
            
            if (settings.get_boolean("remove-gps")) {
                removed_count += remove_tags_by_prefix(metadata, GPS_TAGS);
                // Also clear GPS info using the dedicated method
                try {
                    metadata.delete_gps_info();
                } catch (Error e) {
                    debug("Could not delete GPS info: %s", e.message);
                }
            }
            
            if (settings.get_boolean("remove-camera")) {
                removed_count += remove_tags_by_prefix(metadata, CAMERA_TAGS);
            }
            
            if (settings.get_boolean("remove-datetime")) {
                removed_count += remove_tags_by_prefix(metadata, DATETIME_TAGS);
            }
            
            if (settings.get_boolean("remove-software")) {
                removed_count += remove_tags_by_prefix(metadata, SOFTWARE_TAGS);
            }
            
            if (settings.get_boolean("remove-author")) {
                removed_count += remove_tags_by_prefix(metadata, AUTHOR_TAGS);
            }
            
            return removed_count;
        }
        
        /**
         * Count how many tags would be removed based on current settings
         * 
         * @param metadata GExiv2 metadata object to analyze
         * @param settings GLib.Settings to read preferences from
         * @return Number of tags that would be removed
         */
        public static int count_tags_to_remove(GExiv2.Metadata metadata, GLib.Settings settings) {
            int count = 0;
            
            if (settings.get_boolean("remove-gps")) {
                count += count_matching_tags(metadata, GPS_TAGS);
            }
            
            if (settings.get_boolean("remove-camera")) {
                count += count_matching_tags(metadata, CAMERA_TAGS);
            }
            
            if (settings.get_boolean("remove-datetime")) {
                count += count_matching_tags(metadata, DATETIME_TAGS);
            }
            
            if (settings.get_boolean("remove-software")) {
                count += count_matching_tags(metadata, SOFTWARE_TAGS);
            }
            
            if (settings.get_boolean("remove-author")) {
                count += count_matching_tags(metadata, AUTHOR_TAGS);
            }
            
            return count;
        }
        
        /**
         * Check if all removal options are enabled (equivalent to remove all)
         * 
         * @param settings GLib.Settings to check
         * @return true if all metadata types will be removed
         */
        public static bool is_remove_all(GLib.Settings settings) {
            return settings.get_boolean("remove-gps") &&
                   settings.get_boolean("remove-camera") &&
                   settings.get_boolean("remove-datetime") &&
                   settings.get_boolean("remove-software") &&
                   settings.get_boolean("remove-author");
        }
        
        /**
         * Check if no removal options are enabled (keep all metadata)
         * 
         * @param settings GLib.Settings to check
         * @return true if no metadata will be removed
         */
        public static bool is_keep_all(GLib.Settings settings) {
            return !settings.get_boolean("remove-gps") &&
                   !settings.get_boolean("remove-camera") &&
                   !settings.get_boolean("remove-datetime") &&
                   !settings.get_boolean("remove-software") &&
                   !settings.get_boolean("remove-author");
        }
        
        /**
         * Remove tags matching given prefixes from metadata
         * 
         * @param metadata GExiv2 metadata object
         * @param prefixes Array of tag prefixes to match
         * @return Number of tags removed
         */
        private static int remove_tags_by_prefix(GExiv2.Metadata metadata, string[] prefixes) {
            int removed = 0;
            
            // Process EXIF tags
            try {
                var exif_tags = metadata.get_exif_tags();
                foreach (var tag in exif_tags) {
                    if (tag_matches_prefixes(tag, prefixes)) {
                        try {
                            metadata.clear_tag(tag);
                            removed++;
                        } catch (Error e) {
                            debug("Could not clear tag %s: %s", tag, e.message);
                        }
                    }
                }
            } catch (Error e) {
                debug("Error getting EXIF tags: %s", e.message);
            }
            
            // Process XMP tags
            try {
                var xmp_tags = metadata.get_xmp_tags();
                foreach (var tag in xmp_tags) {
                    if (tag_matches_prefixes(tag, prefixes)) {
                        try {
                            metadata.clear_tag(tag);
                            removed++;
                        } catch (Error e) {
                            debug("Could not clear tag %s: %s", tag, e.message);
                        }
                    }
                }
            } catch (Error e) {
                debug("Error getting XMP tags: %s", e.message);
            }
            
            // Process IPTC tags
            try {
                var iptc_tags = metadata.get_iptc_tags();
                foreach (var tag in iptc_tags) {
                    if (tag_matches_prefixes(tag, prefixes)) {
                        try {
                            metadata.clear_tag(tag);
                            removed++;
                        } catch (Error e) {
                            debug("Could not clear tag %s: %s", tag, e.message);
                        }
                    }
                }
            } catch (Error e) {
                debug("Error getting IPTC tags: %s", e.message);
            }
            
            return removed;
        }
        
        /**
         * Count tags matching given prefixes
         */
        private static int count_matching_tags(GExiv2.Metadata metadata, string[] prefixes) {
            int count = 0;
            
            try {
                var exif_tags = metadata.get_exif_tags();
                foreach (var tag in exif_tags) {
                    if (tag_matches_prefixes(tag, prefixes)) {
                        count++;
                    }
                }
            } catch (Error e) {
                debug("Error counting EXIF tags: %s", e.message);
            }
            
            try {
                var xmp_tags = metadata.get_xmp_tags();
                foreach (var tag in xmp_tags) {
                    if (tag_matches_prefixes(tag, prefixes)) {
                        count++;
                    }
                }
            } catch (Error e) {
                debug("Error counting XMP tags: %s", e.message);
            }
            
            try {
                var iptc_tags = metadata.get_iptc_tags();
                foreach (var tag in iptc_tags) {
                    if (tag_matches_prefixes(tag, prefixes)) {
                        count++;
                    }
                }
            } catch (Error e) {
                debug("Error counting IPTC tags: %s", e.message);
            }
            
            return count;
        }
        
        /**
         * Check if a tag matches any of the given prefixes
         */
        private static bool tag_matches_prefixes(string tag, string[] prefixes) {
            foreach (var prefix in prefixes) {
                if (tag.has_prefix(prefix)) {
                    return true;
                }
            }
            return false;
        }
    }
}

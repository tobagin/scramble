using Gtk;
using Adw;
using Gdk;

namespace Scramble {
    /**
     * Handles metadata display and management for images
     */
    public class MetadataDisplay : Object {
        private Gtk.ListBox metadata_list;

        // Predefined metadata rows
        private MetadataRow filename_row;
        private MetadataRow filesize_row;
        private MetadataRow dimensions_row;
        private MetadataRow camera_row;
        private MetadataRow datetime_row;
        private MetadataRow location_row;

        // Raw metadata section
        private Adw.ExpanderRow raw_metadata_row;

        public MetadataDisplay(Gtk.ListBox list) {
            metadata_list = list;
            setup_metadata_rows();
        }

        /**
         * Initialize predefined metadata rows with icons
         */
        private void setup_metadata_rows() {
            filename_row = new MetadataRow(_("Filename"), "");
            filename_row.set_icon("document-properties-symbolic");
            metadata_list.append(filename_row);

            filesize_row = new MetadataRow(_("File Size"), "");
            filesize_row.set_icon("folder-symbolic");
            metadata_list.append(filesize_row);

            dimensions_row = new MetadataRow(_("Dimensions"), "");
            dimensions_row.set_icon("image-x-generic-symbolic");
            metadata_list.append(dimensions_row);

            camera_row = new MetadataRow(_("Camera"), "");
            camera_row.set_icon("camera-photo-symbolic");
            metadata_list.append(camera_row);

            datetime_row = new MetadataRow(_("Date Taken"), "");
            datetime_row.set_icon("appointment-soon-symbolic");
            metadata_list.append(datetime_row);

            location_row = new MetadataRow(_("Location"), "");
            location_row.set_icon("mark-location-symbolic");
            metadata_list.append(location_row);

            // Add expandable raw metadata section
            raw_metadata_row = new Adw.ExpanderRow();
            raw_metadata_row.set_title(_("Raw Metadata"));
            raw_metadata_row.set_subtitle(_("Complete EXIF, XMP, and IPTC data"));
            raw_metadata_row.add_prefix(new Gtk.Image.from_icon_name("text-x-generic-symbolic"));
            raw_metadata_row.enable_expansion = false;
            metadata_list.append(raw_metadata_row);
        }

        /**
         * Update metadata display with image file information
         *
         * @param path Absolute path to the image file
         */
        public void update_from_file(string path) {
            update_basic_info(path);
            update_exif_metadata(path);
        }

        /**
         * Update basic file information (size, dimensions, etc.)
         */
        private void update_basic_info(string path) {
            try {
                var texture = Gdk.Texture.from_file(GLib.File.new_for_path(path));
                var f = GLib.File.new_for_path(path);
                var info = f.query_info("standard::size", GLib.FileQueryInfoFlags.NONE);
                var size = info.get_size();

                // Update filename
                filename_row.update_value(GLib.Path.get_basename(path));

                // Update file size
                string size_str;
                if (size < 1024) {
                    size_str = "%s bytes".printf(size.to_string());
                } else if (size < 1024*1024) {
                    size_str = "%.1f KB".printf(size/1024.0);
                } else {
                    size_str = "%.1f MB".printf(size/(1024.0*1024.0));
                }
                filesize_row.update_value(size_str);

                // Update dimensions
                dimensions_row.update_value("%d × %d pixels".printf(texture.get_width(), texture.get_height()));

            } catch (Error e) {
                filename_row.update_value(_("Unable to read"));
                filesize_row.update_value(_("Unknown"));
                dimensions_row.update_value(_("Unknown"));
            }
        }

        /**
         * Update EXIF/XMP/IPTC metadata information
         */
        private void update_exif_metadata(string path) {
#if HAVE_GEXIV2
            try {
                var m = new GExiv2.Metadata();
                m.open_path(path);

                // Update camera info
                string camera_info = "";
                var make = m.get_tag_string("Exif.Image.Make");
                var model = m.get_tag_string("Exif.Image.Model");
                if (make != null && model != null) {
                    camera_info = "%s %s".printf(make.strip(), model.strip());
                } else if (model != null) {
                    camera_info = model.strip();
                } else if (make != null) {
                    camera_info = make.strip();
                }
                camera_row.update_value(camera_info != "" ? camera_info : _("Unknown"));

                // Update date/time
                string datetime_info = "";
                var datetime_original = m.get_tag_string("Exif.Photo.DateTimeOriginal");
                var datetime = m.get_tag_string("Exif.Image.DateTime");
                if (datetime_original != null) {
                    datetime_info = datetime_original.strip();
                } else if (datetime != null) {
                    datetime_info = datetime.strip();
                }
                datetime_row.update_value(datetime_info != "" ? datetime_info : _("Unknown"));

                // Update GPS location
                string location_info = "";
                try {
                    double lat, lon, alt;
                    if (m.get_gps_info(out lat, out lon, out alt)) {
                        location_info = "%.6f, %.6f".printf(lat, lon);
                    }
                } catch (Error e) {
                    // GPS info not available
                }
                location_row.update_value(location_info != "" ? location_info : _("Not available"));

                // Populate raw metadata section
                populate_raw_metadata(m);

            } catch (Error e) {
                camera_row.update_value(_("No metadata"));
                datetime_row.update_value(_("No metadata"));
                location_row.update_value(_("No metadata"));
                clear_raw_metadata();
            }
#else
            camera_row.update_value(_("GExiv2 not available"));
            datetime_row.update_value(_("GExiv2 not available"));
            location_row.update_value(_("GExiv2 not available"));
#endif
        }

        /**
         * Populate raw metadata expandable section
         */
        private void populate_raw_metadata(GExiv2.Metadata metadata) {
            clear_raw_metadata();

            var tag_count = 0;

            // Add EXIF tags
            try {
                var exif_tags = metadata.get_exif_tags();
                foreach (var tag in exif_tags) {
                    var value = metadata.get_tag_string(tag);
                    if (value != null && value.strip() != "") {
                        var raw_row = new MetadataRow(tag, value.strip());
                        raw_metadata_row.add_row(raw_row);
                        tag_count++;
                    }
                }
            } catch (Error e) {
                warning("Error reading EXIF tags: %s", e.message);
            }

            // Add XMP tags
            try {
                var xmp_tags = metadata.get_xmp_tags();
                foreach (var tag in xmp_tags) {
                    var value = metadata.get_tag_string(tag);
                    if (value != null && value.strip() != "") {
                        var raw_row = new MetadataRow(tag, value.strip());
                        raw_metadata_row.add_row(raw_row);
                        tag_count++;
                    }
                }
            } catch (Error e) {
                warning("Error reading XMP tags: %s", e.message);
            }

            // Add IPTC tags
            try {
                var iptc_tags = metadata.get_iptc_tags();
                foreach (var tag in iptc_tags) {
                    var value = metadata.get_tag_string(tag);
                    if (value != null && value.strip() != "") {
                        var raw_row = new MetadataRow(tag, value.strip());
                        raw_metadata_row.add_row(raw_row);
                        tag_count++;
                    }
                }
            } catch (Error e) {
                warning("Error reading IPTC tags: %s", e.message);
            }

            // Update subtitle and enable expansion if there are items
            raw_metadata_row.set_subtitle(_("Complete EXIF, XMP, and IPTC data (%d items)").printf(tag_count));
            raw_metadata_row.enable_expansion = (tag_count > 0);
        }

        /**
         * Clear all metadata rows
         */
        public void clear() {
            filename_row.update_value("");
            filesize_row.update_value("");
            dimensions_row.update_value("");
            camera_row.update_value("");
            datetime_row.update_value("");
            location_row.update_value("");
            clear_raw_metadata();
        }

        /**
         * Clear raw metadata section
         */
        private void clear_raw_metadata() {
            var parent = raw_metadata_row.get_parent() as Gtk.ListBox;
            if (parent != null) {
                parent.remove(raw_metadata_row);

                // Create a new raw metadata row
                raw_metadata_row = new Adw.ExpanderRow();
                raw_metadata_row.set_title(_("Raw Metadata"));
                raw_metadata_row.set_subtitle(_("Complete EXIF, XMP, and IPTC data"));
                raw_metadata_row.enable_expansion = false;

                parent.append(raw_metadata_row);
            }
        }
    }
}

using GLib;

namespace Scramble {
    /**
     * Export metadata to various formats (JSON, CSV)
     */
    public class MetadataExporter : Object {

        /**
         * Export format types
         */
        public enum ExportFormat {
            JSON,
            CSV
        }

        /**
         * Metadata entry for export
         */
        public class MetadataEntry {
            public string tag { get; set; }
            public string value { get; set; }
            public string metadata_type { get; set; } // EXIF, XMP, IPTC

            public MetadataEntry(string tag, string value, string metadata_type) {
                this.tag = tag;
                this.value = value;
                this.metadata_type = metadata_type;
            }
        }

        /**
         * Extract metadata from an image file
         *
         * @param image_path Path to the image file
         * @return List of metadata entries
         */
        public static List<MetadataEntry>? extract_metadata(string image_path) {
#if HAVE_GEXIV2
            try {
                var metadata = new GExiv2.Metadata();
                metadata.open_path(image_path);

                var entries = new List<MetadataEntry>();

                // Extract EXIF data
                try {
                    var exif_tags = metadata.get_exif_tags();
                    foreach (var tag in exif_tags) {
                        try {
                            var value = metadata.get_tag_string(tag);
                            if (value != null && value.strip() != "") {
                                entries.append(new MetadataEntry(tag, value.strip(), "EXIF"));
                            }
                        } catch (Error e) {
                            warning("Error reading EXIF tag %s: %s", tag, e.message);
                        }
                    }
                } catch (Error e) {
                    warning("Error reading EXIF tags: %s", e.message);
                }

                // Extract XMP data
                try {
                    var xmp_tags = metadata.get_xmp_tags();
                    foreach (var tag in xmp_tags) {
                        try {
                            var value = metadata.get_tag_string(tag);
                            if (value != null && value.strip() != "") {
                                entries.append(new MetadataEntry(tag, value.strip(), "XMP"));
                            }
                        } catch (Error e) {
                            warning("Error reading XMP tag %s: %s", tag, e.message);
                        }
                    }
                } catch (Error e) {
                    warning("Error reading XMP tags: %s", e.message);
                }

                // Extract IPTC data
                try {
                    var iptc_tags = metadata.get_iptc_tags();
                    foreach (var tag in iptc_tags) {
                        try {
                            var value = metadata.get_tag_string(tag);
                            if (value != null && value.strip() != "") {
                                entries.append(new MetadataEntry(tag, value.strip(), "IPTC"));
                            }
                        } catch (Error e) {
                            warning("Error reading IPTC tag %s: %s", tag, e.message);
                        }
                    }
                } catch (Error e) {
                    warning("Error reading IPTC tags: %s", e.message);
                }

                return entries;
            } catch (Error e) {
                warning("Error extracting metadata: %s", e.message);
                return null;
            }
#else
            warning("GExiv2 not available");
            return null;
#endif
        }

        /**
         * Export metadata to JSON format
         *
         * @param entries List of metadata entries
         * @param image_path Original image path
         * @return JSON string
         */
        public static string export_to_json(List<MetadataEntry> entries, string image_path) {
            var json = new StringBuilder();
            json.append("{\n");
            json.append("  \"file\": \"%s\",\n".printf(escape_json_string(Path.get_basename(image_path))));
            json.append("  \"export_date\": \"%s\",\n".printf(new DateTime.now_local().to_string()));
            json.append("  \"metadata\": {\n");

            // Group by type
            json.append("    \"exif\": {\n");
            bool first_exif = true;
            foreach (var entry in entries) {
                if (entry.metadata_type == "EXIF") {
                    if (!first_exif) json.append(",\n");
                    json.append("      \"%s\": \"%s\"".printf(
                        escape_json_string(entry.tag),
                        escape_json_string(entry.value)
                    ));
                    first_exif = false;
                }
            }
            json.append("\n    },\n");

            json.append("    \"xmp\": {\n");
            bool first_xmp = true;
            foreach (var entry in entries) {
                if (entry.metadata_type == "XMP") {
                    if (!first_xmp) json.append(",\n");
                    json.append("      \"%s\": \"%s\"".printf(
                        escape_json_string(entry.tag),
                        escape_json_string(entry.value)
                    ));
                    first_xmp = false;
                }
            }
            json.append("\n    },\n");

            json.append("    \"iptc\": {\n");
            bool first_iptc = true;
            foreach (var entry in entries) {
                if (entry.metadata_type == "IPTC") {
                    if (!first_iptc) json.append(",\n");
                    json.append("      \"%s\": \"%s\"".printf(
                        escape_json_string(entry.tag),
                        escape_json_string(entry.value)
                    ));
                    first_iptc = false;
                }
            }
            json.append("\n    }\n");

            json.append("  }\n");
            json.append("}\n");

            return json.str;
        }

        /**
         * Export metadata to CSV format
         *
         * @param entries List of metadata entries
         * @param image_path Original image path
         * @return CSV string
         */
        public static string export_to_csv(List<MetadataEntry> entries, string image_path) {
            var csv = new StringBuilder();
            csv.append("File,Type,Tag,Value\n");

            foreach (var entry in entries) {
                csv.append("\"%s\",\"%s\",\"%s\",\"%s\"\n".printf(
                    escape_csv_field(Path.get_basename(image_path)),
                    escape_csv_field(entry.metadata_type),
                    escape_csv_field(entry.tag),
                    escape_csv_field(entry.value)
                ));
            }

            return csv.str;
        }

        /**
         * Export metadata to file
         *
         * @param image_path Path to the image file
         * @param output_path Path to save export file
         * @param format Export format
         * @return true on success
         */
        public static bool export_to_file(string image_path, string output_path, ExportFormat format) {
            try {
                var entries = extract_metadata(image_path);
                if (entries == null) {
                    return false;
                }

                string content = "";
                if (format == ExportFormat.JSON) {
                    content = export_to_json(entries, image_path);
                } else if (format == ExportFormat.CSV) {
                    content = export_to_csv(entries, image_path);
                }

                var file = File.new_for_path(output_path);
                var output_stream = file.replace(null, false, FileCreateFlags.NONE);
                var data_stream = new DataOutputStream(output_stream);
                data_stream.put_string(content);
                data_stream.close();

                return true;
            } catch (Error e) {
                warning("Error exporting metadata: %s", e.message);
                return false;
            }
        }

        /**
         * Escape a string for JSON
         */
        private static string escape_json_string(string str) {
            return str.replace("\\", "\\\\")
                      .replace("\"", "\\\"")
                      .replace("\n", "\\n")
                      .replace("\r", "\\r")
                      .replace("\t", "\\t");
        }

        /**
         * Escape a field for CSV
         */
        private static string escape_csv_field(string str) {
            // If contains comma, quote, or newline, enclose in quotes and escape quotes
            if (str.contains(",") || str.contains("\"") || str.contains("\n")) {
                return str.replace("\"", "\"\"");
            }
            return str;
        }
    }
}

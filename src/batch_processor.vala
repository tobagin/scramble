using Gdk;
using GLib;

namespace Scramble {
    /**
     * Handles batch processing of multiple images
     */
    public class BatchProcessor : Object {

        /**
         * Result of a batch operation on a single file
         */
        public class BatchResult {
            public string input_path { get; set; }
            public string output_path { get; set; }
            public bool success { get; set; }
            public string? error_message { get; set; }

            public BatchResult(string input, string output, bool success, string? error = null) {
                this.input_path = input;
                this.output_path = output;
                this.success = success;
                this.error_message = error;
            }
        }

        /**
         * Progress callback for batch operations
         */
        public delegate void ProgressCallback(int current, int total, string current_file);

        /**
         * Process multiple images in batch
         *
         * @param input_paths List of input image paths
         * @param output_dir Directory to save processed images
         * @param callback Optional progress callback
         * @return List of batch results
         */
        public static List<BatchResult> process_batch(
            List<string> input_paths,
            string output_dir,
            ProgressCallback? callback = null
        ) {
            var results = new List<BatchResult>();
            int current = 0;
            int total = (int)input_paths.length();

            foreach (var input_path in input_paths) {
                current++;

                // Call progress callback
                if (callback != null) {
                    callback(current, total, Path.get_basename(input_path));
                }

                // Generate output path
                var basename = Path.get_basename(input_path);
                var dot = basename.last_index_of(".");
                string name = basename;
                string ext = "";
                if (dot > 0) {
                    name = basename.substring(0, dot);
                    ext = basename.substring(dot);
                }
                var output_path = Path.build_filename(output_dir, "%s_clean%s".printf(name, ext));

                // Process the image
                try {
                    FileValidator.validate_path(input_path);

                    // Check if output directory exists
                    var dir = File.new_for_path(output_dir);
                    if (!dir.query_exists()) {
                        throw new FileError.NOENT(_("Output directory does not exist"));
                    }

                    // Save clean copy
                    if (ImageOperations.save_clean_copy(input_path, output_path)) {
                        results.append(new BatchResult(input_path, output_path, true));
                    } else {
                        results.append(new BatchResult(input_path, output_path, false, _("Save operation failed")));
                    }
                } catch (Error e) {
                    results.append(new BatchResult(input_path, output_path, false, e.message));
                }
            }

            return results;
        }

        /**
         * Get summary statistics from batch results
         *
         * @param results List of batch results
         * @param out success_count Number of successful operations
         * @param out failed_count Number of failed operations
         */
        public static void get_summary(
            List<BatchResult> results,
            out int success_count,
            out int failed_count
        ) {
            success_count = 0;
            failed_count = 0;

            foreach (var result in results) {
                if (result.success) {
                    success_count++;
                } else {
                    failed_count++;
                }
            }
        }

        /**
         * Generate a report from batch results
         *
         * @param results List of batch results
         * @return Human-readable report string
         */
        public static string generate_report(List<BatchResult> results) {
            var report = new StringBuilder();
            int success_count, failed_count;
            get_summary(results, out success_count, out failed_count);

            report.append(_("Batch Processing Report\n"));
            report.append(_("=======================\n\n"));
            report.append(_("Total: %d images\n").printf((int)results.length()));
            report.append(_("Successful: %d\n").printf(success_count));
            report.append(_("Failed: %d\n\n").printf(failed_count));

            if (failed_count > 0) {
                report.append(_("Failed Images:\n"));
                report.append(_("--------------\n"));
                foreach (var result in results) {
                    if (!result.success) {
                        report.append("• %s: %s\n".printf(
                            Path.get_basename(result.input_path),
                            result.error_message ?? _("Unknown error")
                        ));
                    }
                }
            }

            return report.str;
        }
    }
}

using GLib;

namespace Scramble {
    /**
     * File path validation and security checks
     */
    public class FileValidator : Object {

        // Maximum allowed file size: 500 MB
        private const int64 MAX_FILE_SIZE = 500 * 1024 * 1024;

        /**
         * Validate a file path for security and sanity
         *
         * @param path File path to validate
         * @return true if valid, false otherwise
         * @throws FileError on validation failure with descriptive message
         */
        public static void validate_path(string path) throws FileError {
            // Check for null or empty path
            if (path == null || path.strip() == "") {
                throw new FileError.FAILED(_("File path is empty"));
            }

            // Check for path traversal attempts
            if (path.contains("..") || path.contains("//")) {
                throw new FileError.FAILED(_("Invalid file path: contains suspicious patterns"));
            }

            // Check if file exists
            var file = File.new_for_path(path);
            if (!file.query_exists()) {
                throw new FileError.NOENT(_("File does not exist"));
            }

            // Check if it's actually a file (not a directory, symlink, etc.)
            try {
                var info = file.query_info("standard::type,standard::is-symlink,standard::size",
                                          FileQueryInfoFlags.NONE);

                if (info.get_file_type() != FileType.REGULAR) {
                    throw new FileError.FAILED(_("Path is not a regular file"));
                }

                // Check for symlinks (security concern)
                if (info.get_is_symlink()) {
                    warning("Symlink detected: %s", path);
                    // Allow but log - user may have legitimate symlinks
                }

                // Check file size
                var size = info.get_size();
                if (size > MAX_FILE_SIZE) {
                    throw new FileError.FAILED(_("File too large (max 500 MB)"));
                }

                if (size == 0) {
                    throw new FileError.FAILED(_("File is empty"));
                }

            } catch (Error e) {
                throw new FileError.FAILED(_("Cannot access file: %s").printf(e.message));
            }
        }

        /**
         * Validate output path for saving
         *
         * @param path Output file path
         * @throws FileError if path is invalid
         */
        public static void validate_output_path(string path) throws FileError {
            if (path == null || path.strip() == "") {
                throw new FileError.FAILED(_("Output path is empty"));
            }

            // Check for path traversal
            if (path.contains("..") || path.contains("//")) {
                throw new FileError.FAILED(_("Invalid output path"));
            }

            // Check if parent directory exists
            var file = File.new_for_path(path);
            var parent = file.get_parent();
            if (parent == null || !parent.query_exists()) {
                throw new FileError.NOENT(_("Output directory does not exist"));
            }

            // Note: Write permission check would require platform-specific code
            // We'll let the save operation fail naturally if no permission
        }

        /**
         * Sanitize a filename for display (remove sensitive path info)
         *
         * @param path Full file path
         * @return Just the basename
         */
        public static string sanitize_for_display(string path) {
            return Path.get_basename(path);
        }

        /**
         * Get safe error message (no path disclosure)
         *
         * @param error_msg Original error message
         * @return Sanitized error message
         */
        public static string sanitize_error_message(string error_msg) {
            // Remove any absolute paths from error messages
            var sanitized = error_msg;

            // Pattern: /path/to/file or /home/user/...
            try {
                var regex = new Regex("(/[a-zA-Z0-9_/.\\-]+)");
                sanitized = regex.replace(sanitized, -1, 0, "[file]");
            } catch (RegexError e) {
                warning("Regex error in sanitization: %s", e.message);
            }

            return sanitized;
        }
    }
}

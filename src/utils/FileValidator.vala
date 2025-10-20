using GLib;

namespace Scramble {
    /**
     * File path validation and security checks
     */
    public class FileValidator : Object {

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

                // Check for symlinks (security concern - SEC-001)
                if (info.get_is_symlink()) {
                    #if DEVELOPMENT
                        // In development, check if symlinks are allowed via settings
                        var settings = new GLib.Settings(Config.APP_ID);
                        if (settings.get_boolean("allow-symlinks-dev")) {
                            warning("Symlink detected in development mode (allowed): %s", sanitize_for_display(path));
                            // Resolve symlink and validate target
                            var real_path = FileUtils.read_link(path);
                            // If relative path, resolve against parent directory
                            if (!Path.is_absolute(real_path)) {
                                var parent = Path.get_dirname(path);
                                real_path = Path.build_filename(parent, real_path);
                            }
                            // Recursively validate the target
                            validate_path(real_path);
                            return;
                        }
                    #endif
                    // Production mode or dev mode with setting disabled: reject symlinks
                    warning("Symlink detected and rejected for security: %s", sanitize_for_display(path));
                    throw new FileError.FAILED(_("Symbolic links are not supported for security reasons"));
                }

                // Check file size
                var size = info.get_size();
                if (size > Constants.MAX_FILE_SIZE) {
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

            // Note: Don't validate file size for output - Gtk.FileDialog may pre-create empty files
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
         * Uses safe string operations instead of regex to prevent
         * ReDoS attacks (SEC-002)
         *
         * @param error_msg Original error message
         * @return Sanitized error message
         */
        public static string sanitize_error_message(string error_msg) {
            var sanitized = error_msg;

            // Split by forward slash to detect paths
            var parts = sanitized.split("/");

            // If we have an absolute path (starts with /)
            if (parts.length > 1 && sanitized.has_prefix("/")) {
                // Keep only the descriptive part, replace path with generic placeholder
                var last_part = parts[parts.length - 1];

                // If the last part looks like a filename, keep context but hide path
                if (last_part.length > 0 && last_part.contains(".")) {
                    return _("File error: %s").printf(last_part);
                } else {
                    return _("File error: [path hidden]");
                }
            }

            // Also check for Windows-style paths (C:\...)
            if (sanitized.contains(":\\")) {
                var win_parts = sanitized.split("\\");
                if (win_parts.length > 0) {
                    var last = win_parts[win_parts.length - 1];
                    if (last.length > 0) {
                        return _("File error: %s").printf(last);
                    }
                }
            }

            return sanitized;
        }
    }
}

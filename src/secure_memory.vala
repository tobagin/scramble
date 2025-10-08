using Gdk;

namespace Scramble {
    /**
     * Secure memory handling to prevent data leaks
     */
    public class SecureMemory : Object {

        /**
         * Securely clear a pixbuf from memory
         *
         * @param pixbuf The pixbuf to clear
         */
        public static void clear_pixbuf(Gdk.Pixbuf? pixbuf) {
            if (pixbuf == null) {
                return;
            }

            // Get pixel data
            unowned uint8[] pixels = pixbuf.get_pixels_with_length();

            // Overwrite with zeros (multiple passes for security)
            for (int pass = 0; pass < 3; pass++) {
                for (int i = 0; i < pixels.length; i++) {
                    pixels[i] = (uint8)(pass == 0 ? 0 : (pass == 1 ? 0xFF : 0));
                }
            }
        }

        /**
         * Clear sensitive string data from memory
         *
         * @param data String to clear
         */
        public static void clear_string(ref string? data) {
            if (data == null) {
                return;
            }

            // Overwrite string memory (multiple passes)
            for (int pass = 0; pass < 3; pass++) {
                for (int i = 0; i < data.length; i++) {
                    data.data[i] = (char)(pass == 0 ? 0 : (pass == 1 ? 0xFF : 0));
                }
            }

            data = null;
        }

        /**
         * Check if secure memory clearing is enabled in settings
         *
         * @param settings Application settings
         * @return true if enabled
         */
        public static bool is_enabled(GLib.Settings settings) {
            return settings.get_boolean("secure-memory");
        }
    }
}

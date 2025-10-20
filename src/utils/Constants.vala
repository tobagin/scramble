namespace Scramble {
    /**
     * Application-wide constants for validation, quality settings, and file format signatures
     */
    public class Constants : Object {

        // ===== File Format Magic Numbers (Signatures) =====

        /**
         * JPEG magic number signature (first 3 bytes)
         * Format: 0xFF 0xD8 0xFF (Start of Image marker + App segment)
         */
        public const uint8[] JPEG_MAGIC = {0xFF, 0xD8, 0xFF};

        /**
         * PNG magic number signature (8 bytes)
         * Format: 0x89 'P' 'N' 'G' '\r' '\n' 0x1A '\n'
         */
        public const uint8[] PNG_MAGIC = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

        /**
         * WebP RIFF container signature (first 4 bytes)
         * Format: 'R' 'I' 'F' 'F'
         */
        public const uint8[] WEBP_RIFF = {0x52, 0x49, 0x46, 0x46};

        /**
         * WebP format signature (bytes 8-11, after RIFF header + size)
         * Format: 'W' 'E' 'B' 'P'
         */
        public const uint8[] WEBP_WEBP = {0x57, 0x45, 0x42, 0x50};

        /**
         * TIFF Little-Endian magic number (4 bytes)
         * Format: 'I' 'I' 0x2A 0x00 (Intel byte order)
         */
        public const uint8[] TIFF_LE = {0x49, 0x49, 0x2A, 0x00};

        /**
         * TIFF Big-Endian magic number (4 bytes)
         * Format: 'M' 'M' 0x00 0x2A (Motorola byte order)
         */
        public const uint8[] TIFF_BE = {0x4D, 0x4D, 0x00, 0x2A};

        /**
         * HEIF/HEIC ftyp box signature (bytes 4-7)
         * Format: 'f' 't' 'y' 'p'
         * Note: Bytes 0-3 contain box size, bytes 4-7 contain "ftyp"
         */
        public const uint8[] HEIF_FTYP = {0x66, 0x74, 0x79, 0x70};

        /**
         * HEIF brand signatures (bytes 8-11, following ftyp)
         * Common brands: "heic", "heix", "hevc", "hevx", "mif1", "msf1"
         */
        public const string[] HEIF_BRANDS = {"heic", "heix", "hevc", "hevx", "mif1", "msf1"};

        // ===== File Size and Processing Limits =====

        /**
         * Maximum allowed file size for processing: 500 MB
         * Prevents resource exhaustion from extremely large files
         */
        public const int64 MAX_FILE_SIZE = 500 * 1024 * 1024;

        /**
         * Maximum number of files in batch processing
         * Prevents UI freezing and excessive memory usage
         */
        public const int BATCH_SIZE_LIMIT = 1000;

        // ===== Image Quality Settings =====

        /**
         * JPEG compression quality (1-100)
         * 95 provides high quality with reasonable file size
         */
        public const int JPEG_QUALITY = 95;

        /**
         * WebP compression quality (1-100)
         * 95 provides high quality with reasonable file size
         */
        public const int WEBP_QUALITY = 95;

        // ===== Security Settings =====

        /**
         * Number of passes for secure memory clearing
         * 3 passes balances security and performance
         */
        public const int SECURE_MEMORY_PASSES = 3;

        /**
         * Magic number buffer size (maximum bytes needed to validate any format)
         * WebP requires 12 bytes (RIFF header + WEBP signature)
         */
        public const int MAGIC_BUFFER_SIZE = 12;

        // ===== Performance Targets =====

        /**
         * Target maximum time for file validation (milliseconds)
         * Format validation should complete quickly to maintain responsiveness
         */
        public const int VALIDATION_TIMEOUT_MS = 50;

        /**
         * Target maximum time for magic number validation (milliseconds)
         * Magic number check should be very fast as it only reads file header
         */
        public const int MAGIC_VALIDATION_TIMEOUT_MS = 10;
    }
}

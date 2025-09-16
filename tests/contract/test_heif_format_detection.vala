/**
 * Contract Tests for HeifFormatDetector Interface
 *
 * These tests validate the contract defined in heif-format-detection.vala
 * Tests MUST fail initially until the interface is implemented.
 */

using Scramble.Contracts;

namespace Scramble.Tests.Contract {

    public class TestHeifFormatDetection : Object {

        private HeifFormatDetector? detector;

        public void setup() {
            // This will fail initially - no implementation yet
            detector = new HeifFormatDetectorImpl();
        }

        public void test_is_heif_format_with_valid_heif_file() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                bool result = detector.is_heif_format(test_file);
                assert(result == true);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_is_heif_format_with_valid_heic_file() {
            // Arrange
            string test_file = "tests/fixtures/sample.heic";

            // Act & Assert
            try {
                bool result = detector.is_heif_format(test_file);
                assert(result == true);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_is_heif_format_with_invalid_file() {
            // Arrange
            string test_file = "tests/fixtures/sample.jpg";

            // Act & Assert
            try {
                bool result = detector.is_heif_format(test_file);
                assert(result == false);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_is_heif_format_with_nonexistent_file() {
            // Arrange
            string test_file = "tests/fixtures/nonexistent.heif";

            // Act & Assert
            try {
                detector.is_heif_format(test_file);
                assert_not_reached(); // Should throw IOError
            } catch (IOError e) {
                // Expected behavior
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_heif_variant_with_heif_file() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                HeifVariant variant = detector.get_heif_variant(test_file);
                assert(variant == HeifVariant.HEIF);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_heif_variant_with_heic_file() {
            // Arrange
            string test_file = "tests/fixtures/sample.heic";

            // Act & Assert
            try {
                HeifVariant variant = detector.get_heif_variant(test_file);
                assert(variant == HeifVariant.HEIC);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_has_gdkpixbuf_heif_support() {
            // Act
            bool has_support = detector.has_gdkpixbuf_heif_support();

            // Assert - should be true after libheif installation
            assert(has_support == true);
        }

        public void test_get_image_count_single_image() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                int count = detector.get_image_count(test_file);
                assert(count == 1);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_image_count_sequence() {
            // Arrange
            string test_file = "tests/fixtures/sequence.heif";

            // Act & Assert
            try {
                int count = detector.get_image_count(test_file);
                assert(count > 1);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_primary_image_index() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                int index = detector.get_primary_image_index(test_file);
                assert(index >= 0);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_primary_image_index_sequence() {
            // Arrange
            string test_file = "tests/fixtures/sequence.heif";

            // Act & Assert
            try {
                int index = detector.get_primary_image_index(test_file);
                assert(index >= 0);

                // Primary index should be within image count
                int count = detector.get_image_count(test_file);
                assert(index < count);
            } catch (Error e) {
                assert_not_reached();
            }
        }
    }
}

// Test runner for contract tests
public static int main(string[] args) {
    Test.init(ref args);

    var test = new Scramble.Tests.Contract.TestHeifFormatDetection();

    Test.add_func("/contract/heif_format_detection/setup", test.setup);
    Test.add_func("/contract/heif_format_detection/is_heif_format_valid_heif", test.test_is_heif_format_with_valid_heif_file);
    Test.add_func("/contract/heif_format_detection/is_heif_format_valid_heic", test.test_is_heif_format_with_valid_heic_file);
    Test.add_func("/contract/heif_format_detection/is_heif_format_invalid", test.test_is_heif_format_with_invalid_file);
    Test.add_func("/contract/heif_format_detection/is_heif_format_nonexistent", test.test_is_heif_format_with_nonexistent_file);
    Test.add_func("/contract/heif_format_detection/get_variant_heif", test.test_get_heif_variant_with_heif_file);
    Test.add_func("/contract/heif_format_detection/get_variant_heic", test.test_get_heif_variant_with_heic_file);
    Test.add_func("/contract/heif_format_detection/has_gdkpixbuf_support", test.test_has_gdkpixbuf_heif_support);
    Test.add_func("/contract/heif_format_detection/image_count_single", test.test_get_image_count_single_image);
    Test.add_func("/contract/heif_format_detection/image_count_sequence", test.test_get_image_count_sequence);
    Test.add_func("/contract/heif_format_detection/primary_index", test.test_get_primary_image_index);
    Test.add_func("/contract/heif_format_detection/primary_index_sequence", test.test_get_primary_image_index_sequence);

    return Test.run();
}
/**
 * Contract Tests for HeifImageProcessor Interface
 *
 * These tests validate the contract defined in heif-image-processing.vala
 * Tests MUST fail initially until the interface is implemented.
 */

using Scramble.Contracts;

namespace Scramble.Tests.Contract {

    public class TestHeifImageProcessing : Object {

        private HeifImageProcessor? processor;

        public void setup() {
            // This will fail initially - no implementation yet
            processor = new HeifImageProcessorImpl();
        }

        public void test_load_image_heif() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                Gdk.Pixbuf pixbuf = processor.load_image(test_file);

                // Should have valid pixbuf
                assert(pixbuf != null);
                assert(pixbuf.get_width() > 0);
                assert(pixbuf.get_height() > 0);
                assert(pixbuf.get_n_channels() >= 3); // RGB or RGBA
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_load_image_heic() {
            // Arrange
            string test_file = "tests/fixtures/sample.heic";

            // Act & Assert
            try {
                Gdk.Pixbuf pixbuf = processor.load_image(test_file);

                // Should have valid pixbuf
                assert(pixbuf != null);
                assert(pixbuf.get_width() > 0);
                assert(pixbuf.get_height() > 0);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_load_image_by_index() {
            // Arrange
            string test_file = "tests/fixtures/sequence.heif";
            int image_index = 1;

            // Act & Assert
            try {
                Gdk.Pixbuf pixbuf = processor.load_image_by_index(test_file, image_index);

                // Should have valid pixbuf for specific index
                assert(pixbuf != null);
                assert(pixbuf.get_width() > 0);
                assert(pixbuf.get_height() > 0);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_load_image_by_index_out_of_range() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";
            int invalid_index = 999;

            // Act & Assert
            try {
                processor.load_image_by_index(test_file, invalid_index);
                assert_not_reached(); // Should throw IndexError
            } catch (IndexError e) {
                // Expected behavior
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_save_clean_copy_jpeg() {
            // Arrange
            string source_file = "tests/fixtures/sample_with_metadata.heif";
            string output_file = "tests/fixtures/output_clean.jpg";
            ImageFormat format = ImageFormat.JPEG;
            int quality = 90;

            // Act & Assert
            try {
                processor.save_clean_copy(source_file, output_file, format, quality);

                // Output file should exist
                File output = File.new_for_path(output_file);
                assert(output.query_exists());

                // Clean up
                output.delete();
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_save_clean_copy_png() {
            // Arrange
            string source_file = "tests/fixtures/sample_with_metadata.heif";
            string output_file = "tests/fixtures/output_clean.png";
            ImageFormat format = ImageFormat.PNG;

            // Act & Assert
            try {
                processor.save_clean_copy(source_file, output_file, format);

                // Output file should exist
                File output = File.new_for_path(output_file);
                assert(output.query_exists());

                // Clean up
                output.delete();
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_save_clean_copy_by_index() {
            // Arrange
            string source_file = "tests/fixtures/sequence.heif";
            int image_index = 1;
            string output_file = "tests/fixtures/output_sequence_clean.jpg";
            ImageFormat format = ImageFormat.JPEG;

            // Act & Assert
            try {
                processor.save_clean_copy_by_index(source_file, image_index, output_file, format);

                // Output file should exist
                File output = File.new_for_path(output_file);
                assert(output.query_exists());

                // Clean up
                output.delete();
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_image_dimensions() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                ImageDimensions dimensions = processor.get_image_dimensions(test_file);

                // Should have valid dimensions
                assert(dimensions.width > 0);
                assert(dimensions.height > 0);

                // Should have readable string representation
                string dim_string = dimensions.to_string();
                assert(dim_string.contains("×"));
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_check_processing_capability() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                ProcessingCapability capability = processor.check_processing_capability(test_file);

                // Should have at least read support
                assert(capability != ProcessingCapability.NO_SUPPORT);
                assert(capability == ProcessingCapability.FULL_SUPPORT ||
                       capability == ProcessingCapability.READ_ONLY ||
                       capability == ProcessingCapability.METADATA_ONLY);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_validate_file_integrity_valid() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act & Assert
            try {
                bool is_valid = processor.validate_file_integrity(test_file);
                assert(is_valid == true);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_validate_file_integrity_corrupted() {
            // Arrange
            string test_file = "tests/fixtures/corrupted.heif";

            // Act & Assert
            try {
                bool is_valid = processor.validate_file_integrity(test_file);
                assert(is_valid == false);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_load_image_nonexistent_file() {
            // Arrange
            string test_file = "tests/fixtures/nonexistent.heif";

            // Act & Assert
            try {
                processor.load_image(test_file);
                assert_not_reached(); // Should throw IOError
            } catch (IOError e) {
                // Expected behavior
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_quality_settings() {
            // Test QualitySettings utility class

            // Test default quality values
            assert(QualitySettings.get_default_quality(ImageFormat.JPEG) == 90);
            assert(QualitySettings.get_default_quality(ImageFormat.PNG) == 100);
            assert(QualitySettings.get_default_quality(ImageFormat.WEBP) == 85);

            // Test lossy format detection
            assert(QualitySettings.is_lossy_format(ImageFormat.JPEG) == true);
            assert(QualitySettings.is_lossy_format(ImageFormat.PNG) == false);
            assert(QualitySettings.is_lossy_format(ImageFormat.WEBP) == true);

            // Test file extensions
            assert(QualitySettings.get_file_extension(ImageFormat.JPEG) == ".jpg");
            assert(QualitySettings.get_file_extension(ImageFormat.PNG) == ".png");
            assert(QualitySettings.get_file_extension(ImageFormat.HEIF) == ".heif");
        }
    }
}

// Test runner for contract tests
public static int main(string[] args) {
    Test.init(ref args);

    var test = new Scramble.Tests.Contract.TestHeifImageProcessing();

    Test.add_func("/contract/heif_image_processing/setup", test.setup);
    Test.add_func("/contract/heif_image_processing/load_image_heif", test.test_load_image_heif);
    Test.add_func("/contract/heif_image_processing/load_image_heic", test.test_load_image_heic);
    Test.add_func("/contract/heif_image_processing/load_image_by_index", test.test_load_image_by_index);
    Test.add_func("/contract/heif_image_processing/load_image_by_index_invalid", test.test_load_image_by_index_out_of_range);
    Test.add_func("/contract/heif_image_processing/save_clean_copy_jpeg", test.test_save_clean_copy_jpeg);
    Test.add_func("/contract/heif_image_processing/save_clean_copy_png", test.test_save_clean_copy_png);
    Test.add_func("/contract/heif_image_processing/save_clean_copy_by_index", test.test_save_clean_copy_by_index);
    Test.add_func("/contract/heif_image_processing/get_image_dimensions", test.test_get_image_dimensions);
    Test.add_func("/contract/heif_image_processing/check_processing_capability", test.test_check_processing_capability);
    Test.add_func("/contract/heif_image_processing/validate_file_integrity_valid", test.test_validate_file_integrity_valid);
    Test.add_func("/contract/heif_image_processing/validate_file_integrity_corrupted", test.test_validate_file_integrity_corrupted);
    Test.add_func("/contract/heif_image_processing/load_image_nonexistent", test.test_load_image_nonexistent_file);
    Test.add_func("/contract/heif_image_processing/quality_settings", test.test_quality_settings);

    return Test.run();
}
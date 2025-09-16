/**
 * Contract Tests for HeifMetadataExtractor Interface
 *
 * These tests validate the contract defined in heif-metadata-extraction.vala
 * Tests MUST fail initially until the interface is implemented.
 */

using Scramble.Contracts;

namespace Scramble.Tests.Contract {

    public class TestHeifMetadataExtraction : Object {

        private HeifMetadataExtractor? extractor;

        public void setup() {
            // This will fail initially - no implementation yet
            extractor = new HeifMetadataExtractorImpl();
        }

        public void test_extract_metadata_from_heif_with_metadata() {
            // Arrange
            string test_file = "tests/fixtures/sample_with_metadata.heif";

            // Act & Assert
            try {
                HeifMetadataInfo metadata = extractor.extract_metadata(test_file);

                // Should have basic file information
                assert(metadata.file_path == test_file);
                assert(metadata.file_name != null);
                assert(metadata.file_size > 0);

                // Should have image dimensions
                assert(metadata.image_width > 0);
                assert(metadata.image_height > 0);

                // Should indicate it's not a sequence (single image)
                assert(metadata.is_sequence == false);
                assert(metadata.image_count == 1);
                assert(metadata.current_image_index == 0);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_extract_metadata_from_heic_with_camera_data() {
            // Arrange
            string test_file = "tests/fixtures/iphone_photo.heic";

            // Act & Assert
            try {
                HeifMetadataInfo metadata = extractor.extract_metadata(test_file);

                // Should have camera information for iPhone photo
                assert(metadata.camera_make != null);
                assert(metadata.camera_model != null);
                assert(metadata.date_taken != null);

                // Should have formatted camera string
                string? camera_info = metadata.get_formatted_camera();
                assert(camera_info != null);

                // Should have any metadata
                assert(metadata.has_any_metadata() == true);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_extract_metadata_from_heif_with_gps() {
            // Arrange
            string test_file = "tests/fixtures/gps_photo.heif";

            // Act & Assert
            try {
                HeifMetadataInfo metadata = extractor.extract_metadata(test_file);

                // Should have GPS coordinates
                assert(metadata.gps_latitude != null);
                assert(metadata.gps_longitude != null);

                // Should have formatted location
                string? location = metadata.get_formatted_location();
                assert(location != null);
                assert(location.contains(","));
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_extract_metadata_by_index() {
            // Arrange
            string test_file = "tests/fixtures/sequence.heif";
            int image_index = 1;

            // Act & Assert
            try {
                HeifMetadataInfo metadata = extractor.extract_metadata_by_index(test_file, image_index);

                // Should indicate sequence information
                assert(metadata.is_sequence == true);
                assert(metadata.image_count > 1);
                assert(metadata.current_image_index == image_index);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_extract_metadata_by_index_out_of_range() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";
            int invalid_index = 999;

            // Act & Assert
            try {
                extractor.extract_metadata_by_index(test_file, invalid_index);
                assert_not_reached(); // Should throw IndexError
            } catch (IndexError e) {
                // Expected behavior
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_has_metadata_with_metadata() {
            // Arrange
            string test_file = "tests/fixtures/sample_with_metadata.heif";

            // Act & Assert
            try {
                bool has_metadata = extractor.has_metadata(test_file);
                assert(has_metadata == true);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_has_metadata_without_metadata() {
            // Arrange
            string test_file = "tests/fixtures/no_metadata.heic";

            // Act & Assert
            try {
                bool has_metadata = extractor.has_metadata(test_file);
                assert(has_metadata == false);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_available_tags() {
            // Arrange
            string test_file = "tests/fixtures/sample_with_metadata.heif";

            // Act & Assert
            try {
                string[] tags = extractor.get_available_tags(test_file);

                // Should have some tags
                assert(tags.length > 0);

                // Common EXIF tags should be present
                bool has_exif_tags = false;
                foreach (string tag in tags) {
                    if (tag.has_prefix("Exif.")) {
                        has_exif_tags = true;
                        break;
                    }
                }
                assert(has_exif_tags == true);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_tag_value_existing_tag() {
            // Arrange
            string test_file = "tests/fixtures/sample_with_metadata.heif";
            string tag_name = "Exif.Image.Make";

            // Act & Assert
            try {
                string? value = extractor.get_tag_value(test_file, tag_name);
                assert(value != null);
                assert(value.length > 0);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_get_tag_value_nonexistent_tag() {
            // Arrange
            string test_file = "tests/fixtures/sample_with_metadata.heif";
            string tag_name = "Exif.NonExistent.Tag";

            // Act & Assert
            try {
                string? value = extractor.get_tag_value(test_file, tag_name);
                assert(value == null);
            } catch (Error e) {
                assert_not_reached();
            }
        }

        public void test_extract_metadata_nonexistent_file() {
            // Arrange
            string test_file = "tests/fixtures/nonexistent.heif";

            // Act & Assert
            try {
                extractor.extract_metadata(test_file);
                assert_not_reached(); // Should throw IOError
            } catch (IOError e) {
                // Expected behavior
            } catch (Error e) {
                assert_not_reached();
            }
        }
    }
}

// Test runner for contract tests
public static int main(string[] args) {
    Test.init(ref args);

    var test = new Scramble.Tests.Contract.TestHeifMetadataExtraction();

    Test.add_func("/contract/heif_metadata_extraction/setup", test.setup);
    Test.add_func("/contract/heif_metadata_extraction/extract_metadata_heif", test.test_extract_metadata_from_heif_with_metadata);
    Test.add_func("/contract/heif_metadata_extraction/extract_metadata_heic_camera", test.test_extract_metadata_from_heic_with_camera_data);
    Test.add_func("/contract/heif_metadata_extraction/extract_metadata_gps", test.test_extract_metadata_from_heif_with_gps);
    Test.add_func("/contract/heif_metadata_extraction/extract_by_index", test.test_extract_metadata_by_index);
    Test.add_func("/contract/heif_metadata_extraction/extract_by_index_invalid", test.test_extract_metadata_by_index_out_of_range);
    Test.add_func("/contract/heif_metadata_extraction/has_metadata_true", test.test_has_metadata_with_metadata);
    Test.add_func("/contract/heif_metadata_extraction/has_metadata_false", test.test_has_metadata_without_metadata);
    Test.add_func("/contract/heif_metadata_extraction/get_available_tags", test.test_get_available_tags);
    Test.add_func("/contract/heif_metadata_extraction/get_tag_value_existing", test.test_get_tag_value_existing_tag);
    Test.add_func("/contract/heif_metadata_extraction/get_tag_value_nonexistent", test.test_get_tag_value_nonexistent_tag);
    Test.add_func("/contract/heif_metadata_extraction/extract_metadata_nonexistent", test.test_extract_metadata_nonexistent_file);

    return Test.run();
}
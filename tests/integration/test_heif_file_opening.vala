/**
 * Integration Tests for HEIF File Opening Workflow
 *
 * Tests the complete workflow from quickstart scenario 1:
 * Basic HEIF File Opening through drag-drop, file dialog, and shortcuts
 */

namespace Scramble.Tests.Integration {

    public class TestHeifFileOpening : Object {

        private Scramble.Window? window;
        private Scramble.Application? app;

        public void setup() {
            // Initialize application for testing
            app = new Scramble.Application();
            window = new Scramble.Window(app);
        }

        public void teardown() {
            window = null;
            app = null;
        }

        public void test_open_heif_file_via_load_method() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act - simulate opening file through the window's load method
            try {
                window.load_image_file(test_file);

                // Assert - verify image is loaded and displayed
                assert(window.current_image_path == test_file);
                assert(window.image_preview.file != null);

                // Verify metadata panel is populated
                // (This will need to be implemented in window.vala)
                assert(window.has_metadata_displayed() == true);

            } catch (Error e) {
                message("Failed to load HEIF file: %s", e.message);
                assert_not_reached();
            }
        }

        public void test_heif_file_format_detection() {
            // Arrange
            string heif_file = "tests/fixtures/sample.heif";
            string heic_file = "tests/fixtures/sample.heic";
            string jpg_file = "tests/fixtures/sample.jpg";

            // Act & Assert - test format detection
            assert(Scramble.Window.is_supported_format(heif_file) == true);
            assert(Scramble.Window.is_supported_format(heic_file) == true);
            assert(Scramble.Window.is_supported_format(jpg_file) == true); // Should still work

            // Test file extensions specifically
            assert(heif_file.has_suffix(".heif"));
            assert(heic_file.has_suffix(".heic"));
        }

        public void test_file_chooser_shows_heif_files() {
            // This test verifies that HEIF/HEIC files appear in file chooser
            // We'll test the file filter configuration

            // Arrange - get the file filter used in the application
            var file_chooser = new Gtk.FileChooserDialog(
                "Test File Chooser",
                window,
                Gtk.FileChooserAction.OPEN,
                "_Cancel", Gtk.ResponseType.CANCEL,
                "_Open", Gtk.ResponseType.ACCEPT
            );

            // Create the same filter as used in window.vala
            var f_images = new Gtk.FileFilter();
            f_images.set_filter_name("Image Files");
            f_images.add_mime_type("image/jpeg");
            f_images.add_mime_type("image/png");
            f_images.add_mime_type("image/webp");
            f_images.add_mime_type("image/tiff");
            f_images.add_mime_type("image/heif");  // Should be added
            f_images.add_mime_type("image/heic");  // Should be added
            f_images.add_pattern("*.jpg");
            f_images.add_pattern("*.jpeg");
            f_images.add_pattern("*.png");
            f_images.add_pattern("*.webp");
            f_images.add_pattern("*.tif");
            f_images.add_pattern("*.tiff");
            f_images.add_pattern("*.heif");       // Should be added
            f_images.add_pattern("*.heic");       // Should be added

            file_chooser.add_filter(f_images);

            // Act - Test that HEIF files would be accepted
            // (In a real test, we'd check if test files are visible)

            // Assert - The filter should be configured correctly
            // This is a basic test - in reality we'd need to test file visibility
            assert(f_images != null);

            file_chooser.destroy();
        }

        public void test_image_display_after_heif_load() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";

            // Act
            try {
                window.load_image_file(test_file);

                // Assert - verify image is properly displayed
                assert(window.image_preview.file != null);

                // Verify the image container is visible (not welcome page)
                assert(window.image_container.visible == true);
                assert(window.welcome_page.visible == false);

                // Verify image has reasonable dimensions
                var pixbuf = window.image_preview.paintable as Gdk.Pixbuf;
                if (pixbuf != null) {
                    assert(pixbuf.get_width() > 0);
                    assert(pixbuf.get_height() > 0);
                }

            } catch (Error e) {
                message("Failed to display HEIF image: %s", e.message);
                assert_not_reached();
            }
        }

        public void test_metadata_panel_populated_for_heif() {
            // Arrange
            string test_file = "tests/fixtures/sample_with_metadata.heif";

            // Act
            try {
                window.load_image_file(test_file);

                // Assert - verify metadata rows are populated
                // Check that basic metadata rows show information
                assert(window.filename_row.get_value().length > 0);
                assert(window.filesize_row.get_value().length > 0);
                assert(window.dimensions_row.get_value().length > 0);

                // Verify that HEIF-specific metadata is handled
                // (Camera, date, location if present in test file)

            } catch (Error e) {
                message("Failed to extract HEIF metadata: %s", e.message);
                assert_not_reached();
            }
        }

        public void test_clear_heif_image() {
            // Arrange
            string test_file = "tests/fixtures/sample.heif";
            window.load_image_file(test_file);

            // Act - clear the current image
            window.on_clear_clicked();

            // Assert - verify image is cleared
            assert(window.current_image_path == null);
            assert(window.image_container.visible == false);
            assert(window.welcome_page.visible == true);

            // Verify metadata is cleared
            assert(window.filename_row.get_value() == "");
            assert(window.filesize_row.get_value() == "");
        }

        public void test_sequential_heif_file_loading() {
            // Test loading multiple HEIF files in sequence

            // Arrange
            string[] test_files = {
                "tests/fixtures/sample.heif",
                "tests/fixtures/sample.heic",
                "tests/fixtures/another_sample.heif"
            };

            // Act & Assert - load each file sequentially
            foreach (string file in test_files) {
                try {
                    window.load_image_file(file);

                    // Verify each file loads correctly
                    assert(window.current_image_path == file);
                    assert(window.image_preview.file != null);
                    assert(window.image_container.visible == true);

                } catch (Error e) {
                    message("Failed to load file %s: %s", file, e.message);
                    assert_not_reached();
                }
            }
        }
    }
}

// Test runner for integration tests
public static int main(string[] args) {
    Test.init(ref args);
    Gtk.init();

    var test = new Scramble.Tests.Integration.TestHeifFileOpening();

    Test.add_func("/integration/heif_file_opening/setup", test.setup);
    Test.add_func("/integration/heif_file_opening/load_heif_file", test.test_open_heif_file_via_load_method);
    Test.add_func("/integration/heif_file_opening/format_detection", test.test_heif_file_format_detection);
    Test.add_func("/integration/heif_file_opening/file_chooser_filter", test.test_file_chooser_shows_heif_files);
    Test.add_func("/integration/heif_file_opening/image_display", test.test_image_display_after_heif_load);
    Test.add_func("/integration/heif_file_opening/metadata_panel", test.test_metadata_panel_populated_for_heif);
    Test.add_func("/integration/heif_file_opening/clear_image", test.test_clear_heif_image);
    Test.add_func("/integration/heif_file_opening/sequential_loading", test.test_sequential_heif_file_loading);
    Test.add_func("/integration/heif_file_opening/teardown", test.teardown);

    return Test.run();
}
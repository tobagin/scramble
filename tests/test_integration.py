"""
Integration tests for the complete Scramble application workflow.
"""
import os
import tempfile
import unittest
import sys
from pathlib import Path

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from metadata import MetadataHandler


class TestMetadataRemovalVerification(unittest.TestCase):
    """Test that metadata is actually removed from images."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.handler = MetadataHandler()
        self.temp_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        """Clean up test fixtures."""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def create_image_with_metadata(self, filename):
        """Create a test image with known metadata."""
        try:
            from PIL import Image
            import piexif
            
            # Create test image
            img = Image.new('RGB', (200, 200), color='blue')
            
            # Create comprehensive EXIF data
            exif_dict = {
                '0th': {
                    piexif.ImageIFD.Make: "Test Camera Manufacturer",
                    piexif.ImageIFD.Model: "Test Camera Model XYZ",
                    piexif.ImageIFD.Software: "Scramble Test Suite v1.0",
                    piexif.ImageIFD.DateTime: "2025:07:15 23:00:00",
                    piexif.ImageIFD.ImageWidth: 200,
                    piexif.ImageIFD.ImageLength: 200,
                    piexif.ImageIFD.Orientation: 1,
                    piexif.ImageIFD.XResolution: (72, 1),
                    piexif.ImageIFD.YResolution: (72, 1),
                    piexif.ImageIFD.ResolutionUnit: 2,
                },
                'Exif': {
                    piexif.ExifIFD.DateTimeOriginal: "2025:07:15 22:30:00",
                    piexif.ExifIFD.DateTimeDigitized: "2025:07:15 22:30:00",
                    piexif.ExifIFD.ExifVersion: b"0232",
                    piexif.ExifIFD.ComponentsConfiguration: b"\x01\x02\x03\x00",
                    piexif.ExifIFD.FlashpixVersion: b"0100",
                    piexif.ExifIFD.ColorSpace: 1,
                    piexif.ExifIFD.PixelXDimension: 200,
                    piexif.ExifIFD.PixelYDimension: 200,
                    piexif.ExifIFD.ExposureTime: (1, 60),
                    piexif.ExifIFD.FNumber: (28, 10),
                    piexif.ExifIFD.ISO: 100,
                    piexif.ExifIFD.FocalLength: (50, 1),
                },
                'GPS': {
                    piexif.GPSIFD.GPSVersionID: (2, 0, 0, 0),
                    piexif.GPSIFD.GPSLatitudeRef: 'N',
                    piexif.GPSIFD.GPSLatitude: ((40, 1), (42, 1), (4620, 100)),
                    piexif.GPSIFD.GPSLongitudeRef: 'W',
                    piexif.GPSIFD.GPSLongitude: ((74, 1), (0, 1), (2160, 100)),
                    piexif.GPSIFD.GPSTimeStamp: ((22, 1), (30, 1), (0, 1)),
                    piexif.GPSIFD.GPSDateStamp: "2025:07:15",
                },
                '1st': {
                    piexif.ImageIFD.Make: "Test Camera Manufacturer",
                    piexif.ImageIFD.Model: "Test Camera Model XYZ",
                    piexif.ImageIFD.Orientation: 1,
                    piexif.ImageIFD.XResolution: (72, 1),
                    piexif.ImageIFD.YResolution: (72, 1),
                    piexif.ImageIFD.ResolutionUnit: 2,
                }
            }
            
            # Convert to bytes
            exif_bytes = piexif.dump(exif_dict)
            
            # Save with EXIF data
            filepath = os.path.join(self.temp_dir, filename)
            img.save(filepath, 'JPEG', exif=exif_bytes, quality=95)
            
            return filepath
            
        except ImportError:
            self.skipTest("piexif not available for creating test images")
    
    def count_metadata_entries(self, image_path):
        """Count the number of metadata entries in an image."""
        try:
            import piexif
            exif_dict = piexif.load(image_path)
            
            total_entries = 0
            for ifd in ('0th', 'Exif', 'GPS', '1st'):
                if ifd in exif_dict and exif_dict[ifd]:
                    total_entries += len(exif_dict[ifd])
            
            return total_entries
        except Exception:
            return 0
    
    def test_metadata_removal_verification(self):
        """Test that metadata is actually removed from images."""
        # Create image with metadata
        original_path = self.create_image_with_metadata('original_with_metadata.jpg')
        cleaned_path = os.path.join(self.temp_dir, 'cleaned_no_metadata.jpg')
        
        # Verify original has metadata
        original_metadata = self.handler.extract_metadata(original_path)
        self.assertNotIn('error', original_metadata, "Original image should have readable metadata")
        
        original_count = self.count_metadata_entries(original_path)
        self.assertGreater(original_count, 0, "Original image should have metadata entries")
        
        # Remove metadata
        removal_success = self.handler.remove_metadata(original_path, cleaned_path)
        self.assertTrue(removal_success, "Metadata removal should succeed")
        
        # Verify cleaned image exists
        self.assertTrue(os.path.exists(cleaned_path), "Cleaned image should exist")
        
        # Verify cleaned image has no or minimal metadata
        cleaned_count = self.count_metadata_entries(cleaned_path)
        self.assertLessEqual(cleaned_count, 2, "Cleaned image should have minimal metadata")
        
        # Verify significant reduction in metadata
        metadata_reduction = original_count - cleaned_count
        self.assertGreaterEqual(metadata_reduction, original_count * 0.8, 
                               "Should remove at least 80% of metadata entries")
        
        # Verify image quality is preserved
        original_size = os.path.getsize(original_path)
        cleaned_size = os.path.getsize(cleaned_path)
        
        # Cleaned image should be smaller or similar size (not significantly larger)
        size_ratio = cleaned_size / original_size
        self.assertLessEqual(size_ratio, 1.1, "Cleaned image should not be significantly larger")
        self.assertGreaterEqual(size_ratio, 0.3, "Cleaned image should not be too small (corrupted)")
    
    def test_metadata_extraction_completeness(self):
        """Test that metadata extraction finds all major categories."""
        # Create image with comprehensive metadata
        image_path = self.create_image_with_metadata('comprehensive_metadata.jpg')
        
        # Extract metadata
        metadata = self.handler.extract_metadata(image_path)
        
        # Should not have errors
        self.assertNotIn('error', metadata, "Should successfully extract metadata")
        
        # Should have multiple sections
        self.assertGreater(len(metadata), 1, "Should have multiple metadata sections")
        
        # Check for expected metadata categories
        metadata_keys = set(metadata.keys())
        
        # Should have at least one of the major categories
        major_categories = {'EXIF', 'EXIF Details', 'GPS Location', 'File Info'}
        found_categories = metadata_keys.intersection(major_categories)
        self.assertGreater(len(found_categories), 0, 
                          f"Should find at least one major category. Found: {metadata_keys}")
        
        # Verify non-empty sections
        for section_name, section_data in metadata.items():
            if isinstance(section_data, dict):
                self.assertGreater(len(section_data), 0, 
                                 f"Section '{section_name}' should not be empty")
    
    def test_privacy_critical_metadata_removal(self):
        """Test removal of privacy-critical metadata like GPS location."""
        # Create image with GPS data
        image_path = self.create_image_with_metadata('gps_metadata.jpg')
        cleaned_path = os.path.join(self.temp_dir, 'no_gps.jpg')
        
        # Verify original has GPS data
        original_metadata = self.handler.extract_metadata(image_path)
        has_gps = any('GPS' in section or 'Location' in section 
                     for section in original_metadata.keys())
        
        if not has_gps:
            self.skipTest("Test image doesn't have GPS metadata")
        
        # Remove metadata
        self.assertTrue(self.handler.remove_metadata(image_path, cleaned_path))
        
        # Verify GPS data is removed
        cleaned_metadata = self.handler.extract_metadata(cleaned_path)
        has_gps_after = any('GPS' in section or 'Location' in section 
                           for section in cleaned_metadata.keys() 
                           if isinstance(cleaned_metadata[section], dict) and cleaned_metadata[section])
        
        self.assertFalse(has_gps_after, "GPS metadata should be completely removed")
    
    def test_error_handling_robustness(self):
        """Test error handling with various problematic scenarios."""
        # Test with non-existent file
        result = self.handler.extract_metadata('/nonexistent/path/image.jpg')
        self.assertIn('error', result)
        
        removal_result = self.handler.remove_metadata('/nonexistent/input.jpg', 
                                                     '/tmp/output.jpg')
        self.assertFalse(removal_result)
        
        # Test with unsupported format
        result = self.handler.extract_metadata('test.png')
        self.assertIn('error', result)
        self.assertEqual(result['error'], 'Unsupported file format')
        
        # Test with invalid output path
        image_path = self.create_image_with_metadata('test.jpg')
        invalid_output = '/root/no_permission/output.jpg'  # Likely no permission
        
        # Should handle permission errors gracefully
        removal_result = self.handler.remove_metadata(image_path, invalid_output)
        # This might succeed or fail depending on system, but shouldn't crash
        self.assertIsInstance(removal_result, bool)


class TestApplicationWorkflow(unittest.TestCase):
    """Test complete application workflows."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.handler = MetadataHandler()
    
    def test_supported_formats_comprehensive(self):
        """Test all supported formats are handled correctly."""
        supported_extensions = ['.jpg', '.jpeg', '.tiff', '.tif']
        unsupported_extensions = ['.png', '.gif', '.bmp', '.webp', '.svg', '.pdf']
        
        # Test supported formats
        for ext in supported_extensions:
            self.assertTrue(self.handler.is_supported_format(f'test{ext}'))
            self.assertTrue(self.handler.is_supported_format(f'test{ext.upper()}'))
        
        # Test unsupported formats
        for ext in unsupported_extensions:
            self.assertFalse(self.handler.is_supported_format(f'test{ext}'))
    
    def test_metadata_value_formatting_edge_cases(self):
        """Test metadata value formatting with edge cases."""
        test_cases = [
            # (input, expected_output_type, description)
            (None, str, "None values"),
            (b'', str, "Empty bytes"),
            (b'\x00\x00\x00', str, "Null bytes"),
            (b'test\x00trailing', str, "Bytes with null terminator"),
            (b'\xff\xfe\xfd', str, "Binary data"),
            ((0, 1), str, "Zero rational"),
            ((1, 0), str, "Division by zero"),
            ((100, 3), str, "Rational number"),
            ([], str, "Empty list"),
            (['a', 'b', 'c'], str, "List of strings"),
            ('', str, "Empty string"),
            ('  whitespace  ', str, "String with whitespace"),
            (42, str, "Integer"),
            (3.14159, str, "Float"),
        ]
        
        for input_value, expected_type, description in test_cases:
            with self.subTest(input_value=input_value, description=description):
                result = self.handler.format_metadata_value(input_value)
                self.assertIsInstance(result, expected_type, 
                                    f"Failed for {description}: {input_value}")
                # Result should be safe for display (no None, proper string)
                self.assertIsNotNone(result)


if __name__ == '__main__':
    unittest.main()
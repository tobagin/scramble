#!/usr/bin/env python3
"""
Security validation tests for Scramble.
Tests file validation, path sanitization, and security hardening.
"""
import os
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch, MagicMock

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from security_validators import SecurityValidator, create_security_validator


class TestSecurityValidator(unittest.TestCase):
    """Test cases for SecurityValidator."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.validator = create_security_validator()
        # Create a temporary directory for test files
        self.test_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        """Clean up test fixtures."""
        # Clean up temporary directory
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    def test_validator_creation(self):
        """Test SecurityValidator can be created."""
        validator = create_security_validator()
        self.assertIsInstance(validator, SecurityValidator)
        self.assertEqual(validator.max_file_size, 100 * 1024 * 1024)  # 100MB
        self.assertEqual(validator.max_dimension, 50000)
        self.assertEqual(validator.max_pixels, 100_000_000)
    
    def test_nonexistent_file_validation(self):
        """Test validation of non-existent file."""
        result = self.validator.validate_file_security("nonexistent.jpg")
        self.assertIsNotNone(result)
        self.assertEqual(result['error'], "File does not exist")
    
    def test_empty_file_validation(self):
        """Test validation of empty file."""
        # Create an empty file
        empty_file = os.path.join(self.test_dir, "empty.jpg")
        with open(empty_file, 'w') as f:
            pass  # Create empty file
        
        result = self.validator.validate_file_security(empty_file)
        self.assertIsNotNone(result)
        self.assertEqual(result['error'], "File is empty")
    
    def test_directory_validation(self):
        """Test validation rejects directories."""
        result = self.validator.validate_file_security(self.test_dir)
        self.assertIsNotNone(result)
        self.assertEqual(result['error'], "Path is not a regular file")
    
    def test_unsupported_format_validation(self):
        """Test validation of unsupported file format."""
        # Create a file with unsupported extension
        unsupported_file = os.path.join(self.test_dir, "test.png")
        with open(unsupported_file, 'w') as f:
            f.write("fake png content")
        
        result = self.validator.validate_file_security(unsupported_file)
        self.assertIsNotNone(result)
        self.assertEqual(result['error'], "Unsupported file format")
    
    def test_file_header_validation(self):
        """Test file header validation."""
        # Test valid JPEG header
        jpeg_file = os.path.join(self.test_dir, "test.jpg")
        with open(jpeg_file, 'wb') as f:
            f.write(b'\xff\xd8\xff\xe0\x00\x10JFIF')  # Valid JPEG header
        
        result = self.validator._validate_file_header(jpeg_file)
        self.assertTrue(result)
        
        # Test invalid header for JPEG
        fake_jpeg = os.path.join(self.test_dir, "fake.jpg")
        with open(fake_jpeg, 'wb') as f:
            f.write(b'not a jpeg header')
        
        result = self.validator._validate_file_header(fake_jpeg)
        self.assertFalse(result)
        
        # Test valid TIFF header (little-endian)
        tiff_file = os.path.join(self.test_dir, "test.tiff")
        with open(tiff_file, 'wb') as f:
            f.write(b'II*\x00')  # Valid TIFF header (little-endian)
        
        result = self.validator._validate_file_header(tiff_file)
        self.assertTrue(result)
        
        # Test valid TIFF header (big-endian)
        tiff_file2 = os.path.join(self.test_dir, "test2.tiff")
        with open(tiff_file2, 'wb') as f:
            f.write(b'MM\x00*')  # Valid TIFF header (big-endian)
        
        result = self.validator._validate_file_header(tiff_file2)
        self.assertTrue(result)
    
    def test_mime_type_validation(self):
        """Test MIME type validation."""
        # Create file with correct extension but check MIME validation
        test_file = os.path.join(self.test_dir, "test.jpg")
        with open(test_file, 'wb') as f:
            f.write(b'\xff\xd8\xff\xe0\x00\x10JFIF')
        
        # Mock mimetypes to return wrong MIME type
        with patch('mimetypes.guess_type') as mock_mime:
            mock_mime.return_value = ('text/plain', None)
            result = self.validator.validate_file_security(test_file)
            self.assertIsNotNone(result)
            self.assertEqual(result['error'], "Invalid MIME type for file")
    
    def test_large_file_validation(self):
        """Test validation of oversized files."""
        large_file = os.path.join(self.test_dir, "large.jpg")
        
        # Mock os.path.getsize to return large size
        with patch('os.path.getsize') as mock_size:
            mock_size.return_value = 200 * 1024 * 1024  # 200MB (over limit)
            
            with open(large_file, 'wb') as f:
                f.write(b'\xff\xd8\xff\xe0\x00\x10JFIF')
            
            result = self.validator.validate_file_security(large_file)
            self.assertIsNotNone(result)
            self.assertIn("File too large", result['error'])
    
    @patch('security_validators.HAS_PIL', True)
    def test_image_properties_validation(self):
        """Test image properties validation."""
        test_file = os.path.join(self.test_dir, "test.jpg")
        
        # Mock PIL.Image.open
        with patch('security_validators.Image.open') as mock_open:
            mock_img = MagicMock()
            mock_img.size = (1000, 1000)  # Valid dimensions
            mock_img.mode = 'RGB'  # Valid mode
            mock_img.format = 'JPEG'  # Valid format
            mock_open.return_value.__enter__.return_value = mock_img
            
            result = self.validator._validate_image_properties(test_file)
            self.assertTrue(result)
            
            # Test invalid dimensions
            mock_img.size = (0, 100)  # Invalid width
            result = self.validator._validate_image_properties(test_file)
            self.assertFalse(result)
            
            # Test too large dimensions
            mock_img.size = (60000, 60000)  # Over max_dimension
            result = self.validator._validate_image_properties(test_file)
            self.assertFalse(result)
            
            # Test too many pixels
            mock_img.size = (20000, 20000)  # 400 megapixels (over limit)
            result = self.validator._validate_image_properties(test_file)
            self.assertFalse(result)
            
            # Test invalid mode
            mock_img.size = (1000, 1000)
            mock_img.mode = 'INVALID'
            result = self.validator._validate_image_properties(test_file)
            self.assertFalse(result)
            
            # Test invalid format
            mock_img.mode = 'RGB'
            mock_img.format = 'PNG'  # Not supported
            result = self.validator._validate_image_properties(test_file)
            self.assertFalse(result)
    
    def test_path_sanitization(self):
        """Test path sanitization."""
        # Test normal path
        normal_path = "/path/to/file.jpg"
        sanitized = self.validator.sanitize_path(normal_path)
        self.assertTrue(sanitized.endswith("file.jpg"))
        
        # Test empty path
        empty_sanitized = self.validator.sanitize_path("")
        self.assertEqual(empty_sanitized, "")
        
        # Test None path
        none_sanitized = self.validator.sanitize_path(None)
        self.assertEqual(none_sanitized, "")
    
    def test_output_path_validation(self):
        """Test output path validation."""
        input_file = os.path.join(self.test_dir, "input.jpg")
        output_file = os.path.join(self.test_dir, "output.jpg")
        
        # Create input file
        with open(input_file, 'w') as f:
            f.write("test content")
        
        # Test valid output path
        result = self.validator.validate_output_path(output_file, input_file)
        self.assertIsNone(result)  # Should be valid
        
        # Test empty output path
        result = self.validator.validate_output_path("", input_file)
        self.assertEqual(result, "Output path is empty")
        
        # Test same as input path
        result = self.validator.validate_output_path(input_file, input_file)
        self.assertEqual(result, "Cannot overwrite input file")
        
        # Test nonexistent output directory
        bad_output = "/nonexistent/dir/output.jpg"
        result = self.validator.validate_output_path(bad_output, input_file)
        self.assertEqual(result, "Output directory does not exist")
    
    def test_is_supported_format(self):
        """Test supported format checking."""
        # Test supported formats
        self.assertTrue(self.validator._is_supported_format("test.jpg"))
        self.assertTrue(self.validator._is_supported_format("test.jpeg"))
        self.assertTrue(self.validator._is_supported_format("test.tiff"))
        self.assertTrue(self.validator._is_supported_format("test.tif"))
        self.assertTrue(self.validator._is_supported_format("TEST.JPG"))  # Case insensitive
        
        # Test unsupported formats
        self.assertFalse(self.validator._is_supported_format("test.png"))
        self.assertFalse(self.validator._is_supported_format("test.gif"))
        self.assertFalse(self.validator._is_supported_format("test.bmp"))
        self.assertFalse(self.validator._is_supported_format("test.txt"))
        self.assertFalse(self.validator._is_supported_format(""))
        self.assertFalse(self.validator._is_supported_format(None))
    
    def test_validation_with_PIL_unavailable(self):
        """Test validation when PIL is not available."""
        with patch('security_validators.HAS_PIL', False):
            test_file = os.path.join(self.test_dir, "test.jpg")
            with open(test_file, 'wb') as f:
                f.write(b'\xff\xd8\xff\xe0\x00\x10JFIF')
            
            result = self.validator._validate_image_properties(test_file)
            self.assertTrue(result)  # Should pass when PIL unavailable
    
    def test_security_exception_handling(self):
        """Test exception handling in security validation."""
        # Test with file that causes permission error
        restricted_file = os.path.join(self.test_dir, "restricted.jpg")
        with open(restricted_file, 'w') as f:
            f.write("test")
        
        # Mock os.access to simulate permission error
        with patch('os.access') as mock_access:
            mock_access.return_value = False
            result = self.validator.validate_file_security(restricted_file)
            self.assertIsNotNone(result)
            self.assertEqual(result['error'], "File is not readable")


if __name__ == '__main__':
    unittest.main()
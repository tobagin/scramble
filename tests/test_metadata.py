"""
Comprehensive tests for metadata handling functionality.
"""
import os
import tempfile
import unittest
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from metadata import MetadataHandler


class TestMetadataHandler(unittest.TestCase):
    """Test suite for MetadataHandler class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.handler = MetadataHandler()
        self.temp_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        """Clean up test fixtures."""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_supported_formats(self):
        """Test that supported formats are correctly identified."""
        # Test supported formats
        self.assertTrue(self.handler.is_supported_format('test.jpg'))
        self.assertTrue(self.handler.is_supported_format('test.jpeg'))
        self.assertTrue(self.handler.is_supported_format('test.tiff'))
        self.assertTrue(self.handler.is_supported_format('test.tif'))
        
        # Test case insensitive
        self.assertTrue(self.handler.is_supported_format('test.JPG'))
        self.assertTrue(self.handler.is_supported_format('test.TIFF'))
        
        # Test unsupported formats
        self.assertFalse(self.handler.is_supported_format('test.png'))
        self.assertFalse(self.handler.is_supported_format('test.gif'))
        self.assertFalse(self.handler.is_supported_format('test.txt'))
        self.assertFalse(self.handler.is_supported_format('test'))
        
        # Test edge cases
        self.assertFalse(self.handler.is_supported_format(''))
        self.assertFalse(self.handler.is_supported_format(None))
    
    def test_format_metadata_value(self):
        """Test metadata value formatting."""
        # Test None values
        self.assertEqual(self.handler.format_metadata_value(None), '')
        
        # Test string values
        self.assertEqual(self.handler.format_metadata_value('test'), 'test')
        self.assertEqual(self.handler.format_metadata_value('  test  '), 'test')
        
        # Test bytes values
        self.assertEqual(self.handler.format_metadata_value(b'test'), 'test')
        self.assertEqual(self.handler.format_metadata_value(b'test\x00'), 'test')
        
        # Test tuple values (rational numbers)
        self.assertEqual(self.handler.format_metadata_value((100, 1)), '100')
        self.assertEqual(self.handler.format_metadata_value((1, 100)), '0.01')
        self.assertEqual(self.handler.format_metadata_value((0, 1)), '0')
        
        # Test tuple with zero denominator
        self.assertEqual(self.handler.format_metadata_value((100, 0)), '100')
        
        # Test other tuple values
        self.assertEqual(self.handler.format_metadata_value(('a', 'b')), 'a, b')
        
        # Test numeric values
        self.assertEqual(self.handler.format_metadata_value(42), '42')
        self.assertEqual(self.handler.format_metadata_value(3.14), '3.14')
    
    @patch('metadata.os.path.exists')
    def test_extract_metadata_file_not_exists(self, mock_exists):
        """Test metadata extraction when file doesn't exist."""
        mock_exists.return_value = False
        
        result = self.handler.extract_metadata('nonexistent.jpg')
        self.assertIn('error', result)
        self.assertEqual(result['error'], 'File does not exist')
    
    def test_extract_metadata_unsupported_format(self):
        """Test metadata extraction for unsupported format."""
        result = self.handler.extract_metadata('test.png')
        self.assertIn('error', result)
        self.assertEqual(result['error'], 'Unsupported file format')
    
    @patch('metadata.piexif.load')
    @patch('metadata.os.path.exists')
    def test_extract_metadata_piexif_success(self, mock_exists, mock_piexif_load):
        """Test successful metadata extraction using piexif."""
        mock_exists.return_value = True
        mock_piexif_load.return_value = {
            '0th': {
                256: 1920,  # ImageWidth
                257: 1080,  # ImageHeight
            },
            'Exif': {
                36864: b'0100',  # ExifVersion
            },
            'GPS': {
                1: 'N',  # GPSLatitudeRef
            }
        }
        
        # Mock piexif.TAGS
        with patch('metadata.piexif.TAGS', {
            '0th': {256: {'name': 'ImageWidth'}, 257: {'name': 'ImageHeight'}},
            'Exif': {36864: {'name': 'ExifVersion'}},
            'GPS': {1: {'name': 'GPSLatitudeRef'}},
        }):
            result = self.handler.extract_metadata('test.jpg')
            
            self.assertNotIn('error', result)
            self.assertIn('EXIF', result)
            self.assertIn('GPS Location', result)
            self.assertEqual(result['EXIF']['ImageWidth'], '1920')
            self.assertEqual(result['GPS Location']['GPSLatitudeRef'], 'N')
    
    @patch('metadata.piexif.load')
    @patch('metadata.os.path.exists')
    @patch('metadata.HAS_PIEXIF', False)
    def test_extract_metadata_pillow_fallback(self, mock_exists, mock_piexif_load):
        """Test metadata extraction fallback to Pillow when piexif fails."""
        mock_exists.return_value = True
        mock_piexif_load.side_effect = Exception("piexif failed")
        
        # Mock Pillow Image.open and getexif
        mock_image = MagicMock()
        mock_image.getexif.return_value = {
            256: 1920,  # ImageWidth
            257: 1080,  # ImageHeight
        }
        
        with patch('metadata.Image.open') as mock_open:
            mock_open.return_value.__enter__.return_value = mock_image
            with patch('metadata.TAGS', {256: 'ImageWidth', 257: 'ImageHeight'}):
                result = self.handler.extract_metadata('test.jpg')
                
                self.assertNotIn('error', result)
                # Should have fallback data
    
    @patch('metadata.os.path.exists')
    def test_remove_metadata_file_not_exists(self, mock_exists):
        """Test metadata removal when input file doesn't exist."""
        mock_exists.return_value = False
        
        result = self.handler.remove_metadata('nonexistent.jpg', 'output.jpg')
        self.assertFalse(result)
    
    def test_remove_metadata_unsupported_format(self):
        """Test metadata removal for unsupported format."""
        result = self.handler.remove_metadata('test.png', 'output.png')
        self.assertFalse(result)
    
    @patch('metadata.piexif.remove')
    @patch('metadata.os.path.exists')
    def test_remove_metadata_piexif_success(self, mock_exists, mock_piexif_remove):
        """Test successful metadata removal using piexif."""
        mock_exists.return_value = True
        mock_piexif_remove.return_value = None  # Success
        
        result = self.handler.remove_metadata('test.jpg', 'output.jpg')
        self.assertTrue(result)
        mock_piexif_remove.assert_called_once_with('test.jpg', 'output.jpg')
    
    @patch('metadata.piexif.remove')
    @patch('metadata.os.path.exists')
    def test_remove_metadata_pillow_fallback(self, mock_exists, mock_piexif_remove):
        """Test metadata removal fallback to Pillow when piexif fails."""
        mock_exists.return_value = True
        mock_piexif_remove.side_effect = Exception("piexif failed")
        
        # Mock Pillow operations
        mock_image = MagicMock()
        mock_image.mode = 'RGB'
        mock_image.size = (1920, 1080)
        mock_image.format = 'JPEG'
        mock_image.getdata.return_value = [0] * (1920 * 1080)
        
        mock_clean_image = MagicMock()
        
        with patch('metadata.Image.open') as mock_open, \
             patch('metadata.Image.new') as mock_new:
            mock_open.return_value.__enter__.return_value = mock_image
            mock_new.return_value = mock_clean_image
            
            result = self.handler.remove_metadata('test.jpg', 'output.jpg')
            
            self.assertTrue(result)
            mock_clean_image.save.assert_called_once()
    
    def test_get_supported_formats(self):
        """Test getting supported formats."""
        formats = self.handler.get_supported_formats()
        expected = {'.jpg', '.jpeg', '.tiff', '.tif'}
        self.assertEqual(formats, expected)
        
        # Ensure returned set is a copy
        formats.add('.png')
        self.assertNotEqual(formats, self.handler.get_supported_formats())


class TestMetadataHandlerIntegration(unittest.TestCase):
    """Integration tests for MetadataHandler with real files."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.handler = MetadataHandler()
        self.temp_dir = tempfile.mkdtemp()
    
    def tearDown(self):
        """Clean up test fixtures."""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def create_test_image(self, filename, with_metadata=True):
        """Create a test image file with or without metadata."""
        from PIL import Image
        import io
        
        # Create a simple test image
        img = Image.new('RGB', (100, 100), color='red')
        
        # Add some basic EXIF data if requested
        if with_metadata:
            try:
                import piexif
                exif_dict = {
                    '0th': {
                        piexif.ImageIFD.ImageWidth: 100,
                        piexif.ImageIFD.ImageLength: 100,
                        piexif.ImageIFD.Software: "Test Software"
                    }
                }
                exif_bytes = piexif.dump(exif_dict)
                
                # Save with EXIF
                filepath = os.path.join(self.temp_dir, filename)
                img.save(filepath, 'JPEG', exif=exif_bytes)
                return filepath
            except ImportError:
                pass
        
        # Save without metadata
        filepath = os.path.join(self.temp_dir, filename)
        img.save(filepath, 'JPEG')
        return filepath
    
    def test_real_image_metadata_extraction(self):
        """Test metadata extraction with a real image file."""
        # Create test image with metadata
        image_path = self.create_test_image('test_with_metadata.jpg', with_metadata=True)
        
        # Extract metadata
        result = self.handler.extract_metadata(image_path)
        
        # Should not have errors
        self.assertNotIn('error', result)
        
        # Should have some metadata or file info
        self.assertTrue(len(result) > 0)
    
    def test_real_image_metadata_removal(self):
        """Test metadata removal with a real image file."""
        # Create test image with metadata
        input_path = self.create_test_image('test_input.jpg', with_metadata=True)
        output_path = os.path.join(self.temp_dir, 'test_output.jpg')
        
        # Remove metadata
        result = self.handler.remove_metadata(input_path, output_path)
        
        # Should succeed
        self.assertTrue(result)
        
        # Output file should exist
        self.assertTrue(os.path.exists(output_path))
        
        # Output should be smaller or equal (metadata removed)
        input_size = os.path.getsize(input_path)
        output_size = os.path.getsize(output_path)
        self.assertLessEqual(output_size, input_size)


if __name__ == '__main__':
    unittest.main()
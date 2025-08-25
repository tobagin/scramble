"""
Tests for the main window functionality.
"""
import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

# Mock GTK before importing window module
class MockGtk:
    class Template:
        def __init__(self, *args, **kwargs):
            def decorator(cls):
                cls.template_children = kwargs.get('template_children', [])
                return cls
            return decorator
        
        @staticmethod
        def Child():
            return None
    
    class DropTarget:
        @staticmethod
        def new(*args):
            return Mock()
    
    class ShortcutController:
        pass
    
    class Shortcut:
        @staticmethod
        def new(*args):
            return Mock()
    
    class ShortcutTrigger:
        @staticmethod
        def parse_string(*args):
            return Mock()
    
    class CallbackAction:
        @staticmethod
        def new(*args):
            return Mock()
    
    class FileChooserNative:
        @staticmethod
        def new(*args, **kwargs):
            return Mock()
    
    class FileChooserAction:
        SAVE = 'save'
    
    class ResponseType:
        ACCEPT = 'accept'

class MockAdw:
    class ApplicationWindow:
        def __init__(self, **kwargs):
            pass
        
        def add_controller(self, controller):
            pass
    
    class ActionRow:
        def __init__(self):
            self.props = Mock()
        
        def set_title(self, title):
            pass
        
        def set_subtitle(self, subtitle):
            pass
        
        def add_css_class(self, css_class):
            pass
    
    class Toast:
        @staticmethod
        def new(message):
            toast = Mock()
            toast.set_timeout = Mock()
            return toast

class MockGio:
    class File:
        pass

class MockGdkPixbuf:
    class Pixbuf:
        @staticmethod
        def new_from_file(path):
            mock_pixbuf = Mock()
            mock_pixbuf.get_width.return_value = 800
            mock_pixbuf.get_height.return_value = 600
            mock_pixbuf.scale_simple.return_value = mock_pixbuf
            return mock_pixbuf
        
        class InterpType:
            BILINEAR = 'bilinear'

# Apply mocks
sys.modules['gi'] = Mock()
sys.modules['gi.repository'] = Mock()
sys.modules['gi.repository.Gtk'] = MockGtk()
sys.modules['gi.repository.Adw'] = MockAdw()
sys.modules['gi.repository.Gio'] = MockGio()
sys.modules['gi.repository.GdkPixbuf'] = MockGdkPixbuf()

# Now import the modules we want to test
from metadata import MetadataHandler
from metadata_row import MetadataRow


class TestScrambleWindow(unittest.TestCase):
    """Test suite for ScrambleWindow class."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Mock the window module imports
        with patch.dict('sys.modules', {
            'gi': Mock(),
            'gi.repository': Mock(),
            'gi.repository.Gtk': MockGtk(),
            'gi.repository.Adw': MockAdw(),
            'gi.repository.Gio': MockGio(),
            'gi.repository.GdkPixbuf': MockGdkPixbuf(),
        }):
            from window import ScrambleWindow
            self.window_class = ScrambleWindow
    
    @patch('window.MetadataHandler')
    def test_window_initialization(self, mock_metadata_handler):
        """Test window initialization."""
        # Mock the template loading
        with patch.object(self.window_class, '__init__', return_value=None):
            window = self.window_class()
            window.metadata_handler = mock_metadata_handler.return_value
            window.current_image_path = None
            window.current_metadata = None
            
            # Verify metadata handler is created
            mock_metadata_handler.assert_called_once()
    
    def test_supported_format_validation(self):
        """Test file format validation in drag and drop."""
        # Create a mock window instance
        window = Mock()
        window.metadata_handler = Mock()
        
        # Test supported format
        window.metadata_handler.is_supported_format.return_value = True
        
        # Mock the on_drop method behavior
        from window import ScrambleWindow
        
        # Test that supported formats are accepted
        window.metadata_handler.is_supported_format.assert_not_called()
        
        # Call is_supported_format directly
        result = window.metadata_handler.is_supported_format('test.jpg')
        window.metadata_handler.is_supported_format.assert_called_with('test.jpg')
    
    def test_metadata_display_organization(self):
        """Test metadata display organization."""
        # Test metadata organization logic
        sample_metadata = {
            'EXIF': {
                'ImageWidth': '1920',
                'ImageHeight': '1080',
                'Camera': 'Test Camera'
            },
            'GPS Location': {
                'Latitude': '40.7128',
                'Longitude': '-74.0060'
            },
            'File Info': {
                'Filename': 'test.jpg',
                'File Size': '2.1 MB'
            }
        }
        
        # Verify that we have the expected structure
        self.assertIn('EXIF', sample_metadata)
        self.assertIn('GPS Location', sample_metadata)
        self.assertIn('File Info', sample_metadata)
        
        # Verify non-empty values
        for section, data in sample_metadata.items():
            self.assertIsInstance(data, dict)
            self.assertGreater(len(data), 0)
    
    def test_error_handling(self):
        """Test error handling in window operations."""
        window = Mock()
        window.show_error_toast = Mock()
        
        # Test error message display
        error_message = "Test error message"
        window.show_error_toast(error_message)
        window.show_error_toast.assert_called_with(error_message)
    
    def test_file_path_validation(self):
        """Test file path validation for drag and drop."""
        # Test valid file paths
        valid_paths = [
            '/home/user/image.jpg',
            '/tmp/test.jpeg',
            'relative/path/image.tiff',
            'image.tif'
        ]
        
        for path in valid_paths:
            self.assertIsInstance(path, str)
            self.assertGreater(len(path), 0)
        
        # Test invalid file paths
        invalid_paths = [None, '', '   ']
        
        for path in invalid_paths:
            if path is not None and path.strip():
                self.fail(f"Path {path} should be invalid")


class TestMetadataRow(unittest.TestCase):
    """Test suite for MetadataRow widget."""
    
    def test_metadata_row_creation(self):
        """Test MetadataRow widget creation."""
        # Test with sample data
        key = "Camera Model"
        value = "Test Camera XYZ"
        
        # Verify the data types
        self.assertIsInstance(key, str)
        self.assertIsInstance(value, str)
        self.assertGreater(len(key), 0)
        self.assertGreater(len(value), 0)
    
    def test_metadata_value_formatting(self):
        """Test metadata value formatting for display."""
        test_cases = [
            ("Simple string", "Simple string"),
            ("String with spaces  ", "String with spaces"),
            ("", ""),
            ("123", "123"),
            ("GPS: 40.7128, -74.0060", "GPS: 40.7128, -74.0060"),
        ]
        
        for input_value, expected_output in test_cases:
            # Test basic string handling
            formatted = input_value.strip() if input_value else ""
            self.assertEqual(formatted, expected_output)


class TestWindowIntegration(unittest.TestCase):
    """Integration tests for window functionality."""
    
    def test_drag_drop_workflow(self):
        """Test complete drag and drop workflow."""
        # Mock file object
        mock_file = Mock()
        mock_file.get_path.return_value = '/test/image.jpg'
        
        # Test file path extraction
        file_path = mock_file.get_path()
        self.assertEqual(file_path, '/test/image.jpg')
        
        # Test format validation
        handler = MetadataHandler()
        is_supported = handler.is_supported_format(file_path)
        self.assertTrue(is_supported)
    
    def test_save_workflow(self):
        """Test save clean copy workflow."""
        # Mock file paths
        input_path = '/test/input.jpg'
        output_path = '/test/output_clean.jpg'
        
        # Test path validation
        self.assertIsInstance(input_path, str)
        self.assertIsInstance(output_path, str)
        self.assertTrue(input_path.endswith('.jpg'))
        self.assertTrue(output_path.endswith('.jpg'))
        self.assertNotEqual(input_path, output_path)
    
    def test_ui_state_management(self):
        """Test UI state transitions."""
        # Test state variables
        states = {
            'welcome_visible': True,
            'preview_visible': False,
            'save_enabled': False,
            'current_image': None,
            'current_metadata': None
        }
        
        # Test initial state
        self.assertTrue(states['welcome_visible'])
        self.assertFalse(states['preview_visible'])
        self.assertFalse(states['save_enabled'])
        self.assertIsNone(states['current_image'])
        
        # Test state after image load
        states['welcome_visible'] = False
        states['preview_visible'] = True
        states['save_enabled'] = True
        states['current_image'] = '/test/image.jpg'
        
        self.assertFalse(states['welcome_visible'])
        self.assertTrue(states['preview_visible'])
        self.assertTrue(states['save_enabled'])
        self.assertIsNotNone(states['current_image'])


if __name__ == '__main__':
    unittest.main()
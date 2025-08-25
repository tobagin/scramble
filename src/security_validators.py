"""
Security validation utilities for Scramble.
Provides file validation, sanitization, and security hardening functions.
"""

import os
import logging
import mimetypes
from typing import Dict, Any, Optional

# Set up logging
logger = logging.getLogger(__name__)

# Try to import PIL/Pillow for image validation
try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    logger.warning("PIL/Pillow not available for enhanced image validation")


class SecurityValidator:
    """Security validation utilities for file processing."""
    
    def __init__(self):
        self.supported_formats = {'.jpg', '.jpeg', '.tiff', '.tif'}
        self.supported_mimes = {'image/jpeg', 'image/tiff'}
        self.max_file_size = 100 * 1024 * 1024  # 100MB limit
        self.max_dimension = 50000  # Maximum image dimension in pixels
        self.max_pixels = 100_000_000  # 100 megapixels
    
    def validate_file_security(self, file_path: str) -> Optional[Dict[str, str]]:
        """Validate file for security concerns before processing.
        
        Args:
            file_path: Path to the file to validate
            
        Returns:
            Error dictionary if validation fails, None if validation passes
        """
        try:
            # Check if file exists and is accessible
            if not os.path.exists(file_path):
                return {"error": "File does not exist"}
            
            # Resolve path to prevent directory traversal attacks
            resolved_path = os.path.realpath(file_path)
            if not os.path.exists(resolved_path):
                return {"error": "Invalid file path"}
            
            # Check if it's actually a file (not a directory, symlink, etc.)
            if not os.path.isfile(resolved_path):
                return {"error": "Path is not a regular file"}
            
            # Check file permissions
            if not os.access(resolved_path, os.R_OK):
                return {"error": "File is not readable"}
            
            # Check file size
            file_size = os.path.getsize(resolved_path)
            if file_size == 0:
                return {"error": "File is empty"}
            if file_size > self.max_file_size:
                return {"error": f"File too large (max {self.max_file_size // (1024*1024)}MB)"}
            
            # Validate file extension
            if not self._is_supported_format(resolved_path):
                return {"error": "Unsupported file format"}
            
            # Validate MIME type
            mime_type, _ = mimetypes.guess_type(resolved_path)
            if mime_type not in self.supported_mimes:
                return {"error": "Invalid MIME type for file"}
            
            # Basic file header validation
            if not self._validate_file_header(resolved_path):
                return {"error": "Invalid file header - possible file type mismatch"}
            
            # Image-specific validation
            if not self._validate_image_properties(resolved_path):
                return {"error": "Invalid or potentially malicious image"}
            
            return None  # Validation passed
            
        except Exception as e:
            logger.error(f"Security validation failed for {file_path}: {e}")
            return {"error": "File validation failed"}
    
    def _is_supported_format(self, file_path: str) -> bool:
        """Check if the file format is supported."""
        if not file_path:
            return False
        ext = os.path.splitext(file_path)[1].lower()
        return ext in self.supported_formats
    
    def _validate_file_header(self, file_path: str) -> bool:
        """Validate file magic bytes match expected format.
        
        Args:
            file_path: Path to the file
            
        Returns:
            True if header is valid, False otherwise
        """
        try:
            with open(file_path, 'rb') as f:
                header = f.read(16)  # Read first 16 bytes
                
            if len(header) < 4:
                return False
                
            # JPEG magic bytes
            if header.startswith(b'\xff\xd8\xff'):
                return file_path.lower().endswith(('.jpg', '.jpeg'))
            
            # TIFF magic bytes (little-endian and big-endian)
            if header.startswith(b'II*\x00') or header.startswith(b'MM\x00*'):
                return file_path.lower().endswith(('.tiff', '.tif'))
            
            return False
            
        except Exception as e:
            logger.warning(f"Header validation failed for {file_path}: {e}")
            return False
    
    def _validate_image_properties(self, file_path: str) -> bool:
        """Validate image properties for safety.
        
        Args:
            file_path: Path to the image file
            
        Returns:
            True if image is safe, False otherwise
        """
        try:
            if not HAS_PIL:
                logger.warning("PIL not available for image validation")
                return True  # Skip validation if PIL not available
                
            with Image.open(file_path) as img:
                # Check image dimensions
                width, height = img.size
                if width <= 0 or height <= 0:
                    logger.warning(f"Invalid image dimensions: {width}x{height}")
                    return False
                    
                if width > self.max_dimension or height > self.max_dimension:
                    logger.warning(f"Image too large: {width}x{height} (max {self.max_dimension})")
                    return False
                
                # Check for reasonable pixel count to prevent decompression bombs
                pixel_count = width * height
                if pixel_count > self.max_pixels:
                    logger.warning(f"Too many pixels: {pixel_count} (max {self.max_pixels})")
                    return False
                
                # Validate image mode
                valid_modes = {'RGB', 'RGBA', 'L', 'P', 'CMYK', 'YCbCr', 'LAB', 'HSV'}
                if img.mode not in valid_modes:
                    logger.warning(f"Unusual image mode: {img.mode}")
                    return False
                
                # Basic format validation
                if img.format not in {'JPEG', 'TIFF'}:
                    logger.warning(f"Unexpected image format: {img.format}")
                    return False
                
            return True
            
        except Exception as e:
            logger.warning(f"Image validation failed for {file_path}: {e}")
            return False
    
    def sanitize_path(self, path: str) -> str:
        """Sanitize a file path to prevent directory traversal attacks.
        
        Args:
            path: The file path to sanitize
            
        Returns:
            Sanitized path
        """
        if not path:
            return ""
        
        # Resolve to absolute path and normalize
        try:
            sanitized = os.path.realpath(os.path.abspath(path))
            # Additional validation could be added here
            return sanitized
        except Exception as e:
            logger.warning(f"Path sanitization failed for {path}: {e}")
            return ""
    
    def validate_output_path(self, output_path: str, input_path: str) -> Optional[str]:
        """Validate that an output path is safe to write to.
        
        Args:
            output_path: Proposed output file path
            input_path: Input file path for reference
            
        Returns:
            Error message if validation fails, None if path is safe
        """
        try:
            if not output_path:
                return "Output path is empty"
            
            # Sanitize the path
            sanitized_output = self.sanitize_path(output_path)
            if not sanitized_output:
                return "Invalid output path"
            
            # Check if output directory exists and is writable
            output_dir = os.path.dirname(sanitized_output)
            if not os.path.exists(output_dir):
                return "Output directory does not exist"
            
            if not os.access(output_dir, os.W_OK):
                return "Output directory is not writable"
            
            # Prevent overwriting the input file
            if os.path.realpath(sanitized_output) == os.path.realpath(input_path):
                return "Cannot overwrite input file"
            
            # Check if output file already exists and warn
            if os.path.exists(sanitized_output):
                logger.info(f"Output file {sanitized_output} already exists and will be overwritten")
            
            return None  # Path is safe
            
        except Exception as e:
            logger.error(f"Output path validation failed: {e}")
            return "Output path validation failed"


def create_security_validator() -> SecurityValidator:
    """Factory function to create a SecurityValidator instance."""
    return SecurityValidator()
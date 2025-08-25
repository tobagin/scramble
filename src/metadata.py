import os
import logging
import tempfile
import hashlib
import mimetypes
from pathlib import Path
from typing import Dict, Any, Optional
from scramble.security_validators import create_security_validator

# Set up logging
logger = logging.getLogger(__name__)

# Try to import PIL/Pillow
try:
    from PIL import Image
    from PIL.ExifTags import TAGS
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    logger.warning("PIL/Pillow not available")

# Try to import piexif, fall back to Pillow-only if not available
try:
    import piexif
    HAS_PIEXIF = True
except ImportError:
    HAS_PIEXIF = False
    logger.warning("piexif not available, using Pillow-only metadata handling")


class MetadataHandler:
    """Handler for extracting and removing metadata from image files."""
    
    def __init__(self):
        self.supported_formats = {'.jpg', '.jpeg', '.tiff', '.tif'}
        self.supported_mimes = {'image/jpeg', 'image/tiff'}
        self.max_file_size = 100 * 1024 * 1024  # 100MB limit
        self.max_dimension = 50000  # Maximum image dimension in pixels
        
        # Initialize security validator
        self.security_validator = create_security_validator()
        
        self.section_names = {
            '0th': 'EXIF',
            'Exif': 'EXIF Details', 
            'GPS': 'GPS Location',
            '1st': 'Thumbnail',
            'Interop': 'Interoperability'
        }

    def extract_metadata(self, file_path: str) -> Dict[str, Any]:
        """Extract all metadata from an image file using multiple methods.
        
        Args:
            file_path: Path to the image file
            
        Returns:
            Dictionary containing organized metadata sections
        """
        try:
            # Security validation
            validation_result = self.security_validator.validate_file_security(file_path)
            if validation_result is not None:
                return validation_result

            metadata = {}
            
            # Try piexif first for EXIF data
            try:
                exif_dict = piexif.load(file_path)
                metadata.update(self._process_piexif_data(exif_dict))
            except Exception as e:
                logger.warning(f"piexif extraction failed: {e}")
                # Fallback to Pillow EXIF extraction
                try:
                    metadata.update(self._process_pillow_exif(file_path))
                except Exception as pillow_error:
                    logger.warning(f"Pillow EXIF extraction failed: {pillow_error}")
            
            # Add basic file information
            try:
                file_info = self._get_file_info(file_path)
                if file_info:
                    metadata['File Info'] = file_info
            except Exception as e:
                logger.warning(f"File info extraction failed: {e}")
            
            return metadata if metadata else {"info": "No metadata found"}
            
        except Exception as e:
            logger.error(f"Metadata extraction failed for {file_path}: {e}")
            return {"error": f"Failed to extract metadata: {str(e)}"}
    
    def _process_piexif_data(self, exif_dict: Dict) -> Dict[str, Any]:
        """Process EXIF data extracted by piexif."""
        metadata = {}
        
        for ifd in ("0th", "Exif", "GPS", "1st", "Interop"):
            if ifd in exif_dict and exif_dict[ifd]:
                section_data = {}
                for tag in exif_dict[ifd]:
                    try:
                        if tag in piexif.TAGS[ifd]:
                            tag_name = piexif.TAGS[ifd][tag]["name"]
                            value = exif_dict[ifd][tag]
                            formatted_value = self.format_metadata_value(value)
                            if formatted_value and formatted_value.strip():
                                section_data[tag_name] = formatted_value
                    except Exception as e:
                        logger.debug(f"Error processing tag {tag} in {ifd}: {e}")
                        continue
                
                if section_data:
                    section_name = self.section_names.get(ifd, ifd)
                    metadata[section_name] = section_data
        
        return metadata
    
    def _process_pillow_exif(self, file_path: str) -> Dict[str, Any]:
        """Fallback EXIF extraction using Pillow."""
        metadata = {}
        
        try:
            with Image.open(file_path) as img:
                exif_data = img.getexif()
                if exif_data:
                    section_data = {}
                    for tag_id, value in exif_data.items():
                        try:
                            tag_name = TAGS.get(tag_id, f"Tag_{tag_id}")
                            formatted_value = self.format_metadata_value(value)
                            if formatted_value and formatted_value.strip():
                                section_data[tag_name] = formatted_value
                        except Exception as e:
                            logger.debug(f"Error processing Pillow tag {tag_id}: {e}")
                            continue
                    
                    if section_data:
                        metadata['EXIF (Pillow)'] = section_data
        except Exception as e:
            logger.warning(f"Pillow EXIF processing failed: {e}")
            
        return metadata
    
    def _get_file_info(self, file_path: str) -> Dict[str, str]:
        """Get basic file information."""
        try:
            stat = os.stat(file_path)
            file_size = stat.st_size
            
            # Format file size
            if file_size < 1024:
                size_str = f"{file_size} bytes"
            elif file_size < 1024 * 1024:
                size_str = f"{file_size / 1024:.1f} KB"
            else:
                size_str = f"{file_size / (1024 * 1024):.1f} MB"
            
            with Image.open(file_path) as img:
                return {
                    'Filename': os.path.basename(file_path),
                    'File Size': size_str,
                    'Image Size': f"{img.width} x {img.height} pixels",
                    'Format': img.format or 'Unknown',
                    'Mode': img.mode
                }
        except Exception as e:
            logger.warning(f"Could not get file info: {e}")
            return {}

    def remove_metadata(self, input_path: str, output_path: str) -> bool:
        """Create a clean copy of the image without metadata.
        
        Uses piexif.remove() as the primary method with Pillow fallback.
        
        Args:
            input_path: Path to the original image
            output_path: Path where clean image should be saved
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Security validation for input file
            validation_result = self.security_validator.validate_file_security(input_path)
            if validation_result is not None:
                logger.error(f"Input file validation failed: {validation_result.get('error', 'Unknown error')}")
                return False
            
            # Security validation for output path
            output_validation = self.security_validator.validate_output_path(output_path, input_path)
            if output_validation is not None:
                logger.error(f"Output path validation failed: {output_validation}")
                return False
            
            # Method 1: Try piexif.remove() for reliable EXIF removal
            try:
                piexif.remove(input_path, output_path)
                logger.info(f"Metadata removed using piexif: {output_path}")
                return True
            except Exception as piexif_error:
                logger.warning(f"piexif.remove() failed: {piexif_error}")
                
            # Method 2: Fallback to Pillow method
            try:
                with Image.open(input_path) as img:
                    # Get image format and save parameters
                    img_format = img.format
                    save_kwargs = {'optimize': True}
                    
                    # Set quality for JPEG
                    if img_format == 'JPEG':
                        save_kwargs['quality'] = 95
                        save_kwargs['exif'] = b''  # Empty EXIF data
                    
                    # Create clean copy without metadata
                    clean_image = Image.new(img.mode, img.size)
                    clean_image.putdata(list(img.getdata()))
                    
                    # Preserve color profile if needed
                    if 'icc_profile' in img.info:
                        save_kwargs['icc_profile'] = img.info['icc_profile']
                    
                    # Save the clean image
                    clean_image.save(output_path, format=img_format, **save_kwargs)
                    logger.info(f"Metadata removed using Pillow fallback: {output_path}")
                    return True
                    
            except Exception as pillow_error:
                logger.error(f"Pillow fallback failed: {pillow_error}")
                return False
                
        except Exception as e:
            logger.error(f"Error removing metadata from {input_path}: {e}")
            return False

    def is_supported_format(self, file_path: str) -> bool:
        """Check if the file format is supported.
        
        Args:
            file_path: Path to the file to check
            
        Returns:
            True if format is supported, False otherwise
        """
        if not file_path:
            return False
            
        ext = os.path.splitext(file_path)[1].lower()
        return ext in self.supported_formats
    
    def get_supported_formats(self) -> set:
        """Get the set of supported file extensions.
        
        Returns:
            Set of supported file extensions
        """
        return self.supported_formats.copy()

    def format_metadata_value(self, value: Any) -> str:
        """Format metadata values for display with enhanced handling.
        
        Args:
            value: Raw metadata value from EXIF data
            
        Returns:
            Formatted string representation suitable for display
        """
        if value is None:
            return ''
            
        if isinstance(value, bytes):
            try:
                # Try UTF-8 decode first
                decoded = value.decode('utf-8').strip('\x00')
                return decoded if decoded else ''
            except UnicodeDecodeError:
                try:
                    # Try latin-1 as fallback
                    decoded = value.decode('latin-1').strip('\x00')
                    return decoded if decoded else ''
                except UnicodeDecodeError:
                    # Return hex representation for binary data
                    return f"<binary data: {len(value)} bytes>"
                    
        elif isinstance(value, tuple):
            if len(value) == 2 and all(isinstance(x, int) for x in value):
                # Rational number (common in EXIF)
                if value[1] != 0:
                    result = value[0] / value[1]
                    return f"{result:.6g}" if result != int(result) else str(int(result))
                else:
                    return str(value[0])
            else:
                # General tuple formatting
                formatted_items = [self.format_metadata_value(item) for item in value]
                return ', '.join(item for item in formatted_items if item)
                
        elif isinstance(value, (list, tuple)):
            formatted_items = [self.format_metadata_value(item) for item in value]
            return ', '.join(item for item in formatted_items if item)
            
        elif isinstance(value, str):
            # Clean up string values
            cleaned = value.strip('\x00').strip()
            return cleaned
            
        else:
            # Handle numbers and other types
            str_value = str(value).strip()
            return str_value if str_value else ''
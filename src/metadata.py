import os
from PIL import Image
import piexif
from typing import Dict, Any, Optional


class MetadataHandler:
    def __init__(self):
        self.supported_formats = {'.jpg', '.jpeg', '.tiff', '.tif'}

    def extract_metadata(self, file_path: str) -> Dict[str, Any]:
        """Extract all metadata from an image file."""
        try:
            metadata = {}
            
            # Check if file format is supported
            if not self.is_supported_format(file_path):
                return {"error": "Unsupported file format"}

            # Extract EXIF data using piexif
            exif_dict = piexif.load(file_path)
            
            # Process EXIF data
            for ifd in ("0th", "Exif", "GPS", "1st"):
                if ifd in exif_dict:
                    metadata[ifd] = {}
                    for tag in exif_dict[ifd]:
                        tag_name = piexif.TAGS[ifd][tag]["name"]
                        value = exif_dict[ifd][tag]
                        metadata[ifd][tag_name] = self.format_metadata_value(value)

            return metadata
            
        except Exception as e:
            return {"error": f"Failed to extract metadata: {str(e)}"}

    def remove_metadata(self, input_path: str, output_path: str) -> bool:
        """Create a clean copy of the image without metadata."""
        try:
            # Open the image
            with Image.open(input_path) as img:
                # Create a copy without metadata
                data = list(img.getdata())
                clean_image = Image.new(img.mode, img.size)
                clean_image.putdata(data)
                
                # Save the clean image
                clean_image.save(output_path, optimize=True, quality=95)
                
            return True
            
        except Exception as e:
            print(f"Error removing metadata: {e}")
            return False

    def is_supported_format(self, file_path: str) -> bool:
        """Check if the file format is supported."""
        ext = os.path.splitext(file_path)[1].lower()
        return ext in self.supported_formats

    def format_metadata_value(self, value: Any) -> str:
        """Format metadata values for display."""
        if isinstance(value, bytes):
            try:
                return value.decode('utf-8')
            except UnicodeDecodeError:
                return str(value)
        elif isinstance(value, tuple):
            return str(value)
        else:
            return str(value)
## FEATURE:

-   A simple, privacy-focused utility, **Scramble**, for viewing and removing metadata from images.
-   A clean and intuitive interface built with **GTK4** and **Libadwaita**, featuring a large drag-and-drop area.
-   **Metadata Inspector**: After dropping an image, the app displays all of its readable metadata (EXIF, IPTC, XMP) in a clear list.
-   **One-Click Scrubbing**: A single button to remove all metadata, creating a clean version of the image.
-   **Safe by Default**: The application never modifies the original file. It always saves a new, scrubbed copy to a location chosen by the user.
-   Packaged as a **Flatpak** application for secure and easy installation.

---

## EXAMPLES:

The application will be structured around a core metadata handling module with a straightforward GTK front-end.

-   `scramble/main.py` - The main application entry point.
-   `scramble/window.py` - Defines the main `Adw.ApplicationWindow`. It will manage the drag-and-drop target, the image preview, and the metadata display area.
-   `scramble/metadata.py` - The core logic module responsible for all metadata operations. It will use a library like **Pillow** to read image data and its metadata, and to write a new, clean image file without the metadata.
-   `data/ui/` - A directory for **Blueprint** UI files.
    -   `window.blp`: Defines the main window layout, including the "Drop Image Here" welcome screen, the image preview, a `Gtk.ListView` for the metadata, and the "Save Clean Copy..." button.
    -   `metadata_row.blp`: A UI template for a single row in the metadata list, showing a key and its value.
-   `com.github.your_username.Scramble.json` - The **Flatpak** manifest for building the application.

---

## DOCUMENTATION:

Development will be guided by documentation for the chosen image manipulation library and the standard GNOME platform components.

### Core Logic
-   **Pillow (PIL Fork)**: `https://pillow.readthedocs.io/en/stable/`
-   **piexif (for advanced EXIF)**: `https://piexif.readthedocs.io/en/latest/`

### Frontend & Packaging
-   **GTK4**: `https://docs.gtk.org/gtk4/`
-   **Libadwaita**: `https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/`
-   **Blueprint**: `https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/`
-   **Flatpak**: `https://docs.flatpak.org/`

---

## OTHER CONSIDERATIONS:

-   **Non-Destructive Workflow**: The application must **never** overwrite the original image. This is the most critical design principle. The "Save" action will always bring up a file chooser dialog to save a new copy.
-   **Supported Formats**: The initial version will focus on JPEG and TIFF files, which are known to contain extensive EXIF metadata. Support for PNG and other formats can be expanded later.
-   **User Experience**: The UI should be unambiguous about the process. A clear visual distinction between the "before" (with metadata) and "after" (scrubbed) states is important.
-   **Flatpak Portals**: The application will rely on Flatpak portals for file access. Drag-and-drop and the `Gtk.FileChooserNative` dialog provide secure, user-mediated access to files without requiring broad filesystem permissions in the manifest.
-   **Privacy**: The `README.md` will explicitly state the app's privacy policy: it operates entirely offline on the local machine and does not collect or transmit any user data or images.

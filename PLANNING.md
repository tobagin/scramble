# Project Planning: GTK4 Python Application with Blueprint

This document outlines the architecture, conventions, and technologies for this project. The goal is to create a modern, maintainable, and distributable GTK4 application using best practices for the GNOME ecosystem, with a focus on developer experience using the **Blueprint** syntax.

-----

## 1\. Project Architecture

The application will follow a **Model-View-Controller (MVC)**-like pattern, adapted for the GTK framework.

  * **Model**: The data and business logic layer. This part of the application is pure Python and completely independent of the UI. It will manage the application's state, handle data processing, and interact with any backend services or files.
  * **View**: The presentation layer, defined using **Blueprint files (`.blp`)**. Blueprint is a human-readable markup language that compiles into the standard GTK `.ui` XML format. It offers a more concise and developer-friendly way to build user interfaces. LibAdwaita will be used for high-quality, adaptive UI components that integrate well with the GNOME desktop.
  * **Controller**: The logic that connects the Model and the View. This will be the Python code within the GTK Window and Widget classes. These classes will load the UI definitions, connect signal handlers (e.g., button clicks), and update the View based on changes in the Model, and vice-versa.

-----

## 2\. Technology Stack 🧑‍💻

  * **Language**: **Python 3.12**
  * **UI Toolkit**: **GTK4** (targeting version 4.19.3 via the GNOME runtime)
  * **Widget Library**: **LibAdwaita** (targeting version 1.7 via the GNOME runtime)
  * **UI Definition**: **Blueprint** (using `blueprint-compiler` v0.18.0)
  * **Build System**: **Meson**
  * **Packaging**: **Flatpak**
  * **Distribution**: **Flathub**

-----

## 3\. File Structure 📂

The project will adhere to the standard GNOME application structure, with Flatpak manifests organized into a dedicated directory.

```plaintext
projectname/
├── data/
│   ├── io.github.tobagin.projectname.appdata.xml.in
│   ├── io.github.tobagin.projectname.desktop.in
│   ├── icons/
│   │   ├── ...
│   ├── resources/
│   │   └── projectname.gresource.xml
│   └── ui/
│       ├── main_window.blp
│       └── preferences_dialog.blp
├── packaging/
│   ├── io.github.tobagin.projectname-local.yml
│   └── io.github.tobagin.projectname.yml
├── po/
│   ├── LINGUAS
│   └── projectname.pot
├── src/
│   ├── __main__.py
│   ├── main_window.py
│   ├── preferences_dialog.py
│   ├── projectname.in
│   └── _version.py
├── subprojects/
│   └── # Meson subprojects (if any)
├── .gitignore
├── build.sh
├── meson.build
├── meson_post_install.py
└── README.md
```

### Key File Descriptions

  * **`data/`**: Contains all non-code assets.
  * **`packaging/`**: Contains all Flatpak manifest files.
      * **`io.github.tobagin.projectname.yml`**: The **production** manifest.
      * **`io.github.tobagin.projectname-local.yml`**: The **development** manifest.
  * **`po/`**: For internationalization and localization (i18n).
  * **`src/`**: All Python source code.
      * **`projectname.in`**: A template for the main executable script.
  * **`build.sh`**: A convenience script for building the Flatpak locally.
  * **`meson.build`**: The main build configuration file.

-----

## 4\. Naming Conventions

  * **Application ID**: `io.github.tobagin.projectname`.
  * **Python Code**: **PEP 8** (`snake_case` for functions/variables, `PascalCase` for classes).
  * **GTK Classes**: `PascalCase` (e.g., `MainWindow`).
  * **UI Files (`.blp`)**: `snake_case` (e.g., `main_window.blp`).
  * **UI Widget IDs**: `kebab-case` (e.g., `main-action-button`).
  * **Meson Variables**: `snake_case`.

-----

## 5\. Architecture Patterns

### GResource for Assets

All assets (`.ui` files compiled from Blueprint, icons, etc.) will be compiled into a binary `gresource` file. This is handled by Meson and specified in `projectname.gresource.xml`.

### GSettings for Configuration

Application settings will be managed using `GSettings`. A `gschema.xml` file will define the keys, types, and default values.

### Composite Templates with Blueprint

We will use composite templates (`@Gtk.Template`) to cleanly link Python classes with their corresponding UI definitions.

-----

## 6\. Flatpak & Flathub Distribution 📦

The application is designed for Flatpak distribution. We maintain two manifests for different build scenarios.

### Flatpak Modules

Our manifests will define several modules to build the application and its dependencies.

  * **`blueprint-compiler`**: Fetches and builds the Blueprint compiler.
    ```yaml
    - name: blueprint-compiler
      buildsystem: meson
      cleanup: "*"
      sources:
        - type: git
          url: https://gitlab.gnome.org/jwestman/blueprint-compiler.git
          tag: v0.18.0
          commit: 07c9c9df9cd1b6b4454ecba21ee58211e9144a4b
    ```
  * **`python3-packages`**: Vendors all Python dependencies using pre-built wheels with verified checksums.
    ```yaml
    - name: python3-packages
      buildsystem: simple
      build-commands:
        - pip3 install --verbose --exists-action=i --no-index --find-links="file://${PWD}"
          --prefix=${FLATPAK_DEST} pydantic_core pydantic annotated_types typing_extensions typing_inspection hatchling python_dotenv pathspec pluggy trove_classifiers --no-build-isolation
      sources:
        # ... full list of sources with SHA256 checksums
    ```

### Production Manifest (`packaging/io.github.tobagin.projectname.yml`)

This manifest is for creating official, reproducible builds for Flathub.

  * **Source**: Pulls the application source code from a specific **git tag and commit**.
  * **Purpose**: Used for CI/CD pipelines and for submitting to Flathub.

### Local Development Manifest (`packaging/io.github.tobagin.projectname-local.yml`)

This manifest is for day-to-day development and testing.

  * **Source**: Pulls the application source code directly from the **local directory** (`type: dir`).
  * **Purpose**: Rapid iteration during development.

-----

## 7\. Common Flatpak Manifest Properties ⚙️

Both manifests share these core properties to ensure a consistent environment.

### Core Properties

  * **`app-id`**: `io.github.tobagin.projectname`
  * **`runtime`**: `org.gnome.Platform`
  * **`runtime-version`**: `48`
  * **`sdk`**: `org.gnome.Sdk`
  * **`command`**: `projectname`

### Finish Arguments

  * `--share=ipc`
  * `--socket=fallback-x11`
  * `--socket=wayland`
  * `--device=dri`
  * `--share=network`

### Build Cleanup

Unnecessary development files (`/include`, `*.a`, etc.) are removed to reduce the final Flatpak size.

-----

## 8\. Local Build Script (`build.sh`) 🛠️

To simplify the development workflow, a `build.sh` script is included in the project root. This script automates the process of running `flatpak-builder` with the correct manifest and options.

### Functionality

The script intelligently selects the manifest to use:

  * **Default**: By default, it uses the production manifest (`packaging/io.github.tobagin.projectname.yml`).
  * **Dev Mode**: If the `--dev` flag is provided, it switches to the local manifest (`packaging/io.github.tobagin.projectname-local.yml`) to build from the current source tree.

### Usage

The script accepts several command-line arguments to control the build process.

| Flag            | Description                                   |
| --------------- | --------------------------------------------- |
| `--dev`         | Build from local sources (development mode).  |
| `--install`     | Install the application after a successful build. |
| `--force-clean` | Force a clean build, removing the old build directory. |

**Example Commands:**

  * **Build for development and install:**
    ```bash
    ./build.sh --dev --install
    ```
  * **Build a clean production version without installing:**
    ```bash
    ./build.sh --force-clean
    ```
  * **Run the installed application:**
    ```bash
    flatpak run io.github.tobagin.projectname
    ```
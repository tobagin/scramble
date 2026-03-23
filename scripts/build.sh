#!/bin/bash

# Scramble build script
# Usage: ./scripts/build.sh [--dev]

set -e

# Change to project root directory (script is in scripts/)
cd "$(dirname "$0")/.."

# Default to production build
BUILD_TYPE="prod"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            BUILD_TYPE="dev"
            shift
            ;;
        --help)
            echo "Usage: $0 [--dev]"
            echo "  --dev      Build development version (uses Devel manifest)"
            echo "Default: Build production version"
            echo ""
            echo "The Flatpak will always be installed after building."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set manifest based on build type
if [ "$BUILD_TYPE" = "dev" ]; then
    MANIFEST="packaging/io.github.tobagin.scramble.Devel.yml"
    APP_ID="io.github.tobagin.scramble.Devel"
    echo "Building development version..."
else
    MANIFEST="packaging/io.github.tobagin.scramble.yml"
    APP_ID="io.github.tobagin.scramble"
    echo "Building production version..."
fi

# Build directory (always 'build')
BUILD_DIR="build"

echo "Using manifest: $MANIFEST"
echo "Build directory: $BUILD_DIR"

# Shared local Flatpak repo (reused across all local apps)
REPO_DIR="$HOME/repo"
REMOTE_NAME="local"

echo "Running flatpak-builder..."
flatpak-builder --force-clean --install-deps-from=flathub --repo="$REPO_DIR" "$BUILD_DIR" "$MANIFEST"

echo "Installing from local repo..."
flatpak remote-add --user --no-gpg-verify --if-not-exists "$REMOTE_NAME" "$REPO_DIR"
# Uninstall any existing installation (may reference a stale remote)
flatpak uninstall --user -y "$APP_ID" 2>/dev/null || true
flatpak install --user -y "$REMOTE_NAME" "$APP_ID"

echo "Build and installation complete!"
echo "Run with: flatpak run $APP_ID"
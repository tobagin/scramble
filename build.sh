#!/bin/bash

# Scramble build script
# This script builds the Scramble application using Flatpak

set -e

# Configuration
APP_ID="io.github.tobagin.scramble"
BUILD_DIR="_build"
MANIFEST_LOCAL="packaging/${APP_ID}-local.yml"
MANIFEST_PROD="packaging/${APP_ID}.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Scramble Build Script

Usage: $0 [OPTIONS]

Options:
    --dev           Build for development (uses local source)
    --prod          Build for production (uses git source)
    --install       Install the application after building
    --run           Run the application after building/installing
    --clean         Clean build directory before building
    --force-clean   Force clean all Flatpak artifacts
    --help          Show this help message

Examples:
    $0 --dev --install --run
    $0 --prod --clean
    $0 --force-clean
EOF
}

# Parse command line arguments
DEV_BUILD=false
PROD_BUILD=false
INSTALL=false
RUN=false
CLEAN=false
FORCE_CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            DEV_BUILD=true
            shift
            ;;
        --prod)
            PROD_BUILD=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --run)
            RUN=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --force-clean)
            FORCE_CLEAN=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default to development build if no build type specified
if [ "$DEV_BUILD" = false ] && [ "$PROD_BUILD" = false ]; then
    DEV_BUILD=true
fi

# Choose manifest
if [ "$DEV_BUILD" = true ]; then
    MANIFEST="$MANIFEST_LOCAL"
    print_info "Using development manifest: $MANIFEST"
else
    MANIFEST="$MANIFEST_PROD"
    print_info "Using production manifest: $MANIFEST"
fi

# Force clean
if [ "$FORCE_CLEAN" = true ]; then
    print_info "Force cleaning Flatpak artifacts..."
    flatpak uninstall --user $APP_ID -y || true
    flatpak remove --user --unused -y || true
    rm -rf "$BUILD_DIR"
    print_info "Force clean completed"
    exit 0
fi

# Clean build directory
if [ "$CLEAN" = true ]; then
    print_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Check if manifest exists
if [ ! -f "$MANIFEST" ]; then
    print_error "Manifest not found: $MANIFEST"
    exit 1
fi

# Build the application
print_info "Building Scramble..."
if [ "$DEV_BUILD" = true ]; then
    print_info "Development build from local source"
else
    print_info "Production build from git source"
fi

flatpak-builder --user --install-deps-from=flathub --ccache --force-clean "$BUILD_DIR" "$MANIFEST"

# Install if requested
if [ "$INSTALL" = true ]; then
    print_info "Installing Scramble..."
    flatpak-builder --user --install --force-clean "$BUILD_DIR" "$MANIFEST"
fi

# Run if requested
if [ "$RUN" = true ]; then
    print_info "Running Scramble..."
    flatpak run $APP_ID
fi

print_info "Build completed successfully!"
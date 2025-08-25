#!/bin/bash

# Local Build Script for xType
# This script builds the app locally for testing

set -e

PRODUCT_NAME="xType"
SCHEME_NAME="xType"
CONFIGURATION="Debug"  # Use Debug for local builds
BUILD_DIR="build"

echo "🔨 Building $PRODUCT_NAME locally..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build for current architecture
echo "🏗️  Building for current architecture..."
xcodebuild build \
    -scheme "$SCHEME_NAME" \
    -configuration $CONFIGURATION \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    SYMROOT="$BUILD_DIR/Build" \
    OBJROOT="$BUILD_DIR/Build/Intermediates"

# Find the built app
BUILT_APP=$(find "$BUILD_DIR" -name "$PRODUCT_NAME.app" -type d | head -1)

if [ -z "$BUILT_APP" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📍 Built app location: $BUILT_APP"

# Test the app
echo "🧪 Testing the built app..."
if [ -x "$BUILT_APP/Contents/MacOS/$PRODUCT_NAME" ]; then
    echo "✅ App executable is valid"
    
    # Show app info
    echo "📋 App Information:"
    echo "   Version: $(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$BUILT_APP/Contents/Info.plist")"
    echo "   Bundle ID: $(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$BUILT_APP/Contents/Info.plist")"
    echo "   Min OS: $(/usr/libexec/PlistBuddy -c "Print LSMinimumSystemVersion" "$BUILT_APP/Contents/Info.plist")"
    
    # Check architectures
    echo "   Architectures: $(lipo -info "$BUILT_APP/Contents/MacOS/$PRODUCT_NAME" 2>/dev/null | cut -d: -f3 || echo "Unknown")"
else
    echo "❌ Error: App executable not found or not executable"
    exit 1
fi

# Option to create DMG
read -p "📦 Do you want to create a DMG file? (y/N): " create_dmg
if [[ $create_dmg =~ ^[Yy]$ ]]; then
    echo "📦 Creating DMG..."
    
    # Copy app to export directory structure expected by DMG script
    mkdir -p "$BUILD_DIR/export"
    cp -R "$BUILT_APP" "$BUILD_DIR/export/"
    
    # Run DMG creation script
    chmod +x scripts/create_dmg.sh
    ./scripts/create_dmg.sh
    
    echo "✅ DMG created in build/ directory"
fi

# Option to open the app
read -p "🚀 Do you want to launch the app? (y/N): " launch_app
if [[ $launch_app =~ ^[Yy]$ ]]; then
    echo "🚀 Launching $PRODUCT_NAME..."
    open "$BUILT_APP"
fi

echo "🎉 Local build process completed!"

#!/bin/bash

# DMG Creation Script for xType
# This script creates a stylized DMG file for distribution

set -e  # Exit on any error

# Configuration
PRODUCT_NAME="xType"
DMG_NAME="xType"
VERSION="${GITHUB_REF_NAME:-$(date +%Y%m%d_%H%M%S)}"
DMG_FINAL_NAME="${DMG_NAME}-${VERSION}.dmg"

# Paths
BUILD_DIR="build"
EXPORT_DIR="$BUILD_DIR/export"
DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
DMG_BACKGROUND_DIR="$DMG_TEMP_DIR/.background"

# Check if Universal build
if [ "$UNIVERSAL_BUILD" = "true" ]; then
    APP_PATH="$BUILD_DIR/$PRODUCT_NAME-Universal.app"
    DMG_FINAL_NAME="${DMG_NAME}-Universal-${VERSION}.dmg"
else
    APP_PATH="$EXPORT_DIR/$PRODUCT_NAME.app"
fi

echo "🚀 Creating DMG for $PRODUCT_NAME"
echo "📁 App path: $APP_PATH"
echo "📦 DMG name: $DMG_FINAL_NAME"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    exit 1
fi

# Create temporary DMG directory
echo "🗂️  Creating temporary DMG directory..."
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
mkdir -p "$DMG_BACKGROUND_DIR"

# Copy app to temp directory
echo "📋 Copying app to temporary directory..."
cp -R "$APP_PATH" "$DMG_TEMP_DIR/"

# Create Applications symlink
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Copy custom background image
echo "🎨 Setting up custom DMG background..."
BACKGROUND_SOURCE="scripts/background.png"

if [ -f "$BACKGROUND_SOURCE" ]; then
    echo "✅ Using custom background: $BACKGROUND_SOURCE"
    cp "$BACKGROUND_SOURCE" "$DMG_BACKGROUND_DIR/background.png"
    
    # Verify the copied background image
    if [ -f "$DMG_BACKGROUND_DIR/background.png" ]; then
        echo "📐 Background image dimensions: $(sips -g pixelWidth -g pixelHeight "$DMG_BACKGROUND_DIR/background.png" 2>/dev/null | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}' | paste -sd 'x' -)"
    else
        echo "⚠️  Failed to copy background image"
    fi
else
    echo "⚠️  Custom background not found at $BACKGROUND_SOURCE"
    echo "🎨 Creating fallback background..."
    # Create a simple fallback background if custom one is missing
    if command -v sips >/dev/null 2>&1; then
        sips -s format png --resampleHeightWidthMax 600 --padToHeightWidth 400 600 --padColor FFFFFF /System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns --out "$DMG_BACKGROUND_DIR/background.png" 2>/dev/null || echo "⚠️  Could not create fallback background"
    fi
fi

# Create README file
echo "📄 Creating README file..."
cat > "$DMG_TEMP_DIR/README.txt" << EOF
xType - File Type Manager

Thanks for downloading xType!

Installation:
1. Drag xType.app to your Applications folder
2. Launch xType from Applications
3. Grant necessary permissions when prompted

Features:
- Manage file type associations
- Batch set default applications  
- Modern and intuitive interface
- Supports multiple languages (English/中文)

For more information, visit: https://github.com/helson-lin/xType

Enjoy using xType! 🎉
EOF

# Calculate DMG size (app size + some padding)
echo "📏 Calculating DMG size..."
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))  # Add 50MB padding

# Create temporary DMG
echo "💾 Creating temporary DMG..."
TEMP_DMG="$BUILD_DIR/temp.dmg"
hdiutil create -srcfolder "$DMG_TEMP_DIR" -volname "$DMG_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$TEMP_DMG"

# Mount the temporary DMG
echo "🔌 Mounting temporary DMG..."
MOUNT_DIR="/Volumes/$DMG_NAME"
hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen

# Wait for mount
sleep 2

# Set DMG window properties using AppleScript
echo "🎨 Setting DMG window properties..."
osascript << EOF
tell application "Finder"
    tell disk "$DMG_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- Set window size to match background image (660x400) plus some padding
        set the bounds of container window to {100, 100, 760, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        -- Apply custom background image
        set background picture of viewOptions to file ".background:background.png"
        -- Position items to work well with the custom background
        set position of item "$PRODUCT_NAME.app" of container window to {165, 180}
        set position of item "Applications" of container window to {495, 180}
        set position of item "README.txt" of container window to {330, 320}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount the temporary DMG
echo "📤 Unmounting temporary DMG..."
hdiutil detach "$MOUNT_DIR"

# Convert to final compressed DMG
echo "🗜️  Converting to final compressed DMG..."
rm -f "$BUILD_DIR/$DMG_FINAL_NAME"
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$BUILD_DIR/$DMG_FINAL_NAME"

# Clean up
echo "🧹 Cleaning up temporary files..."
rm -f "$TEMP_DMG"
rm -rf "$DMG_TEMP_DIR"

# Verify final DMG
if [ -f "$BUILD_DIR/$DMG_FINAL_NAME" ]; then
    DMG_SIZE_FINAL=$(du -h "$BUILD_DIR/$DMG_FINAL_NAME" | cut -f1)
    echo "✅ DMG created successfully!"
    echo "📦 Final DMG: $BUILD_DIR/$DMG_FINAL_NAME"
    echo "📏 Size: $DMG_SIZE_FINAL"
    
    # Show DMG info
    echo "ℹ️  DMG Info:"
    hdiutil imageinfo "$BUILD_DIR/$DMG_FINAL_NAME" | grep -E "(Format|Size|Compressed|Checksum)"
else
    echo "❌ Error: Failed to create DMG"
    exit 1
fi

echo "🎉 DMG creation completed!"

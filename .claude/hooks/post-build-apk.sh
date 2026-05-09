#!/bin/bash
# Post-build APK hook
# Auto-copy APK dan notification setelah build selesai

set -e

PROJECT_DIR="/Users/macbook/testclaude"
APK_PATH="$1"
BUILD_TYPE="${2:-release}"

# Default APK path jika tidak disupply
if [ -z "$APK_PATH" ]; then
    if [ "$BUILD_TYPE" = "debug" ]; then
        APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
    else
        APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    fi
fi

echo "📦 Post-build APK Hook"
echo "   APK: $APK_PATH"
echo "   Build Type: $BUILD_TYPE"
echo ""

# Check if APK exists
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found: $APK_PATH"
    exit 1
fi

# Get APK info
APK_SIZE=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH" 2>/dev/null)
APK_SIZE_KB=$((APK_SIZE / 1024))
APK_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $APK_SIZE/1024/1024}")

echo "📊 APK Info:"
echo "   Size: $APK_SIZE_MB MB ($APK_SIZE_KB KB)"
echo ""

# Copy to release folder
RELEASE_DIR="$PROJECT_DIR/releases"
mkdir -p "$RELEASE_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BASENAME=$(basename "$APK_PATH")
NEW_NAME="${BASENAME%.*}_${TIMESTAMP}.${BASENAME##*.}"
TARGET_PATH="$RELEASE_DIR/$NEW_NAME"

cp "$APK_PATH" "$TARGET_PATH"
echo "📋 Copied to: $TARGET_PATH"

# Also copy as latest
LATEST_PATH="$RELEASE_DIR/latest.apk"
cp "$APK_PATH" "$LATEST_PATH"
echo "📋 Also copied as: $LATEST_PATH"

# List release folder
echo ""
echo "📁 Release folder contents:"
ls -lh "$RELEASE_DIR"

# Calculate and show diff from previous build
if [ -f "$RELEASE_DIR/previous_build.txt" ]; then
    PREVIOUS_APK=$(cat "$RELEASE_DIR/previous_build.txt")
    if [ -f "$PREVIOUS_APK" ]; then
        PREV_SIZE=$(stat -f%z "$PREVIOUS_APK" 2>/dev/null || stat -c%s "$PREVIOUS_APK" 2>/dev/null)
        DIFF=$((APK_SIZE - PREV_SIZE))
        DIFF_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($DIFF/$PREV_SIZE)*100}")
        if [ $DIFF -gt 0 ]; then
            echo ""
            echo "📈 Size change: +$((DIFF / 1024)) KB (+${DIFF_PERCENT}%)"
        else
            echo ""
            echo "📉 Size change: $((DIFF / 1024)) KB (${DIFF_PERCENT}%)"
        fi
    fi
fi

# Save current APK path for next comparison
echo "$APK_PATH" > "$RELEASE_DIR/previous_build.txt"

# Notify success (macOS)
if [ "$(uname)" = "Darwin" ]; then
    osascript -e 'display notification "APK Build Complete!" with title "Flutter Build" sound name "Glass"' 2>/dev/null || true
fi

echo ""
echo "✅✅✅ APK Post-Build Hook Complete ✅✅✅"

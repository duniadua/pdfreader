#!/bin/bash
# Build and Install APK Script
# Builds a debug APK and installs it to a connected Android device

set -e

PROJECT_DIR="/Users/macbook/testclaude"
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
PACKAGE_NAME="com.pdfreader.pdf_reader_app"

echo "🔨 Building and Installing Debug APK"
echo "======================================"

# Step 1: Clean previous build (optional but recommended)
echo ""
echo "1️⃣  Cleaning previous build..."
cd "$PROJECT_DIR" || exit 1
flutter clean

# Step 2: Build debug APK
echo ""
echo "2️⃣  Building debug APK (arm64)..."
flutter build apk --debug --target-platform android-arm64

# Verify APK was created
if [ ! -f "$APK_PATH" ]; then
    echo "❌ ERROR: APK build failed. File not found at $APK_PATH"
    exit 1
fi

# Get APK size
APK_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
echo "✅ APK built successfully: $APK_PATH ($APK_SIZE)"

# Step 3: Check connected devices
echo ""
echo "3️⃣  Checking connected devices..."
DEVICES=$(adb devices | grep -w "device" | wc -l | tr -d ' ')

if [ "$DEVICES" -eq 0 ]; then
    echo "❌ ERROR: No Android device connected!"
    echo ""
    echo "Please connect a device via USB or start an emulator:"
    echo "  - USB: Enable Developer Mode and USB Debugging on your device"
    echo "  - Emulator: Run 'flutter emulators --launch <emulator_id>'"
    exit 1
fi

echo "✅ Found $DEVICES connected device(s):"
adb devices | grep -w "device" | awk '{print "   - " $1}'

# Step 4: Install APK to device
echo ""
echo "4️⃣  Installing APK to device..."
adb install -r "$APK_PATH"

# Step 5: Launch the app
echo ""
echo "5️⃣  Launching app..."
adb shell am start -n "$PACKAGE_NAME/.MainActivity"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build and Install Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 App is now running on your device!"
echo ""
echo "To view logs:"
echo "  adb logcat | grep pdf_reader"

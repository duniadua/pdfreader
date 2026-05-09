#!/bin/bash
# Pre-device-connect hook
# Auto-detect dan configure device sebelum run/build

PROJECT_DIR="/Users/macbook/testclaude"
cd "$PROJECT_DIR"

echo "📱 Device Detection Hook"
echo ""

# Detect platform
PLATFORM=$(flutter devices --machine 2>/dev/null | grep -oP '"platform":\s*"\K[^"]+' | head -1 || echo "unknown")

# Check for connected devices
DEVICES=$(flutter devices 2>/dev/null | grep -E "^[0-9]+" | wc -l | tr -d ' ')

echo "🔍 Platform: $PLATFORM"
echo "🔍 Connected devices: $DEVICES"
echo ""

# If no devices, suggest starting emulator
if [ "$DEVICES" -eq 0 ]; then
    echo "⚠️  No devices found!"
    echo ""
    echo "Options:"
    echo "   1. Open iOS Simulator: open -a Simulator"
    echo "   2. Open Android Emulator: emulator -avd <name>"
    echo "   3. Connect physical device via USB"
    echo ""
    echo "After starting device, run build again."
    exit 1
fi

# Show device info
echo "📋 Available devices:"
flutter devices 2>/dev/null
echo ""

# Auto-select best device
if [ "$PLATFORM" = "android" ]; then
    # Check for physical device first (faster than emulator)
    PHYSICAL_DEVICE=$(flutter devices 2>/dev/null | grep -i "android" | grep -v "emulator" | head -1)
    if [ -n "$PHYSICAL_DEVICE" ]; then
        echo "📱 Selected: Physical Android device"
    else
        EMULATOR=$(flutter devices 2>/dev/null | grep -i "emulator" | head -1)
        if [ -n "$EMULATOR" ]; then
            echo "📱 Selected: Android Emulator"
        fi
    fi
elif [ "$PLATFORM" = "ios" ]; then
    PHYSICAL_DEVICE=$(flutter devices 2>/dev/null | grep -i "iphone" | head -1)
    if [ -n "$PHYSICAL_DEVICE" ]; then
        echo "📱 Selected: iOS device"
    else
        echo "📱 Using iOS Simulator"
    fi
fi

echo ""
exit 0

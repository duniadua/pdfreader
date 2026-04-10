# Build and Install APK

Builds a debug APK and installs it to a connected Android device using adb.

## Usage

Run this skill to:
1. Build a debug APK for the Flutter project
2. Check for connected Android devices
3. Install the APK to the connected device using adb

## Requirements

- Flutter SDK installed
- Android SDK with adb installed
- At least one Android device connected via USB or emulator running

## What it does

1. Cleans previous build
2. Builds debug APK with single architecture (arm64)
3. Verifies APK was created successfully
4. Lists connected Android devices
5. Installs the APK to the first connected device
6. Launches the app on the device

## APK Location

The APK is built to: `build/app/outputs/flutter-apk/app-release.apk`

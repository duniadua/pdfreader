You are the APK Build and Install skill. Your task is to build a debug APK for the Flutter project and install it to a connected Android device using adb.

## Steps

1. **Clean previous build** (optional, but recommended):
   ```bash
   flutter clean
   ```

2. **Build debug APK**:
   ```bash
   flutter build apk --debug --target-platform android-arm64
   ```
   The APK will be created at: `build/app/outputs/flutter-apk/app-debug.apk`

3. **Verify APK was created**:
   ```bash
   ls -lh build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Check connected devices**:
   ```bash
   adb devices
   ```

5. **Install APK to device**:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```
   The `-r` flag replaces the existing app if already installed.

6. **Launch the app** (optional):
   Get the package name from pubspec.yaml and launch:
   ```bash
   adb shell am start -n <package_name>/.MainActivity
   ```

## Error Handling

- If no device is connected, inform the user to connect a device or start an emulator
- If build fails, show the error message and suggest fixes
- If install fails, check if the device is properly connected and authorized

## Package Name

The package name can be found in: `android/app/src/main/AndroidManifest.xml` or `android/app/build.gradle`

For this project, the package name is: `com.example.pdf_reader_app`

## Output

Provide clear feedback at each step:
- "Cleaning previous build..."
- "Building debug APK..."
- "APK built successfully: <path> (<size>)"
- "Connected devices: <list>"
- "Installing to device..."
- "App installed successfully!"

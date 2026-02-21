# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A local-only PDF reader mobile application built with Flutter. No backend API required.

## Project Structure

```
├── lib/
│   ├── main.dart                 # App entry point, Hive initialization
│   ├── core/
│   │   ├── constants/            # App-wide constants (colors, storage keys)
│   │   ├── data/
│   │   │   └── models/           # Hive models (PdfDocument, AppSettings)
│   │   ├── router/               # GoRouter configuration
│   │   ├── theme/                # App theme (light/dark, design tokens)
│   │   └── utils/                # Utility functions
│   ├── features/
│   │   ├── library/              # PDF library screen with bottom nav
│   │   ├── reader/               # PDF viewer with Syncfusion
│   │   ├── settings/             # App settings/preferences
│   │   └── scanner/              # Document scanner (future)
│   └── shared/                   # Shared widgets and providers
├── stitch/                       # HTML prototypes from Stitch (design reference)
├── assets/                       # Images, icons, fonts
├── android/                      # Android platform code
└── ios/                          # iOS platform code
```

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (requires connected device or emulator)
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Generate Hive adapters (after modifying models)
flutter pub run build_runner build

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Fast APK Build

**APK Output Location:** `build/app/outputs/flutter-apk/`

```bash
# Fastest - single architecture (arm64 for modern phones)
flutter build apk --release --target-platform android-arm64

# Split APK - smaller size, faster build
flutter build apk --release --split-per-abi

# Debug build - fastest for testing
flutter build apk --debug --target-platform android-arm64
```

**Tip:** Gradle parallel build enabled in `android/gradle.properties` for faster builds.

## Tech Stack

| Category | Package |
|----------|---------|
| PDF Viewing | syncfusion_flutter_pdfviewer |
| State Management | flutter_riverpod + riverpod_generator |
| Navigation | go_router |
| Local Storage | hive_flutter |
| File Handling | file_picker, path_provider |
| Theme | flex_color_scheme, google_fonts |

## Design System

Based on Stitch prototypes - colors defined in `lib/core/constants/app_constants.dart`:

```dart
primary: "#135bec"
backgroundLight: "#f6f6f8"
backgroundDark: "#101622"
```

- Font: Inter (via Google Fonts)
- Icons: Material Icons
- Theme: Material 3 with FlexColorScheme

## Data Models

Hive is used for local data persistence. Models require code generation:

1. Add/modify model in `lib/core/data/models/`
2. Run `flutter pub run build_runner build`
3. Register adapter in `main.dart`

Key models:
- `PdfDocument` — Metadata for PDFs in library
- `ReadingProgress` — Track reading position
- `AppSettings` — User preferences

## Feature Structure

Each feature follows a clean architecture pattern:

```
features/{feature_name}/
├── data/        # Data sources, repositories
├── domain/      # Business logic, use cases
└── presentation/# UI screens, widgets, state
```

## Stitch Design Reference

The `stitch/` directory contains HTML prototypes used as design reference:

| Screen | Prototype | Implementation |
|--------|-----------|----------------|
| Library | `my_library/` | `features/library/` |
| Reader | `pdf_reader_view/` | `features/reader/` |
| Settings | `settings_and_customization/` | `features/settings/` |
| File Import | `file_import_and_cloud/` | Not implemented (local-only) |

Open `stitch/*/code.html` in a browser to view the design prototypes.

---

## Dart/Flutter Code Style Guidelines

### General Rules

1. **Follow Effective Dart Guidelines**
   - Use `flutter analyze` and `dart fix --apply` before committing
   - All code must pass analysis with zero warnings
   - Run `dart format .` for consistent formatting (2 spaces indentation)

2. **File Organization**
   ```dart
   // 1. dart: imports first
   // 2. package: imports second
   // 3. relative imports third (with ../ prefix)
   // Each section separated by blank line

   import 'dart:async';
   import 'dart:io';

   import 'package:flutter/material.dart';
   import 'package:riverpod_annotation/riverpod_annotation.dart';

   import '../../shared/widgets/app_button.dart';
   import 'my_state.dart';
   ```

3. **Naming Conventions**
   - **Classes/Enums/Typedefs**: `UpperCamelCase` (e.g., `PdfDocument`, `LibraryState`)
   - **Variables/Functions/Parameters**: `lowerCamelCase` (e.g., `pdfId`, `getDocuments()`)
   - **Constants**: `lowerCamelCase` (e.g., `primaryColor`, `maxRetries`)
   - **Private members**: Prefix with `_` (e.g., `_repository`, `_loadData()`)
   - **File names**: `lowercase_with_underscores.dart` (e.g., `library_screen.dart`)

4. **Widget Structure**
   ```dart
   class MyWidget extends ConsumerWidget {
     const MyWidget({
       super.key,
     });

     @override
     Widget build(BuildContext context, WidgetRef ref) {
     }
   }

   // OR

   class MyWidget extends ConsumerStatefulWidget {
     const MyWidget({super.key});

     @override
     ConsumerState<MyWidget> createState() => _MyWidgetState();
   }

   class _MyWidgetState extends ConsumerState<MyWidget> {
     @override
     Widget build(BuildContext context) {
     }
   }
   ```

5. **Const Constructors**
   - Always use `const` for immutable widgets
   - ```dart
     const SizedBox(height: 16)
     const Text('Hello')
     ```

6. **Riverpod Providers**
   ```dart
   // State notifier with code generation
   @riverpod
   class MyNotifier extends _$MyNotifier {
     @override
     MyState build() => MyState.initial();
   }

   // Always use part directives
   part 'my_notifier.g.dart';
   part 'my_notifier.freezed.dart';
   ```

7. **Freezed Models**
   ```dart
   @freezed
   class MyModel with _$MyModel {
     const factory MyModel({
       required String id,
       String? name,
     }) = _MyModel;

     factory MyModel.fromJson(Map<String, Object?> json) =>
         _$MyModelFromJson(json);
   }
   ```

8. **Color & Theming**
   - Use theme colors instead of hardcoding: `Theme.of(context).colorScheme.primary`
   - For custom colors from design: use values from `app_constants.dart`
   - ```dart
     // Preferred
     Color(0xFF135BEC)
     // Not withOpacity (deprecated in newer Dart)
     // Use withValues() instead:
     color.withValues(alpha: 0.5)
     ```

9. **Avoid Using**
   - `print()` - use `AppLogger` from `core/utils/logger.dart` instead
   - `as` without null check - prefer type checking or null-aware operators
   - `late` unless absolutely necessary - prefer nullable types with initialization
   - `!` (bang operator) - use proper null checks instead

10. **Widget Composition**
    ```dart
    // Break large widgets into smaller pieces
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: ListView(
          children: [
            _buildHeader(),
            _buildContent(),
            _buildFooter(),
          ],
        ),
      );
    }

    Widget _buildHeader() => const HeaderWidget();
    Widget _buildContent() => const ContentWidget();
    Widget _buildFooter() => const FooterWidget();
    ```

11. **Async/Await**
    ```dart
    // Use proper error handling
    Future<void> loadData() async {
      try {
        state = state.copyWith(isLoading: true);
        final data = await _repository.fetch();
        state = state.copyWith(data: data, isLoading: false);
      } catch (e, st) {
        AppLogger.e('Failed to load', e, st);
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
    ```

12. **String Interpolation**
    ```dart
    // Use multi-line strings for long text
    final message = '''
      This is a long message
      that spans multiple lines.
    ''';

    // Or use + for concatenation with heredoc for longer text
    ```

13. **Extension Methods**
    ```dart
    // For nullable types, avoid ! operator
    extension NullableExtension on String? {
      String orDefault() => this ?? 'default';
    }
    ```

14. **Import Ordering for Flutter**
    ```dart
    // Order: dart -> flutter -> riverpod -> third-party -> local
    import 'dart:async';
    import 'dart:io';

    import 'package:flutter/material.dart';
    import 'package:riverpod_annotation/riverpod_annotation.dart';

    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:go_router/go_router.dart';

    import '../../../core/constants/app_constants.dart';
    import '../../../shared/widgets/app_card.dart';
    import 'my_provider.dart';
    ```

15. **Lint Rules**
    - Follow rules in `analysis_options.yaml`
    - Fix all warnings before committing
    - Run `flutter analyze` locally

### Before Committing

```bash
# Format code
dart format .

# Run analysis
flutter analyze

# Fix auto-fixable issues
dart fix --apply

# Run tests
flutter test
```

### UI Development Rules

1. **Always match Stitch design prototypes** - Reference `stitch/` directory
2. **Use Inter font** - via `GoogleFonts.inter()`
3. **Follow Material 3** - use Material 3 components
4. **Proper spacing** - use consistent padding/margin values (4, 8, 12, 16, 24, 32)
5. **Dark mode support** - always test in both light and dark themes

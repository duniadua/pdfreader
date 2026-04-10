# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A PDF reader mobile application built with Flutter. Core functionality is local-only, with optional cloud features:
- **Local**: PDF library, viewing, bookmarks, settings (Hive storage)
- **Optional Cloud**: Google Drive integration, AI chat (Firebase Genkit)

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
│   │   ├── auth/                 # Authentication (Google Sign-In)
│   │   ├── drive/                # Google Drive integration
│   │   ├── library/              # PDF library screen with bottom nav
│   │   ├── reader/               # PDF viewer with Syncfusion (includes AI chat)
│   │   ├── scanner/              # Document scanner
│   │   └── settings/             # App settings/preferences
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

## App Information

| Property | Value |
|----------|-------|
| Package Name | `com.pdfreader.pdf_reader_app` |
| Flutter Version | 3.38.5 (stable) |
| APK Output | `build/app/outputs/flutter-apk/` |

### ADB Commands
```bash
# Install APK to connected device
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Launch the app
adb shell am start -n com.pdfreader.pdf_reader_app/.MainActivity

# View logs
adb logcat | grep pdf_reader
```

## Feature Overview

| Feature | Description |
|---------|-------------|
| **Auth** | Google Sign-In integration for authentication. Required for Drive integration. |
| **Drive** | Google Drive integration for accessing PDFs from cloud storage. Follows Clean Architecture with domain/data/presentation layers. |
| **Reader** | PDF viewer with Syncfusion. Includes AI chat panel for PDF Q&A using Firebase Genkit. |
| **Library** | PDF library with bottom navigation, search, and filtering. |
| **Settings** | App preferences including theme (light/dark), reading settings. |

## Automation Tools

### Skills

The `.claude/skills/` directory contains reusable skills:

| Skill | Purpose |
|-------|---------|
| `/pre-commit` | Run all validation checks before committing |
| `/code-review` | Review code for maintainability and security |
| `/test-generator` | Generate tests for new features |
| `/model-generator` | Generate Hive models with Freezed |
| `/scaffold-feature` | Generate feature scaffold structure |
| `/build-install-apk` | Build and install APK to connected device |

### Hooks

Pre/post hooks automate quality checks:

| Hook | Purpose |
|------|---------|
| `pre-bash-safety.sh` | Warn before dangerous commands (rm -rf, git reset --hard) |
| `pre-write-check.sh` | Validate file structure for new files in lib/features/ |
| `pre-read-validate.sh` | Warn about large files or sensitive data |
| `pre-test-validate.sh` | Check for missing generated files (@freezed, @riverpod) |
| `post-edit-format.sh` | Auto-format code after edits |
| `post-edit-build-runner.sh` | Detect model changes requiring build_runner |
| `post-bash-dependency.sh` | Track dependency changes to dependency-log.txt |

### Scripts

```bash
# Build and install APK to connected device
.claude/scripts/build-install-apk.sh

# Or use the skill:
/build-install-apk
```

## Pre-Commit Validation

Use the `/pre-commit` skill to run all validation checks before committing:

```bash
/pre-commit              # Run all checks
/pre-commit --fix        # Run + auto-fix issues
/pre-commit --filter=format,analyze  # Run specific checks
```

**What it checks:**
- Code formatting (`dart format`)
- Analyzer issues (`flutter analyze`)
- Test execution (`flutter test`)
- Test coverage (target: 80%)
- TODO/FIXME detection
- Build runner status

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

**Quick Build & Install:**
Use the `/build-install-apk` skill to build and install to a connected device in one command:
```bash
/build-install-apk
```

## Testing Workflow

**IMPORTANT: Always run tests before building APK after code changes.**

### Recommended Workflow

```
1. Make code changes
2. Run unit tests
3. Fix any failing tests
4. Run code analysis
5. Fix any warnings/errors
6. Build APK
```

### Test Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/features/reader/pdf_reader_models_test.dart

# Run tests for specific feature
flutter test test/unit/features/reader/

# Run tests with verbose output
flutter test --verbose

# Run integration tests (requires device/emulator)
flutter test integration_test/
```

### Test Structure

```
test/
├── unit/                      # Unit tests
│   ├── core/
│   │   └── data/models/       # Model tests (PdfDocument, etc.)
│   └── features/
│       ├── library/           # Library feature tests
│       ├── reader/            # Reader feature tests
│       └── settings/          # Settings feature tests
├── widget/                    # Widget tests
└── integration/               # Integration tests (requires device)
```

### Running Tests Before Building

```bash
# Complete pre-build test sequence
flutter test                    # Run all unit tests
flutter analyze                 # Check for code issues
dart format .                   # Format code
flutter build apk --release    # Build APK (only if tests pass!)
```

### Creating New Tests

When adding new features, create corresponding test files:

```bash
# Create test for a new feature
# 1. Create test file: test/unit/features/{feature}/{feature}_test.dart
# 2. Run the test
flutter test test/unit/features/{feature}/{feature}_test.dart
```

### Test Example

```dart
// test/unit/features/reader/pdf_reader_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';

void main() {
  group('PdfDocument', () {
    test('should have correct properties', () {
      final pdf = PdfDocument(
        id: 'test-1',
        title: 'Test.pdf',
        filePath: '/path/Test.pdf',
      );

      expect(pdf.id, 'test-1');
      expect(pdf.title, 'Test.pdf');
    });
  });
}
```

### Common Test Options

| Command | Purpose |
|---------|---------|
| `flutter test` | Run all unit & widget tests |
| `flutter test --coverage` | Generate coverage report |
| `flutter test --update-goldens` | Update golden test files |
| `flutter test --reporter expanded` | Detailed test output |

### Interpreting Test Results

```
✅ All tests passed: OK to build APK
❌ Some tests failed: Fix failures before building
⚠️  Warnings: Review and fix if critical
```

### Pre-Build Checklist

Before building APK, verify:

- [ ] All unit tests pass (`flutter test`)
- [ ] Code analysis shows no issues (`flutter analyze`)
- [ ] Code is formatted (`dart format .`)
- [ ] New features have tests
- [ ] Changed features have updated tests
- [ ] Manual testing completed on device/emulator

### Quick Test Command

```bash
# One-liner to run tests before building
flutter test && flutter analyze && dart format . && echo "✅ Ready to build!"
```

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
| Reader | `pdf_reader_view/` | `features/reader/` (includes AI chat panel) |
| Settings | `settings_and_customization/` | `features/settings/` |
| File Import | `file_import_and_cloud/` | `features/drive/` (Google Drive integration) |

Open `stitch/*/code.html` in a browser to view the design prototypes.

## Debugging

When debugging state-related issues, always check for duplicate function calls, especially in constructor or builder methods (e.g., PdfChatNotifier.build() being called twice). This pattern appears frequently in Flutter/Riverpod applications where providers may be initialized multiple times due to widget rebuilds, hot reload, or incorrect provider scoping.

**Common symptoms**:
- State resets unexpectedly
- Data disappears on rebuild
- Initial state reappears after navigation

**Debugging steps**:
1. Search for all instances of `.build()` methods in notifiers/providers
2. Check component lifecycle timing (initState, dispose, mount/unmount)
3. Add logging at state mutation points to trace execution flow
4. Verify providers aren't being recreated on every rebuild

## Feature Development

For AI/ML feature integration (Firebase Genkit, PDF chat, etc.), always create a comprehensive implementation plan before writing code. Complex features require careful planning to avoid incomplete implementations and technical debt.

**Planning checklist**:
- Define clear success criteria and acceptance tests
- Identify all dependencies and their versions
- Map data flow and component hierarchy
- Plan error handling for edge cases
- Consider performance implications (e.g., PDF processing, API calls)

**Example plan structure**:
1. Overview and requirements
2. Technical architecture
3. File structure changes
4. Component hierarchy and data flow
5. Error handling and edge cases
6. Testing approach
7. Implementation phases

## Code Quality

Always verify Dart code with the analyzer before considering edits complete to catch analyzer errors early. This prevents the cycle of: implement → discover errors → fix → rediscover more errors.

**Verification workflow**:
1. Run `flutter analyze` after code changes
2. Fix all analyzer warnings and errors
3. Run `dart format .` for consistent formatting
4. Run `flutter test` to ensure tests still pass
5. Only then mark the task as complete

**A PostToolUse hook is configured** to automatically run `flutter analyze` after Edit operations, providing immediate feedback on code quality issues.

## Firebase & Cloud Functions Debugging

The app uses Firebase Genkit for the AI chat feature in the reader. For debugging Firebase-related issues (AI chat, Genkit functions, authentication), use the Firebase CLI directly in Claude sessions via the Bash tool.

**Common debugging commands**:
```bash
# Check Firebase project status
firebase projects:list

# View recent function logs
firebase functions:log --only <function_name>

# View all function logs (useful for state debugging)
firebase functions:log

# Check Firestore indexes
firebase firestore:indexes list

# View Firestore data (for debugging state persistence)
firebase firestore:get <collection>/<document_id>

# Export Firestore data (for state analysis)
firestore export <collection_name>
```

**Debugging AI chat state issues**:
1. Check function logs for errors: `firebase functions:log`
2. Verify Firestore documents exist: `firebase firestore:get chatSessions/<session_id>`
3. Check for rate limiting or quota issues
4. Review function execution time in Firebase Console

**Common patterns**:
- State reset → Check if Firestore documents are being overwritten
- Missing chat responses → Check function logs for Genkit API errors
- Authentication failures → Check Firebase Auth logs
- Performance issues → Review cold starts and function execution times

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

---

## Documentation Guidelines

### Where to Create Markdown Files

**IMPORTANT**: All new `.md` files must be created in the `docs/` folder, except for:
- `README.md` - Project overview (keep at root)
- `CLAUDE.md` - Claude Code instructions (keep at root)

### Examples

✅ **CORRECT** - Create documentation files in `docs/`:
```bash
docs/API_REFERENCE.md          # API documentation
docs/ARCHITECTURE.md           # System architecture
docs/DEPLOYMENT_GUIDE.md       # Deployment instructions
docs/TROUBLESHOOTING.md        # Troubleshooting guide
```

❌ **WRONG** - Don't create these at root level:
```bash
# Don't do this (except README.md and CLAUDE.md):
API_REFERENCE.md
ARCHITECTURE.md
FEATURE_X_DOCUMENTATION.md
```

### Why This Rule?

1. **Clean repository root** - Keeps root directory focused on code
2. **Organized documentation** - All docs in one searchable location
3. **Git ignore compatibility** - `docs/` folder is gitignored for local/working docs
4. **Exception for key files** - `README.md` and `CLAUDE.md` stay at root for visibility

### Moving Existing Docs

When you encounter `.md` files at root level (except `README.md` and `CLAUDE.md`), move them to `docs/`:

```bash
# Example: Move an existing doc to docs folder
mv EXISTING_FILE.md docs/
```

### Documentation File Types

These belong in `docs/`:
- API references
- Architecture diagrams
- Deployment guides
- Feature specifications
- Technical design docs
- Troubleshooting guides
- Meeting notes
- Migration plans

These stay at root:
- `README.md` - Project overview for GitHub
- `CLAUDE.md` - Instructions for Claude Code

# Dart/Flutter Code Style Guidelines

This file contains code style rules that MUST be followed when writing Dart/Flutter code in this repository.

---

## General Rules

1. **Follow Effective Dart Guidelines**
   - Run `flutter analyze` before committing - zero warnings allowed
   - Run `dart fix --apply` to fix auto-fixable issues
   - Run `dart format .` for consistent formatting (2 spaces indentation)

2. **File Organization**
   ```dart
   // Order: dart imports → flutter imports → package imports → relative imports
   // Each section separated by blank line

   import 'dart:async';
   import 'dart:io';

   import 'package:flutter/material.dart';
   import 'package:riverpod_annotation/riverpod_annotation.dart';

   import 'package:freezed_annotation/freezed_annotation.dart';
   import 'package:go_router/go_router.dart';

   import '../../../core/constants/app_constants.dart';
   import '../../../shared/widgets/app_button.dart';
   import 'my_state.dart';
   ```

3. **Naming Conventions**
   ```dart
   // Classes, Enums, Typedefs, Extensions: UpperCamelCase
   class PdfDocument {}
   enum FileType { pdf, epub }
   typedef JsonMap = Map<String, dynamic>;
   extension DateTimeExtensions on DateTime {}

   // Variables, Functions, Parameters: lowerCamelCase
   var pdfId;
   void getDocuments() {}
   void fetchData({int? timeout}) {}

   // Constants: lowerCamelCase
   const primaryColor = Color(0xFF135BEC);
   const maxRetries = 3;

   // Private members: prefix with _
   var _repository;
   void _loadData() {}

   // File names: lowercase_with_underscores.dart
   // library_screen.dart
   // pdf_document.dart
   // library_notifier.dart
   ```

---

## Widget Structure

```dart
// Prefer ConsumerWidget for stateless widgets
class MyWidget extends ConsumerWidget {
  const MyWidget({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const _Content(),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Placeholder();
  }
}

// Use ConsumerStatefulWidget only when state is needed
class MyStatefulWidget extends ConsumerStatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  ConsumerState<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends ConsumerState<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
```

---

## Const Constructors

```dart
// ALWAYS use const for immutable widgets
const SizedBox(height: 16)
const Text('Hello')
const Icon(Icons.home)
const EdgeInsets.all(16)

// Use const for local variables when possible
final padding = const EdgeInsets.all(16);
```

---

## Riverpod Providers

```dart
// Always use code generation
part 'my_notifier.g.dart';
part 'my_notifier.freezed.dart';

// State notifier
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => MyState.initial();

  Future<void> loadData() async {
    // implementation
  }
}

// Simple provider
@riverpod
String myValue(MyValueRef ref) => 'value';
```

---

## Freezed Models

```dart
// Always include part directives
part 'my_model.g.dart';
part 'my_model.freezed.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    String? name,
    @Default(false) bool isActive,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, Object?> json) =>
      _$MyModelFromJson(json);
}
```

---

## Colors & Theming

```dart
// Use theme colors from context
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
Theme.of(context).textTheme.titleLarge

// For design-specific colors, use app_constants.dart
import '../../../core/constants/app_constants.dart';
AppColors.primary

// Color with alpha (use withValues, NOT withOpacity)
color.withValues(alpha: 0.5)  // Correct
color.withOpacity(0.5)         // DEPRECATED - do not use

// Direct color values (from design specs)
const Color(0xFF135BEC)  // Primary blue
```

---

## Things to AVOID

```dart
// DON'T: use print() - use AppLogger instead
import '../../../core/utils/logger.dart';
AppLogger.i('Info message');
AppLogger.e('Error', error, stackTrace);

// DON'T: use 'as' without null check
// DO: Use type checking
if (value is MyClass) {
  value.myMethod();
}

// DON'T: use 'late' unless absolutely necessary
// DO: Use nullable types with initialization
String? name;

// DON'T: use ! (bang operator)
// DO: Use proper null checks
if (value != null) {
  value.doSomething();
}

// DON'T: withOpacity() - deprecated
// DO: withValues(alpha: )
color.withValues(alpha: 0.5)
```

---

## Widget Composition

```dart
// Break large widgets into smaller, reusable pieces
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(context),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildContent(),
        const SizedBox(height: 24),
        _buildFooter(),
      ],
    ),
  );
}

PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    title: const Text('My Screen'),
  );
}

Widget _buildHeader() => const HeaderWidget();
Widget _buildContent() => const ContentWidget();
Widget _buildFooter() => const FooterWidget();
```

---

## Async/Await Error Handling

```dart
Future<void> loadData() async {
  try {
    state = state.copyWith(isLoading: true);
    final data = await _repository.fetch();
    state = state.copyWith(data: data, isLoading: false);
  } catch (error, stackTrace) {
    AppLogger.e('Failed to load data', error, stackTrace);
    state = state.copyWith(
      isLoading: false,
      error: error.toString(),
    );
  }
}
```

---

## Extension Methods (Nullable Types)

```dart
// DON'T: Use ! on nullable generics
extension LetExtension<T> on T? {
  R? let<R>(R Function(T) callback) {
    final value = this;
    if (value != null) {
      return callback(value);
    }
    return null;
  }
}

// DO: Explicit null check
extension NullableString on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
```

---

## UI Development Rules

1. **Always match Stitch design prototypes** - Reference files in `stitch/` directory
2. **Use Inter font** - via `GoogleFonts.inter()` from `google_fonts` package
3. **Follow Material 3** - use Material 3 components and patterns
4. **Consistent spacing** - Use values: 4, 8, 12, 16, 24, 32 (multiples of 4)
5. **Dark mode support** - Always test in both light and dark themes

```dart
// Spacing constants
const gap4 = SizedBox(height: 4);
const gap8 = SizedBox(height: 8);
const gap16 = SizedBox(height: 16);
const gap24 = SizedBox(height: 24);
const gap32 = SizedBox(height: 32);

// Horizontal gaps
const hGap8 = SizedBox(width: 8);
const hGap16 = SizedBox(width: 16);
```

---

## Before Committing Checklist

```bash
# 1. Format all code
dart format .

# 2. Run analysis (must show "No issues found")
flutter analyze

# 3. Apply auto-fixes
dart fix --apply

# 4. Run tests
flutter test

# 5. Check for outdated dependencies
flutter pub outdated
```

---

## Project-Specific Rules

| Aspect | Rule |
|--------|------|
| **State Management** | Use Riverpod with code generation (`@riverpod`) |
| **Navigation** | Use `go_router` for all navigation |
| **Models** | Use Freezed for immutable models |
| **Storage** | Use Hive for local data persistence |
| **Fonts** | Use Inter via `google_fonts` |
| **Icons** | Use Material Icons |
| **Theme** | Material 3 with `flex_color_scheme` |
| **Architecture** | Clean Architecture: data/domain/presentation layers |

---

## File Naming Convention

```
features/
└── library/
    ├── data/
    │   ├── pdf_repository.dart
    │   └── pdf_repository_impl.dart
    ├── domain/
    │   └── use_cases/
    │       └── load_pdfs_use_case.dart
    └── presentation/
        ├── library_screen.dart
        ├── library_state.dart
        └── providers/
            ├── library_notifier.dart
            ├── library_notifier.g.dart      # Generated
            └── library_notifier.freezed.dart # Generated
```

---

## Quick Reference

| Pattern | Example |
|---------|---------|
| Widget file | `library_screen.dart` |
| State file | `library_state.dart` |
| Notifier file | `library_notifier.dart` |
| Model file | `pdf_document.dart` |
| Repository file | `pdf_repository.dart` |
| Constants file | `app_constants.dart` |
| Utils file | `logger.dart` |

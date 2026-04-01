# Model/State Generator

Generate Freezed models and Riverpod notifiers following project patterns from `.claude/rules/code-style.md` and `.claude/rules/architecture.md`.

## Purpose

Every feature needs immutable state classes and Riverpod notifiers. This skill automates:
- Freezed model generation with proper annotations
- Riverpod notifier with code generation
- Part directives for build_runner
- fromJson/toJson methods
- Proper field typing with defaults

**Token Savings**: ~85% (from ~1000 to ~150 tokens per model+state+notifier triplet)

## Usage

```bash
/model-generator <Name> [options]
```

**Options**:
- `--with-notifier` - Also generate Riverpod notifier for the state
- `--state-only` - Generate state class only (no notifier)
- `--immutable-only` - Generate immutable class without copyWith
- `--add-variant <name>` - Add new state variant to existing state

**Examples**:
```bash
/model-generator ScannerState --with-notifier
/model-generator UserProfile
/model-generator PdfMetadata --state-only
/model-generator ChatState --add-variant sending
```

## Process

1. **Parse model name** and options from command
2. **Prompt for field definitions** (or infer from context):
   - Field name
   - Type (String, int, bool, List, custom type)
   - Required or optional
   - Default value (for optional fields)
3. **Generate Freezed model** with proper part directives
4. **Generate Riverpod notifier** (if `--with-notifier` specified)
5. **Include fromJson/toJson** methods
6. **Follow naming conventions** from code-style.md

## Generated Code Structure

### Freezed State Model

```dart
part '{{name}}.g.dart';
part '{{name}}.freezed.dart';

@freezed
class {{ClassName}} with _${{ClassName}} {
  const factory {{ClassName}}.initial() = _{{ClassName}}Initial;

  const factory {{ClassName}}.{{state_name}}({
    @Default(false) bool isLoading,
    {{fields_with_defaults}}
  }) = _{{ClassName}}{{StateName}};

  const factory {{ClassName}}.{{another_state}}({
    {{fields}}
  }) = _{{ClassName}}{{AnotherState}};
}
```

### Riverpod Notifier

```dart
part '{{name}}_notifier.g.dart';
part '{{name}}_notifier.freezed.dart';

@riverpod
class {{Name}}Notifier extends _${{Name}}Notifier {
  @override
  {{StateType}} build() {
    {{initialization}}
    return {{StateType}}.initial();
  }

  {{methods}}
}
```

## Field Definition System

### Interactive Field Builder

When you run `/model-generator`, you'll be prompted for fields:

```
Enter fields (empty to finish):

Field name: isScanning
Type (String|int|bool|List|Custom): bool
Required? (y/n): y
Default value: [n/a for required]

Field name: scannedPath
Type (String|int|bool|List|Custom): String
Required? (y/n): n
Default value: [optional, press Enter for null]

Field name: [Enter to finish]
```

### Common Field Types

| Type | Example | Default Value |
|------|---------|---------------|
| `bool` | `isLoading` | `@Default(false)` |
| `String?` | `errorMessage` | `null` |
| `List<T>` | `pdfs` | `@Default([])` |
| `int` | `pageCount` | `0` |
| `CustomModel?` | `selectedPdf` | `null` |

## Generated Files

Files are generated in the appropriate feature directories:

```
lib/
├── core/
│   └── data/
│       └── models/
│           └── {name}_state.dart          # Freezed state model
└── features/
    └── {feature}/
        └── presentation/
            └── providers/
                └── {name}_notifier.dart    # Riverpod notifier
```

## After Generation

After files are generated, run:

```bash
# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Fix any issues
dart fix --apply

# Format code
dart format .

# Run tests
flutter test
```

## Dependencies

- Reads patterns from `.claude/rules/code-style.md`
- Follows architecture patterns from `.claude/rules/architecture.md`
- Uses existing Freezed + Riverpod patterns in codebase

## Related Skills

- `/test-generator` - Generate tests for your models and notifiers
- `/scaffold-feature` - Generate complete feature structure
- `/code-review` - Review generated code for quality

## Troubleshooting

**Issue**: build_runner fails with "conflict" error
- **Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Issue**: Part directives are missing
- **Solution**: Ensure both `.g.dart` and `.freezed.dart` part files are included

**Issue**: Notifier can't find state type
- **Solution**: Make sure state file is imported in notifier file

**Issue**: fromJson/toJson not working
- **Solution**: Add `const factory {{Model}}.fromJson(Map<String, Object?> json)` to model

## Best Practices

1. **Use proper naming**: State classes end with `State`, notifiers end with `Notifier`
2. **Make most fields optional** with sensible defaults
3. **Use `@Default` annotation** for optional fields instead of nullable when possible
4. **Keep state immutable** - use copyWith for updates
5. **Add state variants** for different states (loading, data, error, etc.)

## Examples

### Example 1: Scanner State with Notifier

```bash
/model-generator ScannerState --with-notifier
```

**Input**:
```
Field 1: isScanning (bool, required)
Field 2: scannedPath (String?, optional)
Field 3: error (String?, optional)
```

**Output** - `lib/features/scanner/presentation/scanner_state.dart`:
```dart
part 'scanner_state.g.dart';
part 'scanner_state.freezed.dart';

@freezed
class ScannerState with _$ScannerState {
  const factory ScannerState.initial() = _ScannerStateInitial;

  const factory ScannerState.scanning({
    @Default(false) bool isScanning,
    String? scannedPath,
    String? error,
  }) = _ScannerStateScanning;
}
```

**Output** - `lib/features/scanner/presentation/providers/scanner_notifier.dart`:
```dart
part 'scanner_notifier.g.dart';
part 'scanner_notifier.freezed.dart';

@riverpod
class ScannerNotifier extends _$ScannerNotifier {
  @override
  ScannerState build() => ScannerState.initial();

  Future<void> scanDocument(String path) async {
    state = ScannerState.scanning(isScanning: true);
    // Implementation...
  }
}
```

### Example 2: User Profile Model (No Notifier)

```bash
/model-generator UserProfile
```

**Input**:
```
Field 1: name (String, required)
Field 2: email (String, required)
Field 3: preferences (UserPreferences?, optional)
```

**Output** - `lib/core/data/models/user_profile.dart`:
```dart
part 'user_profile.g.dart';
part 'user_profile.freezed.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String email,
    UserPreferences? preferences,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, Object?> json) =>
      _$UserProfileFromJson(json);
}
```

## Adding Variants to Existing State

To add a new variant to an existing state:

```bash
/model-generator ChatState --add-variant sending
```

This will:
1. Read existing state file
2. Add new variant with appropriate fields
3. Update copyWith and when methods automatically

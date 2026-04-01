# Test Generator

Generate complete test files following project testing standards from `.claude/rules/testing.md`.

## Purpose

Tests are mandatory for every feature in this project, following strict Arrange-Act-Assert patterns. This skill automates test file creation with:
- Proper mock setup using `@GenerateMocks`
- ProviderContainer configuration for Riverpod
- Test data factories
- Comprehensive test cases (success, failure, edge cases)

**Token Savings**: ~87% (from ~1500 to ~200 tokens per test file)

## Usage

```bash
/test-generator <type> <target>
```

**Types**:
- `notifier` - Generate unit tests for Riverpod notifiers
- `model` - Generate unit tests for Freezed models
- `widget` - Generate widget tests for screens
- `usecase` - Generate unit tests for use cases
- `repository` - Generate unit tests for repositories

**Examples**:
```bash
/test-generator notifier pdf_chat
/test-generator model pdf_document
/test-generator widget library_screen
/test-generator usecase load_pdfs
/test-generator repository pdf
```

## Process

1. **Read target file** to understand structure and dependencies
2. **Extract dependencies** for mock generation
3. **Select template** based on test type
4. **Generate test file** following Arrange-Act-Assert pattern from `testing.md`
5. **Add mock annotations** using `@GenerateMocks`
6. **Include ProviderContainer setup** for Riverpod testing
7. **Create test data factories** for reusable test data

## Generated Test Structure

All generated tests follow the structure from `.claude/rules/testing.md`:

```dart
// Imports
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Mock generation
@GenerateMocks([...])
import 'target_test.mocks.dart';

void main() {
  late MockDependencies;
  late ProviderContainer container;

  setUp(() {
    // Initialize mocks
    // Setup ProviderContainer with overrides
  });

  tearDown(() {
    container.dispose();
  });

  group('TargetName', () {
    test('should return initial state when created', () {
      // Arrange
      // Act
      // Assert
    });

    test('should handle success case', () async {
      // Arrange
      // Act
      // Assert
    });

    test('should handle error case', () async {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

## Generated Files

Tests are generated in the `test/` directory following project structure:

```
test/
├── unit/
│   └── features/
│       └── {feature}/
│           ├── {feature}_notifier_test.dart
│           ├── {feature}_state_test.dart
│           ├── {feature}_use_case_test.dart
│           └── repositories/
│               └── {feature}_repository_test.dart
└── widget/
    └── features/
        └── {feature}/
            └── {feature}_screen_test.dart
```

## After Generation

After test files are generated, run:

```bash
# Generate mocks
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test test/unit/features/{feature}/{feature}_test.dart

# Run all tests
flutter test
```

## Dependencies

- Reads patterns from `.claude/rules/testing.md`
- Uses existing mock patterns from `test/unit/features/`
- Follows test structure documented in CLAUDE.md

## Related Skills

- `/model-generator` - Generate models that tests will verify
- `/scaffold-feature` - Generate feature structure with test templates
- `/code-review` - Review generated tests for quality
- `/pre-commit` - Validate tests pass before committing

## Troubleshooting

**Issue**: Mock generation fails
- **Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Issue**: ProviderContainer setup is incorrect
- **Solution**: Check that provider overrides match the actual provider definitions

**Issue**: Tests fail to compile
- **Solution**: Verify all imports are correct and dependencies are properly mocked

## Best Practices

1. **Run tests immediately** after generation to catch issues early
2. **Customize test cases** for your specific business logic
3. **Add edge cases** that the auto-generation might miss
4. **Keep tests focused** - one assertion per test when possible
5. **Use descriptive test names** following BDD style

## Examples

See generated test files in:
- `test/unit/features/library/library_notifier_test.dart`
- `test/unit/features/reader/pdf_chat_notifier_test.dart`
- `test/unit/core/data/models/pdf_document_test.dart`

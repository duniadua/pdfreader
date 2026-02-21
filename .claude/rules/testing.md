# Dart/Flutter Testing Guidelines

This file contains testing rules and guidelines that MUST be followed when writing tests in this repository.

---

## Testing Philosophy

- **Test behavior, not implementation** - Focus on what the code does, not how it does it
- **Arrange-Act-Assert pattern** - Structure tests clearly with these three phases
- **Descriptive test names** - Test names should describe what is being tested
- **One assertion per test** - Keep tests focused and simple
- **Mock external dependencies** - Use mocks for repositories, services, and external APIs

---

## File Organization

```
test/
├── features/
│   └── library/
│       ├── application/
│       │   └── library_notifier_test.dart      # Notifier tests
│       ├── domain/
│       │   └── use_cases/
│       │       └── load_pdfs_use_case_test.dart # Use case tests
│       └── data/
│           └── pdf_repository_test.dart        # Repository tests
├── shared/
│   └── widgets/
│       └── pdf_card_test.dart                  # Widget tests
├── core/
│   ├── utils/
│   │   └── logger_test.dart
│   └── data/
│       └── models/
│           └── pdf_document_test.dart          # Model tests
└── test_utils/
    ├── mocks.dart                              # Mock classes
    └── test_helpers.dart                       # Helper functions
```

---

## Test Naming Conventions

```dart
// File naming: *_test.dart
library_notifier_test.dart
pdf_repository_test.dart
pdf_card_test.dart

// Test naming: describe what is being tested
group('LibraryNotifier', () {
  test('should return initial state when created', () {
    // Test implementation
  });

  test('should load pdfs successfully', () {
    // Test implementation
  });

  test('should throw exception when repository fails', () {
    // Test implementation
  });
});

// BDD-style naming (Given-When-Then)
test('given user is logged in, when loading library, then return pdfs', () {
  // Test implementation
});
```

---

## Unit Tests

### Testing Notifiers/Controllers

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../../lib/features/library/application/library_notifier.dart';
import '../../../../lib/core/data/repositories/pdf_repository.dart';
import '../../../../lib/core/data/models/pdf_document.dart';

// Generate mocks with: flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([PdfRepository])
import 'library_notifier_test.mocks.dart';

void main() {
  late MockPdfRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockPdfRepository();
    container = ProviderContainer(
      overrides: [
        pdfRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LibraryNotifier', () {
    test('should return initial state when created', () {
      // Arrange
      const initialState = LibraryState.initial();

      // Act
      final state = container.read(libraryNotifierProvider);

      // Assert
      expect(state, initialState);
    });

    test('should load pdfs successfully', () async {
      // Arrange
      final pdfs = [PdfDocument(id: '1', title: 'Test', filePath: '/path')];
      when(mockRepository.getAllPdfs())
          .thenAnswer((_) async => Result.success(pdfs));

      // Act
      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadLibrary();

      // Assert
      final state = container.read(libraryNotifierProvider);
      expect(state.allPdfs, pdfs);
      expect(state.isLoading, false);
      verify(mockRepository.getAllPdfs()).called(1);
    });

    test('should set error state when repository fails', () async {
      // Arrange
      final error = Exception('Failed to load');
      when(mockRepository.getAllPdfs())
          .thenAnswer((_) async => Result.failure(error));

      // Act
      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadLibrary();

      // Assert
      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, false);
      expect(state.failure, isNotNull);
    });
  });
}
```

### Testing Use Cases

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../../lib/features/library/domain/use_cases/load_pdfs_use_case.dart';
import '../../../../lib/core/data/repositories/pdf_repository.dart';
import '../../../../lib/core/utils/failures.dart';

@GenerateMocks([PdfRepository])
import 'load_pdfs_use_case_test.mocks.dart';

void main() {
  late LoadPdfsUseCase useCase;
  late MockPdfRepository mockRepository;

  setUp(() {
    mockRepository = MockPdfRepository();
    useCase = LoadPdfsUseCase(mockRepository);
  });

  group('LoadPdfsUseCase', () {
    test('should return list of pdfs when repository succeeds', () async {
      // Arrange
      final pdfs = [
        PdfDocument(id: '1', title: 'PDF 1', filePath: '/path/1'),
        PdfDocument(id: '2', title: 'PDF 2', filePath: '/path/2'),
      ];
      when(mockRepository.getAllPdfs())
          .thenAnswer((_) async => Right(pdfs));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (data) => expect(data.length, 2),
      );
    });

    test('should return failure when repository fails', () async {
      // Arrange
      when(mockRepository.getAllPdfs())
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return Left'),
      );
    });
  });
}
```

### Testing Models

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader_app/core/data/models/pdf_document.dart';

void main() {
  group('PdfDocument', () {
    test('should create instance with required fields', () {
      // Arrange & Act
      const pdf = PdfDocument(
        id: '1',
        title: 'Test PDF',
        filePath: '/path/to/file.pdf',
      );

      // Assert
      expect(pdf.id, '1');
      expect(pdf.title, 'Test PDF');
      expect(pdf.filePath, '/path/to/file.pdf');
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      const pdf = PdfDocument(
        id: '1',
        title: 'Test PDF',
        filePath: '/path/to/file.pdf',
        pageCount: 100,
      );

      // Act
      final json = pdf.toJson();

      // Assert
      expect(json['id'], '1');
      expect(json['title'], 'Test PDF');
      expect(json['filePath'], '/path/to/file.pdf');
      expect(json['pageCount'], 100);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'id': '1',
        'title': 'Test PDF',
        'filePath': '/path/to/file.pdf',
        'pageCount': 100,
      };

      // Act
      final pdf = PdfDocument.fromJson(json);

      // Assert
      expect(pdf.id, '1');
      expect(pdf.title, 'Test PDF');
      expect(pdf.pageCount, 100);
    });

    test('should copy with new values', () {
      // Arrange
      const pdf = PdfDocument(
        id: '1',
        title: 'Test PDF',
        filePath: '/path/to/file.pdf',
      );

      // Act
      final updated = pdf.copyWith(title: 'Updated PDF');

      // Assert
      expect(updated.id, '1');
      expect(updated.title, 'Updated PDF');
      expect(updated.filePath, '/path/to/file.pdf');
    });
  });
}
```

---

## Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../lib/features/library/presentation/library_screen.dart';
import '../../../../lib/core/data/models/pdf_document.dart';
import '../../../../lib/features/library/application/library_notifier.dart';

void main() {
  group('LibraryScreen', () {
    testWidgets('should show loading indicator when loading',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith((ref) {
              return LibraryNotifier();
            }),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display pdf list when loaded', (tester) async {
      // Arrange
      const pdfs = [
        PdfDocument(id: '1', title: 'PDF 1', filePath: '/path/1'),
        PdfDocument(id: '2', title: 'PDF 2', filePath: '/path/2'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith(
              (ref) => MockLibraryNotifier(state: LibraryState(allPdfs: pdfs)),
            ),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('PDF 1'), findsOneWidget);
      expect(find.text('PDF 2'), findsOneWidget);
    });

    testWidgets('should show empty state when no pdfs', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith(
              (ref) => MockLibraryNotifier(state: LibraryState(allPdfs: [])),
            ),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No PDFs yet'), findsOneWidget);
    });

    testWidgets('should navigate to reader when pdf is tapped',
        (tester) async {
      // Arrange
      const pdf = PdfDocument(id: '1', title: 'Test PDF', filePath: '/path');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryNotifierProvider.overrideWith(
              (ref) => MockLibraryNotifier(state: LibraryState(allPdfs: [pdf])),
            ),
          ],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Test PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PdfReaderScreen), findsOneWidget);
    });
  });
}
```

---

## Golden Tests (Snapshot Testing)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../lib/features/library/presentation/widgets/pdf_card.dart';
import '../../../../lib/core/data/models/pdf_document.dart';

void main() {
  group('PdfCard Golden Tests', () {
    testWidgets('should match golden file in light mode', (tester) async {
      // Arrange
      const pdf = PdfDocument(
        id: '1',
        title: 'Test PDF',
        filePath: '/path/to/file.pdf',
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(body: PdfCard(pdf: pdf)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(PdfCard),
        matchesGoldenFile('goldens/pdf_card_light.png'),
      );
    });

    testWidgets('should match golden file in dark mode', (tester) async {
      // Arrange
      const pdf = PdfDocument(
        id: '1',
        title: 'Test PDF',
        filePath: '/path/to/file.pdf',
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: PdfCard(pdf: pdf)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(PdfCard),
        matchesGoldenFile('goldens/pdf_card_dark.png'),
      );
    });
  });
}
```

---

## Mocking Guidelines

### Using Mockito

```dart
// 1. Add to pubspec.yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0

// 2. Generate mocks
// flutter pub run build_runner build --delete-conflicting-outputs

// 3. Use in tests
@GenerateMocks([PdfRepository])
import 'pdf_repository_test.mocks.dart';

void main() {
  late MockPdfRepository mockRepository;

  setUp(() {
    mockRepository = MockPdfRepository();
  });

  test('should get pdfs', () async {
    // Setup mock behavior
    when(mockRepository.getAllPdfs())
        .thenAnswer((_) async => Result.success([]));

    // Test code...

    // Verify interaction
    verify(mockRepository.getAllPdfs()).called(1);
  });
}
```

### Mock Verification

```dart
// Verify method was called
verify(mockRepository.getAllPdfs()).called(1);

// Verify method was never called
verifyNever(mockRepository.deletePdf(any));

// Verify with specific arguments
verify(mockRepository.getPdfById('123')).called(1);

// Verify at least/at most
verify(mockRepository.getAllPdfs()).called(greaterThan(0));
```

---

## Test Helpers

Create reusable test helpers in `test/test_utils/test_helpers.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Wrapper for testing with providers
class TestWidget extends StatelessWidget {
  const TestWidget({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  final Widget child;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }
}

// Sample data factories
class TestData {
  static PdfDocument createPdf({
    String? id,
    String? title,
    String? filePath,
  }) {
    return PdfDocument(
      id: id ?? '1',
      title: title ?? 'Test PDF',
      filePath: filePath ?? '/path/to/file.pdf',
    );
  }

  static List<PdfDocument> createPdfList({int count = 3}) {
    return List.generate(
      count,
      (i) => createPdf(id: '$i', title: 'PDF $i'),
    );
  }
}

// Async test helper
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Timed out waiting for widget', timeout);
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
```

---

## Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/library/application/library_notifier_test.dart

# Run tests for a specific folder
flutter test test/features/library/

# Run tests in a specific file with debug output
flutter test test/features/library/application/library_notifier_test.dart --debug

# Run golden tests (update golden files)
flutter test --update-goldens

# Run tests with platform specified
flutter test --platform chrome

# Run tests with retry
flutter test --retry=3
```

---

## Coverage Reports

```bash
# Generate coverage
flutter test --coverage

# View coverage in terminal
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Minimum coverage requirement (add to pubspec.yaml)
# Use coverage_badge package for GitHub
```

---

## Test Checklist

Before considering a feature "complete", ensure:

- [ ] All business logic has unit tests (>80% coverage)
- [ ] All widgets have widget tests
- [ ] Edge cases are tested (null values, empty lists, errors)
- [ ] User interactions are tested (taps, scrolls, inputs)
- [ ] Loading and error states are tested
- [ ] Both light and dark themes are tested (for widgets)
- [ ] All tests pass locally
- [ ] No skipped tests (`skip: false`)

---

## Best Practices

### DO ✅

```dart
// Test one thing per test
test('should return error when network fails', () {});

// Use descriptive names
test('loadLibrary should set isLoading to true while fetching', () {});

// Follow Arrange-Act-Assert
test('should filter pdfs by search query', () {
  // Arrange
  final pdfs = [pdf1, pdf2, pdf3];
  final query = 'pdf1';

  // Act
  final result = filterPdfs(pdfs, query);

  // Assert
  expect(result, [pdf1]);
});

// Use matchers
expect(value, isNotNull);
expect(list, isEmpty);
expect(number, greaterThan(0));
expect(string, contains('substring'));
```

### DON'T ❌

```dart
// Don't test multiple things in one test
test('should load, filter, and sort pdfs', () {}); // Bad!

// Don't use vague names
test('test123', () {}); // Bad!

// Don't skip tests without explanation
test('should fail', () {}, skip: true); // Bad - add reason!

// Don't ignore errors in tests
test('should handle error', () async {
  try {
    await function();
  } catch (_) {} // Bad - should assert the error!
});
```

---

## Common Test Matchers

```dart
// Nullability
expect(value, isNull);
expect(value, isNotNull);

// Numbers
expect(number, equals(42));
expect(number, greaterThan(0));
expect(number, lessThanOrEqualTo(100));
expect(number, isPositive);
expect(number, inInclusiveRange(1, 10));

// Strings
expect(string, equals('hello'));
expect(string, contains('ell'));
expect(string, startsWith('hel'));
expect(string, endsWith('llo'));
expect(string, matches(RegExp(r'^\w+$')));

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(3));
expect(list, contains(item));
expect(list, orderedEquals([1, 2, 3]));

// Types
expect(value, isA<String>());
expect(value, isNotNull);

// Futures
expectLater(future, completes);
expectLater(future, throwsException);
expectLater(future, throwsA(isA<NotFoundException>()));

// Widgets
expect(find.byType(Text), findsOneWidget);
expect(find.text('Hello'), findsWidgets);
expect(find.byKey(Key('my-key')), findsNothing);
```

---

## CI/CD Integration

Add to `.github/workflows/test.yml`:

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.5'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test --update-goldens  # Only for PRs that update goldens
```

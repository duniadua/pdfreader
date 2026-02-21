# Clean Architecture Guidelines

This repository follows **Clean Architecture** principles with a feature-based structure. All code must adhere to these architectural rules.

---

## Core Principle

**Dependencies must only point inward**:

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                         │
│  (Widgets, Notifiers, Controllers - Flutter/Riverpod)      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                          Domain                             │
│  (Use Cases, Entities - Pure Dart, no Flutter deps)        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                           Data                              │
│  (Repositories, Data Sources, DTOs, Hive Models)           │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── core/                          # Shared across all features
│   ├── constants/                 # App-wide constants
│   │   └── app_constants.dart
│   ├── data/                      # Core data layer
│   │   ├── models/                # Hive models, DTOs
│   │   │   ├── pdf_document.dart
│   │   │   └── app_settings.dart
│   │   ├── repositories/          # Repository interfaces & impls
│   │   │   ├── pdf_repository.dart
│   │   │   └── settings_repository.dart
│   │   └── providers/             # Riverpod providers
│   │       └── repository_providers.dart
│   ├── router/                    # Navigation
│   │   └── app_router.dart
│   ├── theme/                     # App theming
│   │   └── app_theme.dart
│   └── utils/                     # Utilities
│       ├── logger.dart
│       exceptions.dart
│       └── failures.dart
├── features/                      # Feature modules
│   └── {feature_name}/
│       ├── data/                  # Data layer (optional)
│       │   ├── repositories/      # Feature-specific repos
│       │   └── datasources/       # API, local storage, etc.
│       ├── domain/                # Business logic (optional)
│       │   ├── entities/          # Core business objects
│       │   └── usecases/          # Use case implementations
│       └── presentation/          # UI layer
│           ├── {feature}_screen.dart
│           ├── {feature}_state.dart
│           └── providers/
│               └── {feature}_notifier.dart
└── shared/                        # Shared widgets & providers
    ├── widgets/
    └── providers/
```

---

## Layer Responsibilities

### 1. Data Layer

**Responsibility**: Data sources, data persistence, external APIs

```dart
// Repository Interface (in core/data or features/{feature}/data)
abstract class PdfRepository {
  Future<Result<List<PdfDocument>>> getAllPdfs();
  Future<Result<PdfDocument>> getPdfById(String id);
  Future<Result<void>> savePdf(PdfDocument pdf);
}

// Implementation
class SharedPreferencesPdfRepository implements PdfRepository {
  @override
  Future<Result<List<PdfDocument>>> getAllPdfs() {
    // Implementation
  }
}
```

**Rules:**
- NO Flutter widgets or Material imports
- NO business logic (only data transformation)
- Returns `Result<T>` types (Either-like pattern)
- Handles all data sources (local, API, cache)

### 2. Domain Layer

**Responsibility**: Business logic, use cases, entities

```dart
// Use Case
class LoadPdfsUseCase {
  const LoadPdfsUseCase(this._repository);

  final PdfRepository _repository;

  Future<Result<List<PdfDocument>>> call() {
    return _repository.getAllPdfs();
  }
}

// Entity (business object)
// Often just reusing data models for simple apps
class PdfDocument {
  const PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
  });

  final String id;
  final String title;
  final String filePath;

  // Business logic methods
  bool get isValid => id.isNotEmpty && filePath.isNotEmpty;
}
```

**Rules:**
- Pure Dart - NO Flutter dependencies
- NO data persistence logic
- Contains business rules and validation
- Use cases are single-responsibility operations

### 3. Presentation Layer

**Responsibility**: UI, state management, user interaction

```dart
// State
@freezed
class LibraryState with _$LibraryState {
  const factory LibraryState({
    required List<PdfDocument> pdfs,
    required bool isLoading,
    AppFailure? error,
  }) = _LibraryState;
}

// Notifier
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  @override
  LibraryState build() => LibraryState.initial();

  Future<void> loadPdfs() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getAllPdfs();
    result.when(
      success: (pdfs) => state = state.copyWith(pdfs: pdfs, isLoading: false),
      failure: (error) => state = state.copyWith(isLoading: false, error: error),
    );
  }
}

// Widget
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryNotifierProvider);

    return Scaffold(
      body: state.isLoading
          ? const CircularProgressIndicator()
          : PdfList(pdfs: state.pdfs),
    );
  }
}
```

**Rules:**
- Uses Riverpod for state management
- Widgets are dumb - delegate logic to notifiers
- No business logic in widgets
- State is immutable (using Freezed)

---

## Dependency Rules

### Allowed Imports by Layer

| Layer | Can Import | Cannot Import |
|-------|------------|---------------|
| **Presentation** | Domain, Core, shared widgets | Data (only via Domain) |
| **Domain** | Core (entities, utils) | Data, Flutter widgets |
| **Data** | Core, external packages | Presentation, Domain use cases |
| **Core** | External packages only | Features, Presentation |

### Import Patterns

```dart
// ✅ CORRECT - Presentation imports Domain
import '../../domain/usecases/load_pdfs_use_case.dart';

// ✅ CORRECT - Data imports Core models
import '../../../core/data/models/pdf_document.dart';

// ❌ WRONG - Domain importing Presentation
import '../../presentation/library_screen.dart';

// ❌ WRONG - Data importing Domain use cases
import '../../domain/usecases/load_pdfs_use_case.dart';

// ❌ WRONG - Any layer importing another feature's internals
import '../../reader/presentation/reader_screen.dart';
// Use shared/navigation/router.go instead
```

---

## Feature Creation Template

When creating a new feature, follow this structure:

```
features/{feature_name}/
├── data/
│   ├── {feature}_repository.dart      # Interface
│   └── impl/
│       └── {feature}_repository_impl.dart
├── domain/
│   └── usecases/
│       └── {operation}_{entity}_use_case.dart
└── presentation/
    ├── {feature}_screen.dart
    ├── {feature}_state.dart
    └── providers/
        └── {feature}_notifier.dart
```

**Example: Creating a "Scanner" feature**

```dart
// 1. Data Layer - Repository Interface
// features/scanner/data/scanner_repository.dart
abstract class ScannerRepository {
  Future<Result<String>> scanDocument(String imagePath);
}

// 2. Domain Layer - Use Case
// features/scanner/domain/usecases/scan_document_use_case.dart
class ScanDocumentUseCase {
  const ScanDocumentUseCase(this._repository);

  final ScannerRepository _repository;

  Future<Result<String>> call(String imagePath) {
    return _repository.scanDocument(imagePath);
  }
}

// 3. Presentation Layer - State & Notifier
// features/scanner/presentation/scanner_state.dart
@freezed
class ScannerState with _$ScannerState {
  const factory ScannerState({
    required bool isScanning,
    String? scannedPath,
    AppFailure? error,
  }) = _ScannerState;
}

// features/scanner/presentation/providers/scanner_notifier.dart
@riverpod
class ScannerNotifier extends _$ScannerNotifier {
  @override
  ScannerState build() => ScannerState(isScanning: false);

  Future<void> scanDocument(String imagePath) async {
    state = state.copyWith(isScanning: true);
    final result = await _useCase(imagePath);
    result.when(
      success: (path) => state = state.copyWith(isScanning: false, scannedPath: path),
      failure: (error) => state = state.copyWith(isScanning: false, error: error),
    );
  }
}

// 4. Presentation Layer - Widget
// features/scanner/presentation/scanner_screen.dart
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerNotifierProvider);

    return Scaffold(
      body: state.isScanning
          ? const ScanningView()
          : ScannerIdleView(onScan: (path) {
              ref.read(scannerNotifierProvider.notifier).scanDocument(path);
            }),
    );
  }
}
```

---

## Common Patterns

### Result Type (Either-like)

```dart
// core/utils/result.dart
abstract class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    }
    return failure((this as Failure<T>).error);
  }
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}
```

### Failure Types

```dart
// core/utils/failures.dart
abstract class AppFailure {
  const AppFailure(this.message);

  final String message;

  factory AppFailure.fromException(AppException exception) {
    return exception.when(
      network: (message) => NetworkFailure(message),
      storage: (message) => StorageFailure(message),
      notFound: (message) => NotFoundFailure(message),
      unknown: (message) => UnknownFailure(message),
    );
  }
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
```

---

## Provider Organization

```dart
// core/data/providers/repository_providers.dart
@riverpod
PdfRepository pdfRepository(PdfRepositoryRef ref) {
  return SharedPreferencesPdfRepository();
}

// features/library/presentation/providers/library_notifier.dart
@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  @override
  LibraryState build() {
    final repository = ref.watch(pdfRepositoryProvider);
    // Initialize...
    return LibraryState.initial();
  }
}
```

---

## Navigation Architecture

Use `go_router` for all navigation. Routes are defined centrally:

```dart
// core/router/app_router.dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/reader/:id',
      name: 'reader',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ReaderScreen(pdfId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

// Navigation usage
context.goNamed('reader', pathParameters: {'id': pdf.id});
```

---

## Architecture Checklist

Before adding new code, verify:

- [ ] Dependencies flow inward (no circular imports)
- [ ] Presentation doesn't import Data directly
- [ ] Domain has no Flutter dependencies
- [ ] State is immutable (Freezed)
- [ ] Repositories return Result types
- [ ] Use cases are single-responsibility
- [ ] Widgets are dumb (logic in notifiers)
- [ ] No business logic in widgets
- [ ] Navigation uses go_router
- [ ] Core has no feature-specific code

---

## Anti-Patterns to Avoid

### ❌ DON'T: Business Logic in Widgets

```dart
// BAD
class BadWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final pdfs = Hive.box('pdfs').values.toList(); // Direct DB access!
    return ListView.builder(
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        if (pdf.title.contains('.pdf')) { // Business logic in widget!
          return PdfCard(pdf: pdf);
        }
        return const SizedBox();
      },
    );
  }
}
```

### ✅ DO: Use Notifiers for Logic

```dart
// GOOD
class GoodWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryNotifierProvider);

    return state.when(
      loading: () => const CircularProgressIndicator(),
      data: (pdfs) => PdfListView(pdfs: pdfs),
      error: (error) => ErrorView(error: error),
    );
  }
}
```

### ❌ DON'T: Circular Dependencies

```dart
// library/presentation/library_screen.dart
import '../../reader/presentation/reader_screen.dart'; // WRONG!
```

### ✅ DO: Use Router

```dart
// Use navigation instead
context.goNamed('reader', pathParameters: {'id': pdf.id});
```

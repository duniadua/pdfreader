# Feature Scaffold

Generate complete feature structure following Clean Architecture from `.claude/rules/architecture.md`.

## Purpose

Creating a new feature requires creating many files following Clean Architecture. This skill automates:
- Data layer (repositories, data sources)
- Domain layer (use cases, entities)
- Presentation layer (screens, state, notifiers)
- Test file templates
- Proper import structure
- Naming conventions

**Token Savings**: ~92% (from ~2500 to ~200 tokens per feature)

## Usage

```bash
/scaffold-feature <feature_name> [layers]
```

**Layers** (comma-separated):
- `all` - data,domain,presentation (default)
- `data` - data layer only
- `domain` - domain layer only
- `presentation` - presentation layer only
- Custom combination: e.g., `data,presentation`

**Examples**:
```bash
/scaffold-feature scanner
/scaffold-feature bookmarks all
/scaffold-feature profile presentation
/scaffold-feature search data,domain
```

## Process

1. **Parse feature name** and layers from command
2. **Generate directory structure** following Clean Architecture
3. **Create files** from appropriate templates
4. **Add proper imports** and part directives
5. **Include TODO comments** for implementation
6. **Generate test file templates**
7. **Show preview** before creating files

## Generated Structure

### Full Feature (all layers)

```
lib/features/{feature_name}/
├── data/
│   ├── {feature}_repository.dart        # Repository interface
│   └── impl/
│       └── {feature}_repository_impl.dart  # Repository implementation
├── domain/
│   └── usecases/
│       └── {action}_{entity}_use_case.dart  # Use case(s)
└── presentation/
    ├── {feature}_screen.dart           # Screen widget
    ├── {feature}_state.dart            # State class (Freezed)
    └── providers/
        └── {feature}_notifier.dart      # Riverpod notifier

test/
├── unit/
│   └── features/
│       └── {feature}/
│           ├── {feature}_repository_test.dart
│           ├── {feature}_use_case_test.dart
│           └── providers/
│               └── {feature}_notifier_test.dart
└── widget/
    └── features/
        └── {feature}/
            └── {feature}_screen_test.dart
```

### Data Layer Only

```
lib/features/{feature_name}/
└── data/
    ├── {feature}_repository.dart
    └── impl/
        └── {feature}_repository_impl.dart

test/unit/features/{feature}/
└── {feature}_repository_test.dart
```

### Domain Layer Only

```
lib/features/{feature_name}/
└── domain/
    └── usecases/
        └── {action}_{entity}_use_case.dart

test/unit/features/{feature}/
└── {feature}_use_case_test.dart
```

### Presentation Layer Only

```
lib/features/{feature_name}/
└── presentation/
    ├── {feature}_screen.dart
    ├── {feature}_state.dart
    └── providers/
        └── {feature}_notifier.dart

test/
├── unit/features/{feature}/providers/
│   └── {feature}_notifier_test.dart
└── widget/features/{feature}/
    └── {feature}_screen_test.dart
```

## Templates

### Repository Interface

```dart
/// Repository interface for {{FeatureName}}
abstract class {{FeatureName}}Repository {
  /// {{Method description}}
  Future<Result<{{ReturnType}}>>> {{methodName}}({{params}});
}
```

### Repository Implementation

```dart
/// Repository implementation for {{FeatureName}}
class {{FeatureName}}RepositoryImpl implements {{FeatureName}}Repository {
  const {{FeatureName}}RepositoryImpl();

  @override
  Future<Result<{{ReturnType}}>>> {{methodName}}({{params}}) {
    // TODO: Implement repository logic
    throw UnimplementedError();
  }
}
```

### Use Case

```dart
/// Use case for {{action}}
class {{Action}}{{Entity}}UseCase {
  const {{Action}}{{Entity}}UseCase(this._repository);

  final {{FeatureName}}Repository _repository;

  Future<Result<{{ReturnType}}>>> call({{params}}) {
    return _repository.{{methodName}}({{args}});
  }
}
```

### Screen Widget

```dart
/// Screen for {{FeatureName}}
class {{FeatureName}}Screen extends ConsumerWidget {
  const {{FeatureName}}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({{featureName}}NotifierProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref, state),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('{{Feature Title}}'),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, {{StateType}} state) {
    return state.when(
      initial: () => const _InitialView(),
      loading: () => const _LoadingView(),
      data: (data) => _DataView(data: data),
      error: (error) => _ErrorView(error: error),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) => const Placeholder();
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(),
  );
}

class _DataView extends StatelessWidget {
  const _DataView({required this.data});

  final DataType data;

  @override
  Widget build(BuildContext context) => Placeholder();
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => Center(
    child: Text('Error: $error'),
  );
}
```

## After Generation

After scaffolding, you should:

1. **Generate state and notifier**:
   ```bash
   /model-generator {FeatureName}State --with-notifier
   ```

2. **Generate tests**:
   ```bash
   /test-generator repository {feature}
   /test-generator notifier {feature}
   /test-generator widget {feature}_screen
   ```

3. **Implement business logic**:
   - Fill in repository methods
   - Implement use cases
   - Add notifier methods
   - Build UI widgets

4. **Run code generation**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Validate**:
   ```bash
   /code-review lib/features/{feature}/
   /pre-commit
   ```

## Dependencies

- Reads architecture patterns from `.claude/rules/architecture.md`
- Follows naming conventions from `.claude/rules/code-style.md`
- Uses existing feature structures as reference
- Generates test-ready code templates

## Related Skills

- `/model-generator` - Generate state and notifier after scaffolding
- `/test-generator` - Generate tests for scaffolded files
- `/code-review` - Review generated scaffold
- `/pre-commit` - Validate before committing

## Troubleshooting

**Issue**: Feature directory already exists
- **Solution**: Use a different feature name or remove existing directory

**Issue**: Generated files have compilation errors
- **Solution**: Run `flutter pub get` to ensure dependencies are available

**Issue**: Test files reference non-existent classes
- **Solution**: Implement the classes first, then run tests

**Issue**: Import paths are incorrect
- **Solution**: Verify project structure matches generated paths

## Best Practices

1. **Plan before scaffolding**: Know what layers you need
2. **Scaffold minimal layers first**: Start with what you need, add more later
3. **Review generated files**: Check TODO comments and fill them in
4. **Run code review early**: Catch architectural issues before implementing
5. **Generate tests alongside**: Write tests as you implement features

## Example Workflow

### Creating a Complete Feature

```bash
# 1. Scaffold full feature
/scaffold-feature scanner all

# 2. Generate state and notifier
/model-generator ScannerState --with-notifier

# 3. Generate repository implementation
# Edit: lib/features/scanner/data/impl/scanner_repository_impl.dart

# 4. Generate notifier methods
# Edit: lib/features/scanner/presentation/providers/scanner_notifier.dart

# 5. Build UI
# Edit: lib/features/scanner/presentation/scanner_screen.dart

# 6. Generate tests
/test-generator repository scanner
/test-generator notifier scanner
/test-generator widget scanner_screen

# 7. Validate
/code-review lib/features/scanner/
/pre-commit
```

## Customization

### Add Custom Use Cases

After scaffolding, add custom use cases:

```bash
# Scaffold domain layer only
/scaffold-feature scanner domain

# Manually add use case files
# lib/features/scanner/domain/usecases/scan_document_use_case.dart
```

### Add Custom Screens

```bash
# Scaffold presentation layer only
/scaffold-feature scanner presentation

# Add additional screens
# lib/features/scanner/presentation/scanner_settings_screen.dart
```

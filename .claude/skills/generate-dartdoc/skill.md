# Generate Dartdoc

Generate comprehensive API documentation using dartdoc with best practices for AI agent scanning.

## What It Does

Generates API documentation for the entire codebase using Dart's built-in `dart doc` tool with optimizations for both human reading and AI agent parsing.

## When to Use

- Before committing significant API changes
- Before releasing a new version
- When setting up the project for a new developer
- When AI agents need to understand the codebase API
- For generating reference documentation

## Options

```bash
/generate-dartdoc                    # Generate HTML documentation (default)
/generate-dartdoc --json            # Generate JSON for AI parsing
/generate-dartdoc --validate        # Validate documentation completeness
/generate-dartdoc --verbose         # Show detailed generation output
/generate-dartdoc --open            # Open docs in browser after generation
```

## What Gets Generated

### Primary Output (`dartdoc/` directory)
- **HTML format**: Human-readable API documentation with navigation
- **JSON format**: Machine-readable API specification for AI tools
- **index.md**: AI-friendly summary with quick links and patterns
- **manifest.json**: JSON manifest for AI agent discovery

### Documented APIs
- All public classes, methods, and properties
- Core data models (`PdfDocument`, `AppSettings`, etc.)
- Repository interfaces and implementations
- Services (`PdfIntentHandler`, `ThumbnailService`, etc.)
- Feature modules (Library, Reader, Settings, etc.)

### Excluded from Documentation
- Generated files (`*.g.dart`, `*.freezed.dart`)
- Internal implementation details
- Private members

## Best Practices Applied

1. **Clean output**: Removes old documentation before generating
2. **Organized categories**: Groups APIs by core, features, and data
3. **AI-friendly**: Generates index and manifest for easy scanning
4. **Validation**: Optionally checks for undocumented public APIs
5. **Multiple formats**: HTML for humans, JSON for machines

## Workflow Integration

### Pre-commit Workflow
Consider running this before pushing significant changes:

```bash
# Generate documentation
/generate-dartdoc

# Commit the updated docs
git add dartdoc/
git commit -m "docs: update API documentation"
```

### CI/CD Integration
Add to your CI pipeline:

```yaml
# .github/workflows/docs.yml
- name: Generate API docs
  run: .claude/scripts/generate-dartdoc.sh --json

- name: Upload documentation
  uses: actions/upload-artifact@v3
  with:
    name: api-docs
    path: dartdoc/
```

## Documentation Quality

For best results, ensure your code has:
- Documentation comments on all public APIs
- `///` style for doc comments
- Examples in doc comments where helpful
- `@throws` annotations for exceptions
- `@seealso` for related APIs

Example:
```dart
/// Loads all PDF documents from local storage.
///
/// Returns a [Result] containing either a list of [PdfDocument]
/// on success, or an [AppFailure] on error.
///
/// Example:
/// ```dart
/// final result = await repository.getAllPdfs();
/// result.when(
///   success: (pdfs) => print('Found ${pdfs.length}'),
///   failure: (error) => print('Error: $error'),
/// );
/// ```
///
/// Throws nothing - all errors are wrapped in Result.
///
/// @seealso [getPdfById] for loading a single PDF
Future<Result<List<PdfDocument>>> getAllPdfs();
```

## Troubleshooting

**"dart: command not found"**
- Ensure Dart SDK is installed and in PATH
- Run `flutter doctor` to verify installation

**"No documentation generated"**
- Check that you have public APIs to document
- Verify your lib directory exists
- Run with `--verbose` to see detailed output

**"Documentation looks incomplete"**
- Add documentation comments to public APIs
- Run with `--validate` to find undocumented members
- Consider adding `public_member_api_docs` lint to analysis_options.yaml

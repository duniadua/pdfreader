# Pre-commit Validator

Run all validation checks before committing, following `.claude/rules/git-workflow.md`.

## Purpose

Manual pre-commit validation is repetitive and error-prone. This skill automates:
- Code formatting checks
- Analyzer validation
- Test execution
- Coverage verification
- TODO/FIXME detection
- Build runner status
- Clear pass/fail reporting

**Token Savings**: ~94% (from ~800 to ~50 tokens per commit cycle)

## Usage

```bash
/pre-commit [--fix] [--filter=checks]
```

**Options**:
- `--fix` - Run auto-fix commands (dart format, dart fix)
- `--filter=checks` - Run specific checks only (comma-separated)
  - Available checks: format, analyze, test, coverage, todos, build_runner

**Examples**:
```bash
/pre-commit              # Run all checks
/pre-commit --fix        # Run + auto-fix issues
/pre-commit --filter=format,analyze  # Run specific checks only
```

## Validation Checks

### 1. Format Check
```bash
dart format --output=none --set-exit-if-changed .
```

**What it checks**: Code formatting according to Dart style guide

**Auto-fix**: `dart format .`

### 2. Analyzer Check
```bash
flutter analyze --fatal-infos
```

**What it checks**: Dart analyzer issues, warnings, and errors

**Auto-fix**: `dart fix --apply`

### 3. Test Execution
```bash
flutter test
```

**What it checks**: All unit and widget tests pass

**Auto-fix**: None (manual fixes required)

### 4. Test Coverage
```bash
flutter test --coverage
```

**What it checks**: Test coverage is adequate (target: 80%)

**Auto-fix**: None (manual fixes required)

### 5. TODO/FIXME Check
```bash
grep -r "TODO\|FIXME" lib/ --include="*.dart" | grep -v "// TODO:"
```

**What it checks**: No new TODOs or FIXMEs in committed code

**Auto-fix**: None (manual fixes required)

### 6. Build Runner Check
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**What it checks**: Generated code is up to date if models changed

**Auto-fix**: `flutter pub run build_runner build --delete-conflicting-outputs`

## Output Format

### All Checks Passed

```markdown
## ✅ Pre-commit Validation

### Summary
All checks passed! Ready to commit 🚀

### Checks Passed ✅
- ✅ Code formatted correctly
- ✅ No analyzer issues (0 warnings, 0 errors)
- ✅ All tests passing (15/15)
- ✅ Coverage: 87% (target: 80%)
- ✅ No new TODOs/FIXMEs
- ✅ Build runner up to date

### Ready to Commit
Run:
```bash
git add .
git commit -m "your commit message"
```
```

### Checks Failed

```markdown
## ❌ Pre-commit Validation Failed

### Summary
3 issues found. Fix and re-run.

### Issues Found

#### ❌ Format Check
**Issue**: 3 files need formatting
**Files**:
- lib/features/reader/presentation/reader_screen.dart
- lib/features/library/presentation/library_notifier.dart
- lib/core/data/models/pdf_document.dart

**Auto-fix Available**:
```bash
dart format .
```

#### ⚠️ Analyzer Check
**Issue**: 2 analyzer warnings
**Warnings**:
1. lib/features/reader/presentation/providers/pdf_chat_notifier.dart:145
   - Prefer const constructors
2. lib/features/library/presentation/library_screen.dart:67
   - Unused import: 'package:flutter/material.dart'

**Auto-fix Available**:
```bash
dart fix --apply
```

#### ❌ Test Coverage
**Issue**: Coverage below target (72% < 80%)
**Suggestion**: Add tests for:
- lib/features/scanner/presentation/scanner_notifier.dart
- lib/core/data/repositories/pdf_repository.dart

**Manual Fixes Required**: Add tests to increase coverage

### Auto-Fix Commands
```bash
# Fix formatting
dart format .

# Fix analyzer issues
dart fix --apply

# Re-run checks
/pre-commit
```

### Manual Fixes Required
1. Add tests for scanner_notifier.dart
2. Add tests for pdf_repository.dart
3. Re-run `/pre-commit` after fixes
```

### Partial Success (Warnings)

```markdown
## ⚠️ Pre-commit Validation (Warnings)

### Checks Passed ✅
- ✅ Code formatted correctly
- ✅ All tests passing (15/15)
- ✅ No new TODOs/FIXMEs

### Warnings ⚠️
- ⚠️ Coverage: 78% (target: 80%, close but not quite)
- ⚠️ 1 analyzer warning (non-blocking):
  lib/feature/presentation/screen.dart:123 - Unused variable

### Suggested Improvements
- Add 1-2 more tests to reach 80% coverage
- Remove unused variable

### Can Proceed
You can commit if these warnings are acceptable:
```bash
git add .
git commit -m "your message"
```

Or run `/pre-commit --fix` to auto-fix what's possible.
```

## Process

1. **Run all checks** in parallel (when possible)
2. **Collect results** from each check
3. **Generate report** with clear pass/fail status
4. **Provide auto-fix commands** when available
5. **Suggest manual fixes** for issues requiring attention

## Integration with Git Hooks

### Recommended Git Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run pre-commit validation
echo "Running pre-commit checks..."
claude /pre-commit

# Check exit code
if [ $? -ne 0 ]; then
  echo "❌ Pre-commit checks failed. Commit aborted."
  echo "Run '/pre-commit --fix' to auto-fix issues."
  exit 1
fi

echo "✅ All checks passed. Proceeding with commit."
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Integration with settings.json

The skill can integrate with existing hooks:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Commit",
        "hooks": [
          {
            "type": "skill",
            "skill": "pre-commit",
            "statusMessage": "Running pre-commit validation..."
          }
        ]
      }
    ]
  }
}
```

## Caching

Check results are cached in `.claude/pre-commit-cache.json`:

```json
{
  "last_run": "2025-04-01T10:30:00Z",
  "format": {
    "status": "passed",
    "files_hash": "abc123"
  },
  "analyze": {
    "status": "passed",
    "issues_count": 0
  },
  "test": {
    "status": "passed",
    "test_count": 15,
    "failed_count": 0
  },
  "coverage": {
    "status": "passed",
    "percentage": 87
  }
}
```

Cache is invalidated when:
- Files change (detected by git status)
- 1 hour has passed since last check
- Manual cache clear with `--no-cache` flag

## Dependencies

- Uses Flutter CLI for formatting and analysis
- Uses test framework for running tests
- Integrates with existing git workflow
- Follows git-workflow.md from `.claude/rules/`

## Related Skills

- `/code-review` - Deep dive into code quality issues
- `/test-generator` - Create tests to improve coverage
- `/model-generator` - Generate code that passes checks
- `/scaffold-feature` - Generate compliant feature structure

## Troubleshooting

**Issue**: Checks are slow
- **Solution**: Use `--filter` to run only specific checks

**Issue**: False positives from analyzer
- **Solution**: Run `flutter analyze` manually to see full output

**Issue**: Test coverage calculation is wrong
- **Solution**: Run `flutter test --coverage` and check `coverage/lcov.info`

**Issue**: Build runner keeps failing
- **Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

## Best Practices

1. **Run before every commit**: Make it a habit to run `/pre-commit`
2. **Use --fix for auto-fixes**: Save time with automated fixes
3. **Review warnings**: Even if checks pass, review warnings
4. **Keep tests updated**: Maintain test coverage above 80%
5. **Clean up TODOs**: Resolve TODOs before committing

## Example Workflow

### Typical Commit Cycle

```bash
# 1. Make code changes
# ... edit files ...

# 2. Run pre-commit
/pre-commit

# 3. If issues found, auto-fix
/pre-commit --fix

# 4. Fix manual issues
# ... edit files ...

# 5. Re-run validation
/pre-commit

# 6. Commit
git add .
git commit -m "feat: add new feature"
```

### Quick Check (Specific Checks Only)

```bash
# Check formatting only (fast)
/pre-commit --filter=format

# Check tests only
/pre-commit --filter=test

# Check formatting and analyzer
/pre-commit --filter=format,analyze
```

### Force Commit (Skip Checks)

If you need to skip pre-commit checks:

```bash
git commit --no-verify -m "message"
```

Use sparingly and only when necessary.

## Performance Tips

- **Parallel execution**: Multiple checks run simultaneously
- **Smart filtering**: Only run checks for changed file types
- **Caching**: Results cached for 1 hour
- **Incremental**: Only affected tests run when possible

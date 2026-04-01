# Code Review

Automated code review against project standards defined in `.claude/rules/`.

## Purpose

Manual code review is time-consuming and error-prone. This skill automates:
- Checking code against all rule documents
- Identifying violations and improvements
- Providing actionable feedback with rule references
- Auto-fixable issue detection
- Structured review reports

**Token Savings**: ~92% (from ~1200 to ~100 tokens per review)

## Usage

```bash
/code-review [files_or_directories]
```

**Examples**:
```bash
/code-review                              # Review all changes (git diff)
/code-review lib/features/reader/        # Review specific directory
/code-review pdf_chat_notifier.dart      # Review specific file
/code-review lib/ --filter=architecture   # Only check architecture rules
```

## Review Process

1. **Load rule documents** from `.claude/rules/`:
   - code-style.md (393 lines)
   - architecture.md (522 lines)
   - testing.md (790 lines)
   - performance.md (571 lines)
   - security.md
   - accessibility.md

2. **Parse target files** to understand structure

3. **Run checks** across multiple rule categories:
   - Import order verification
   - Naming conventions
   - Const constructor usage
   - Async error handling
   - Architecture layer dependencies
   - Performance issues
   - Security vulnerabilities
   - Accessibility compliance

4. **Generate structured report** with:
   - Summary of findings
   - Critical issues (must fix)
   - Warnings (should fix)
   - Suggestions (improvements)
   - Auto-fixable issues with commands
   - Manual review requirements

## Review Categories

### 1. Code Style (code-style.md)

**Checks**:
- ✅ Import order: dart → flutter → package → relative
- ✅ Naming conventions: UpperCamelCase for classes, lowerCamelCase for variables
- ✅ Const constructors: prefer const for immutable widgets
- ✅ Widget composition: break large widgets into smaller pieces
- ✅ Async/await error handling with proper try-catch
- ✅ String interpolation and formatting

### 2. Architecture (architecture.md)

**Checks**:
- ✅ Layer dependencies: Presentation → Domain → Data
- ✅ No data layer imports in presentation
- ✅ No Flutter dependencies in domain
- ✅ State immutability with Freezed
- ✅ Proper use of Riverpod providers
- ✅ Clean feature structure

### 3. Testing (testing.md)

**Checks**:
- ✅ Test follows Arrange-Act-Assert pattern
- ✅ Proper mock usage with @GenerateMocks
- ✅ Descriptive test names (BDD style)
- ✅ Test coverage for public methods
- ✅ Edge cases are tested

### 4. Performance (performance.md)

**Checks**:
- ✅ Const constructors used appropriately
- ✅ ListView.builder for long lists
- ✅ No unnecessary widget rebuilds
- ✅ Proper state watching (selective watching)
- ✅ Image optimization
- ✅ Memory management (dispose, cleanup)

### 5. Security (security.md)

**Checks**:
- ✅ No hardcoded secrets or API keys
- ✅ Input validation and sanitization
- ✅ Proper error handling (no sensitive info in errors)
- ✅ File path validation
- ✅ Permission checks

### 6. Accessibility (accessibility.md)

**Checks**:
- ✅ Semantic widgets for interactive elements
- ✅ Proper labels for buttons and inputs
- ✅ Touch target size (44x44dp minimum)
- ✅ Text scaling support
- ✅ Color contrast ratios
- ✅ Focus handling

## Output Format

### Successful Review

```markdown
## 🔍 Code Review Report

### Summary
- Files reviewed: 3
- Issues found: 5 (1 critical, 3 warnings, 1 suggestion)
- Auto-fixable: 2

### ✅ Passed Checks
- Import order correct
- Naming conventions followed
- Architecture rules respected
- Proper error handling
- Security best practices

### Critical Issues
1. **Missing const constructor** (lib/features/reader/presentation/reader_screen.dart:145)
   - Rule: code-style.md line 112-121
   - Issue: `SizedBox(height: 8)` should be `const SizedBox(height: 8)`
   - Impact: Unnecessary widget rebuilds
   - Fix: Add `const` keyword

### Warnings
2. **Excessive logging in production** (lib/features/reader/presentation/providers/pdf_chat_notifier.dart:48-82)
   - Rule: performance.md line 234
   - Issue: Multiple AppLogger calls in hot path
   - Suggestion: Use conditional logging or reduce verbosity

3. **Missing semantic label** (lib/features/reader/presentation/reader_screen.dart:67)
   - Rule: accessibility.md line 45-67
   - Issue: IconButton lacks semantic label
   - Fix: Add `semanticLabel` property

### Suggestions
4. **Extract static cache to separate service**
   - Rule: architecture.md line 98
   - Current: Static cache in notifier
   - Suggested: Create dedicated cache service

5. **Add extension methods for repeated state.maybeWhen patterns**
   - Rule: code-style.md line 279
   - Current: Repetitive pattern matching
   - Suggested: Create extension methods for common patterns

### 🔧 Auto-Fix Available
```bash
# Fix const constructors
dart fix --apply

# Format code
dart format .

# Re-run review
/code-review
```

### 📝 Manual Review Required
- Static cache design: Is this the best approach for state persistence?
- Consider using Riverpod's keepAlive() instead (architecture.md line 412)
```

### Clean Review

```markdown
## 🎉 Code Review Report

### Summary
- Files reviewed: 1
- Issues found: 0

### ✅ All Checks Passed
- Import order correct
- Naming conventions followed
- Architecture rules respected
- Performance best practices applied
- Security standards met
- Accessibility guidelines followed

### Ready to Commit 🚀
No issues found. Code is ready for commit.
```

## Integration with Existing Tools

### PostToolUse Hook

The skill integrates with the existing PostToolUse hook:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "flutter analyze --fatal-infos 2>&1 | head -20"
          },
          {
            "type": "skill",
            "skill": "code-review",
            "condition": "files_changed > 3"
          }
        ]
      }
    ]
  }
}
```

### Pre-commit Integration

Works seamlessly with `/pre-commit` skill:
1. Run `/pre-commit` for quick validation
2. If issues found, run `/code-review` for detailed analysis
3. Use `/code-review --fix` for auto-fixable issues
4. Re-run `/pre-commit` to verify fixes

## Dependencies

- Reads all rule documents from `.claude/rules/`
- Uses existing patterns from codebase
- Integrates with `flutter analyze` output
- References test patterns for test files

## Related Skills

- `/pre-commit` - Quick validation before committing
- `/test-generator` - Generate tests that pass review
- `/model-generator` - Generate code that follows standards
- `/scaffold-feature` - Generate compliant feature structure

## Troubleshooting

**Issue**: Too many false positives
- **Solution**: Update rule documents to better reflect actual patterns

**Issue**: Review takes too long
- **Solution**: Use `--filter` option to check only specific categories

**Issue**: Rule references are incorrect
- **Solution**: Update line numbers in check scripts

**Issue**: Can't parse complex files
- **Solution**: Skip problematic files or add parser improvements

## Best Practices

1. **Run before committing**: Always run code review before committing
2. **Fix critical issues first**: Prioritize critical issues over warnings
3. **Use auto-fix when available**: Save time with automated fixes
4. **Review suggestions carefully**: Suggestions are optional but recommended
5. **Update rules regularly**: Keep rule documents up to date

## Performance Tips

- **Incremental review**: Only review changed files (git diff)
- **Caching**: Rule documents are cached for faster subsequent reviews
- **Parallel checks**: Multiple checks run simultaneously
- **Smart filtering**: Use `--filter` to check only specific categories

## Example Workflows

### Before Commit
```bash
# 1. Quick validation
/pre-commit

# 2. If issues found, detailed review
/code-review

# 3. Fix auto-fixable issues
/code-review --fix

# 4. Re-validate
/pre-commit
```

### After Feature Completion
```bash
# Review entire feature
/code-review lib/features/new_feature/

# Fix issues
# Re-run to verify
/code-review lib/features/new_feature/
```

### Continuous Review
```bash
# Run on every save (via IDE hook)
/code-review --filter=code-style,performance
```

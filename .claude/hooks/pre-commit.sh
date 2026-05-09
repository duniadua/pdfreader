#!/bin/bash
# Pre-commit hook untuk Git
# Validasi code quality sebelum commit

set -e  # Exit on error

PROJECT_DIR="/Users/macbook/testclaude"
cd "$PROJECT_DIR"

echo "🔍 Running pre-commit validation..."
echo ""

# 1. Format Check
echo "📝 Checking code format..."
FORMAT_RESULT=$(dart format --set-exit-if-changed . 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ Code formatting issues found!"
    echo "$FORMAT_RESULT"
    echo ""
    echo "Run: dart format ."
    exit 1
fi
echo "✅ Code format OK"
echo ""

# 2. Flutter Analyze
echo "🔧 Running flutter analyze..."
ANALYZE_RESULT=$(flutter analyze 2>&1)
ANALYZE_EXIT=$?
if [ $ANALYZE_EXIT -ne 0 ]; then
    echo "❌ Flutter analyze found issues!"
    echo "$ANALYZE_RESULT"
    echo ""
    exit 1
fi
echo "✅ Flutter analyze OK"
echo ""

# 3. Build Runner Check
echo "🏗️ Checking code generation..."
BUILD_RUNNER_CHECK=true
find "$PROJECT_DIR/lib" -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" | while read -r file; do
    if grep -qE "@freezed|@riverpod|@JsonSerializable" "$file" 2>/dev/null; then
        BASENAME="${file%.dart}"
        G_FILE="${BASENAME}.g.dart"
        if [ -f "$G_FILE" ]; then
            SOURCE_MTIME=$(stat -f%m "$file" 2>/dev/null)
            G_MTIME=$(stat -f%m "$G_FILE" 2>/dev/null)
            if [ -n "$SOURCE_MTIME" ] && [ -n "$G_MTIME" ] && [ "$SOURCE_MTIME" -gt "$G_MTIME" ]; then
                echo "❌ Model changed without regenerating: $file"
                BUILD_RUNNER_CHECK=false
            fi
        fi
    fi
done

if [ "$BUILD_RUNNER_CHECK" = false ]; then
    echo ""
    echo "Run: flutter pub run build_runner build"
    exit 1
fi
echo "✅ Code generation OK"
echo ""

# 4. Test (quick - unit tests only)
echo "🧪 Running unit tests..."
TEST_RESULT=$(flutter test test/unit/ 2>&1)
TEST_EXIT=$?
if [ $TEST_EXIT -ne 0 ]; then
    echo "❌ Some tests failed!"
    echo "$TEST_RESULT"
    echo ""
    exit 1
fi
echo "✅ All tests passed"
echo ""

# 5. Check for TODO/FIXME in changed files
echo "📋 Checking for unresolved TODOs..."
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep "\.dart$")
TODO_COUNT=0
for file in $CHANGED_FILES; do
    if [ -f "$file" ]; then
        TODOS=$(grep -nE "TODO|FIXME|HACK|XXX" "$file" 2>/dev/null || true)
        if [ -n "$TODOS" ]; then
            echo "⚠️  Found in $file:"
            echo "$TODOS"
            TODO_COUNT=$((TODO_COUNT + 1))
        fi
    fi
done

if [ $TODO_COUNT -gt 0 ]; then
    echo ""
    echo "⚠️  Found unresolved TODOs/FIXMEs in changed files"
    echo "Consider resolving them before committing."
    # Warning only, not blocking
fi
echo ""

# All checks passed
echo "✅✅✅ Pre-commit validation PASSED ✅✅✅"
echo ""
exit 0

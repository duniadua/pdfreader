#!/bin/bash
# Posthook untuk SessionEnd
# Tampilkan summary development session

PROJECT_DIR="/Users/macbook/testclaude"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Development Session Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Git status
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    echo ""
    echo "📁 Git Status:"
    git -C "$PROJECT_DIR" status -s

    # Count changes
    ADDED=$(git -C "$PROJECT_DIR" diff --name-only --cached | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$PROJECT_DIR" diff --name-only | wc -l | tr -d ' ')

    if [ "$ADDED" -gt 0 ] || [ "$MODIFIED" -gt 0 ]; then
        echo ""
        echo "   Changed files: $((ADDED + MODIFIED))"
        echo "   Staged: $ADDED | Modified: $MODIFIED"
    fi
fi

# Check uncommitted generated files
echo ""
echo "🔧 Generated Files:"
UNCOMMITTED_G=$(find "$PROJECT_DIR/lib" -name "*.g.dart" -newer "$PROJECT_DIR/pubspec.yaml" 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED_G" -gt 0 ]; then
    echo "   ⚠️  $UNCOMMITTED_G generated file(s) may need commit"
else
    echo "   ✅ All generated files up to date"
fi

# Flutter analyze quick check
echo ""
echo "🔍 Code Health:"
cd "$PROJECT_DIR" || exit 0

if command -v flutter &> /dev/null; then
    ISSUES=$(flutter analyze --no-pub 2>&1 | grep -E "warning|error|hint" | wc -l | tr -d ' ')
    if [ "$ISSUES" -eq 0 ]; then
        echo "   ✅ No analyzer issues"
    else
        echo "   ⚠️  $ISSUES issue(s) found - run 'flutter analyze'"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Happy coding! 🚀"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0

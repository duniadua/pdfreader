#!/bin/bash
# Pre-git-push hook
# Double check sebelum push ke remote

set -e

PROJECT_DIR="/Users/macbook/testclaude"
cd "$PROJECT_DIR"

echo "🚀 Pre-git-push validation..."
echo ""

# Get current branch and remote info
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
REMOTE_NAME="${1:-origin}"
REMOTE_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || echo "unknown")

echo "📍 Push details:"
echo "   Branch: $CURRENT_BRANCH"
echo "   Remote: $REMOTE_NAME"
echo "   URL: $REMOTE_URL"
echo ""

# 1. Check uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
    echo "⚠️  You have $UNCOMMITTED uncommitted change(s):"
    git status --short
    echo ""
    echo "Run: git status"
    read -p "Continue anyway? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi
echo ""

# 2. Check if pushing to main/master - extra caution
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    echo "⚠️  ⚠️  ⚠️  WARNING ⚠️  ⚠️  ⚠️"
    echo "You are about to push to $CURRENT_BRANCH!"
    echo ""
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi
echo ""

# 3. Show commits to be pushed
echo "📋 Commits to be pushed:"
git log "$REMOTE_NAME/$CURRENT_BRANCH..HEAD" --oneline 2>/dev/null || echo "   (no previous commits on remote)"
echo ""

# 4. Check for sensitive data
echo "🔒 Checking for sensitive data..."
SENSITIVE_FILES=$(git diff --cached --name-only | grep -iE "(key|secret|password|token|credential|\.env|api_key)" 2>/dev/null || true)
if [ -n "$SENSITIVE_FILES" ]; then
    echo "❌ Potential sensitive files detected:"
    echo "$SENSITIVE_FILES"
    echo ""
    echo "These files may contain secrets!"
    read -p "Continue anyway? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi
echo ""

# 5. Check for large files (>5MB)
echo "📦 Checking for large files..."
LARGE_FILES=$(git diff --cached --name-only -z | xargs -0 -I{} sh -c 'size=$(stat -f%z "{}" 2>/dev/null || stat -c%s "{}" 2>/dev/null); if [ "$size" -gt 5242880 ]; then echo "{}"; fi' 2>/dev/null || true)
if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Large files detected (>5MB):"
    echo "$LARGE_FILES"
    echo ""
    read -p "Continue anyway? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi
echo ""

# 6. Check for firebase config
FIREBASE_CONFIG=$(git diff --cached --name-only | grep -iE "google-services\.json|firebase.*\.json" 2>/dev/null || true)
if [ -n "$FIREBASE_CONFIG" ]; then
    echo "⚠️  Firebase config file detected in changes!"
    echo "$FIREBASE_CONFIG"
    echo ""
    read -p "Make sure this is intentional (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi
echo ""

# 7. Run quick flutter analyze
echo "🔧 Quick analyze check..."
ANALYZE_EXIT=0
flutter analyze --no-fatal-infos --no-fatal-warnings > /dev/null 2>&1 || ANALYZE_EXIT=$?
if [ $ANALYZE_EXIT -ne 0 ]; then
    echo "⚠️  Flutter analyze found issues"
    echo "Consider fixing before pushing"
    read -p "Continue anyway? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Push cancelled"
        exit 1
    fi
fi
echo ""

# All checks passed
echo "✅✅✅ Pre-git-push validation PASSED ✅✅✅"
echo ""
exit 0

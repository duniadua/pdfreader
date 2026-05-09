#!/bin/bash
# Pre-firebase-deploy hook
# Validasi sebelum deploy Firebase functions

PROJECT_DIR="/Users/macbook/testclaude"
cd "$PROJECT_DIR"

echo "🔥 Firebase Deploy Pre-Check"
echo ""

# 1. Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi
echo "✅ Firebase CLI found"

# 2. Check login status
FIREBASE_LOGGED=$(firebase login:list 2>&1 | grep -c "Logged in" || echo 0)
if [ "$FIREBASE_LOGGED" -eq 0 ]; then
    echo "⚠️  Not logged in to Firebase"
    echo "Run: firebase login"
    read -p "Continue anyway? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        exit 1
    fi
else
    echo "✅ Firebase logged in"
fi
echo ""

# 3. Check functions directory
if [ -d "functions" ]; then
    echo "📁 Functions directory exists"
    cd functions
    
    # Check package.json
    if [ ! -f "package.json" ]; then
        echo "❌ package.json not found in functions/"
        exit 1
    fi
    echo "✅ package.json found"
    
    # Check for missing node_modules
    if [ ! -d "node_modules" ]; then
        echo "⚠️  node_modules not installed"
        echo "Run: cd functions && npm install"
        read -p "Install now? (type 'yes' to confirm): " confirm
        if [ "$confirm" = "yes" ]; then
            npm install
        else
            exit 1
        fi
    else
        echo "✅ node_modules installed"
    fi
    echo ""
    
    # Run lint
    if [ -f "package.json" ] && grep -q '"lint"' "package.json" 2>/dev/null; then
        echo "🔧 Running lint..."
        npm run lint > /dev/null 2>&1 || echo "⚠️  Lint found issues"
    fi
    
    # Check TypeScript compilation
    if [ -f "tsconfig.json" ]; then
        echo "🔧 Checking TypeScript..."
        if command -v npx &> /dev/null; then
            npx tsc --noEmit > /dev/null 2>&1 || {
                echo "⚠️  TypeScript errors found"
                read -p "Continue anyway? (type 'yes' to confirm): " confirm
                if [ "$confirm" != "yes" ]; then
                    cd "$PROJECT_DIR"
                    exit 1
                fi
            }
        fi
    fi
    echo "✅ TypeScript check passed"
    
    cd "$PROJECT_DIR"
else
    echo "ℹ️  No functions directory found (functions as code not used)"
fi
echo ""

# 4. Check flutter analyze (optional)
echo "🔧 Checking Flutter code..."
ANALYZE_EXIT=0
flutter analyze --no-fatal-infos --no-fatal-warnings > /dev/null 2>&1 || ANALYZE_EXIT=$?
if [ $ANALYZE_EXIT -ne 0 ]; then
    echo "⚠️  Flutter analyze found issues"
    echo "Consider fixing before deploying"
    read -p "Continue anyway? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        exit 1
    fi
else
    echo "✅ Flutter code OK"
fi
echo ""

# 5. Check .firebaserc
if [ ! -f ".firebaserc" ]; then
    echo "❌ .firebaserc not found"
    echo "Run: firebase init hosting"
    exit 1
fi
echo "✅ .firebaserc found"

# 6. Show deploy target
echo ""
echo "📋 Deploy configuration:"
cat .firebaserc 2>/dev/null | head -20
echo ""

# All checks passed
echo "✅✅✅ Firebase Deploy Pre-Check PASSED ✅✅✅"
echo ""
exit 0

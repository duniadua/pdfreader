#!/bin/bash
# Prehook untuk quality check
# Validasi code quality sebelum commit atau build

PROJECT_DIR="/Users/macbook/testclaude"

# Cek apakah ada perubahan model tanpa build_runner
echo "🔍 Checking for code generation issues..."

# Cari file .dart yang menggunakan @freezed/@riverpod
find "$PROJECT_DIR/lib" -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" | while read -r file; do
    # Cek apakah file menggunakan annotation yang perlu code generation
    if grep -qE "@freezed|@riverpod|@JsonSerializable" "$file" 2>/dev/null; then
        BASENAME="${file%.dart}"
        G_FILE="${BASENAME}.g.dart"

        # Cek apakah file .g.dart ada dan lebih lama dari source
        if [ -f "$G_FILE" ]; then
            # macOS stat comparison
            SOURCE_MTIME=$(stat -f%m "$file" 2>/dev/null)
            G_MTIME=$(stat -f%m "$G_FILE" 2>/dev/null)

            if [ -n "$SOURCE_MTIME" ] && [ -n "$G_MTIME" ] && [ "$SOURCE_MTIME" -gt "$G_MTIME" ]; then
                echo "⚠️  Model changed without regenerating:"
                echo "   $file"
                echo "   Run: flutter pub run build_runner build"
            fi
        else
            echo "⚠️  Missing generated file for:"
            echo "   $file"
            echo "   Run: flutter pub run build_runner build"
        fi
    fi
done

# Cek apakah ada file test yang hilang untuk feature baru
echo ""
echo "📝 Checking test coverage..."

# Cari file di lib/features/ yang belum punya test
find "$PROJECT_DIR/lib/features" -name "*_screen.dart" -o -name "*_notifier.dart" -o -name "*_state.dart" | while read -r file; do
    RELATIVE="${file#$PROJECT_DIR/lib/}"
    TEST_FILE="$PROJECT_DIR/test/$RELATIVE"

    if [ ! -f "$TEST_FILE" ]; then
        echo "ℹ️  Missing test file: $RELATIVE"
        echo "   Consider creating: test/$RELATIVE"
    fi
done

# Cek dependency violations (import dari layer yang salah)
echo ""
echo "🏗️  Checking architecture violations..."

# Cari import dari presentation ke data (clean architecture violation)
find "$PROJECT_DIR/lib/features" -path "*/presentation/*.dart" -not -name "*.g.dart" | while read -r file; do
    if grep -q "import.*\.\./\.\./data/" "$file" 2>/dev/null; then
        echo "⚠️  Architecture violation in: $file"
        echo "   Presentation layer should not import Data layer directly."
    fi
done

exit 0

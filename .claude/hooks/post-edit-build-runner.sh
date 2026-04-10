#!/bin/bash
# Posthook untuk Edit tool
# Jalankan build_runner jika file yang di-edit memerlukan code generation

FILE_PATH="$1"
PROJECT_DIR="/Users/macbook/testclaude"

# Cek apakah file yang di-edit menggunakan code generation
if [ -f "$FILE_PATH" ]; then
    # Cek annotation yang memerlukan code generation
    if grep -qE "@freezed|@riverpod|@JsonSerializable|@CopyWith" "$FILE_PATH" 2>/dev/null; then
        echo "🔧 Code generation detected, running build_runner..."

        # Jalankan build_runner dengan delete-conflicting-outputs
        cd "$PROJECT_DIR" || exit 0

        # Build di background untuk tidak blocking
        flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1 &

        echo "⏳ Code generation running in background..."
    fi
fi

exit 0

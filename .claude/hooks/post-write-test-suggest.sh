#!/bin/bash
# Posthook untuk Write tool
# Sarankan pembuatan test file untuk file baru

FILE_PATH="$2"
PROJECT_DIR="/Users/macbook/testclaude"

# Normalize path
if [ -z "$FILE_PATH" ]; then
    FILE_PATH="$1"
fi

# Hanya proses file di lib/
if [[ ! "$FILE_PATH" =~ ^lib/ ]]; then
    exit 0
fi

# Cek apakah file di lib/ dan belum ada test-nya
RELATIVE_PATH="${FILE_PATH#lib/}"
TEST_FILE="$PROJECT_DIR/test/$RELATIVE_PATH"

if [ ! -f "$TEST_FILE" ] && [ -f "$FILE_PATH" ]; then
    # Tentukan jenis file
    if [[ "$FILE_PATH" =~ (screen|notifier|state|usecase|repository|service)\.dart$ ]]; then
        echo ""
        echo "📝 Consider creating test file:"
        echo "   $TEST_FILE"
        echo ""
        echo "   Quick test template:"

        # Berikan template berdasarkan jenis file
        if [[ "$FILE_PATH" =~ _notifier\.dart$ ]]; then
            echo "   - Use ProviderContainer for testing"
            echo "   - Mock repositories with mockito"
        elif [[ "$FILE_PATH" =~ _screen\.dart$ ]]; then
            echo "   - Use WidgetTester"
            echo "   - PumpWidget with ProviderScope"
        elif [[ "$FILE_PATH" =~ _state\.dart$ ]]; then
            echo "   - Test state transitions"
            echo "   - Test copyWith and toJson"
        fi
    fi
fi

exit 0

#!/bin/bash
# Prehook untuk Write tool
# Cegah overwrite tidak sengaja dan validasi struktur

FILE_PATH="$2"

# Jika file_path tidak tersedia, gunakan argumen pertama
if [ -z "$FILE_PATH" ]; then
    FILE_PATH="$1"
fi

# Cek file di lib/features/ untuk struktur clean architecture
if [[ "$FILE_PATH" =~ ^lib/features/ ]]; then
    # Ekstrak feature name
    FEATURE=$(echo "$FILE_PATH" | sed -E 's|^lib/features/([^/]+)/.*$|\1|')

    # Validasi struktur folder untuk feature baru
    if [ ! -d "lib/features/$FEATURE" ]; then
        echo "📁 Creating new feature structure: $FEATURE"
        echo "   Suggested structure:"
        echo "   lib/features/$FEATURE/"
        echo "   ├── data/"
        echo "   ├── domain/"
        echo "   └── presentation/"
    fi
fi

# Cek duplikasi file di test/
if [[ "$FILE_PATH" =~ ^lib/ ]]; then
    RELATIVE_PATH="${FILE_PATH#lib/}"
    EXISTING_TEST="/Users/macbook/testclaude/test/$RELATIVE_PATH"

    if [ -f "$EXISTING_TEST" ]; then
        echo "ℹ️  Test file already exists: $EXISTING_TEST"
        echo "   Consider updating the existing test instead."
    fi
fi

# Validasi nama file untuk models (harus snake_case)
if [[ "$FILE_PATH" =~ ^lib/core/data/models/ ]] || [[ "$FILE_PATH" =~ ^lib/.*/data/models/ ]]; then
    FILENAME=$(basename "$FILE_PATH")
    if [[ ! "$FILENAME" =~ ^[a-z][a-z0-9_]*\.dart$ ]] && [[ "$FILENAME" != *.g.dart ]] && [[ "$FILENAME" != *.freezed.dart ]]; then
        echo "⚠️  Model filename should be snake_case: $FILENAME"
        echo "   Expected format: lower_case_with_underscores.dart"
    fi
fi

# Validasi nama file untuk presentation screens
if [[ "$FILE_PATH" =~ ^lib/.*/presentation/ ]]; then
    FILENAME=$(basename "$FILE_PATH")
    if [[ "$FILENAME" =~ ^[A-Z] ]] && [[ "$FILENAME" =~ [A-Z][a-z] ]]; then
        echo "⚠️  Presentation file should use snake_case: $FILENAME"
        echo "   Expected format: ${FILENAME,,}"
    fi
fi

exit 0

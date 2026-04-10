#!/bin/bash
# Posthook untuk Edit tool
# Auto format file yang di-edit

FILE_PATH="$1"
PROJECT_DIR="/Users/macbook/testclaude"

# Hanya format file .dart
if [[ "$FILE_PATH" =~ \.dart$ ]] && [ -f "$FILE_PATH" ]; then
    # Format file di background
    dart format "$FILE_PATH" > /dev/null 2>&1 &

    # Optional: Organize imports juga (gunakan dart fix atau plugin)
    # dart fix --apply "$FILE_PATH" > /dev/null 2>&1 &
fi

exit 0

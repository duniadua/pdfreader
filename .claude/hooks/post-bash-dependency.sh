#!/bin/bash
# Posthook untuk Bash tool
# Cek dependency changes dan beri notifikasi

COMMAND="$*"
PROJECT_DIR="/Users/macbook/testclaude"

# Jika command mengubah dependency
if echo "$COMMAND" | grep -qE "flutter pub (add|remove|upgrade)"; then
    echo ""
    echo "📦 Dependency changed!"
    echo "   Run 'flutter pub get' to fetch dependencies"
    echo "   Run 'flutter pub outdated' to check for updates"

    # Tampilkan dependency yang diubah
    if echo "$COMMAND" | grep -q "add"; then
        PACKAGE=$(echo "$COMMAND" | sed -E 's/.*flutter pub add ([^ ]*).*/\1/')
        echo "   Added: $PACKAGE"
    fi
fi

# Jika command berhubungan dengan git, tampilkan status
if echo "$COMMAND" | grep -qE "git (commit|add|status)"; then
    echo ""
    git -C "$PROJECT_DIR" status -s 2>/dev/null || true
fi

exit 0

#!/bin/bash
# Prehook untuk Read tool
# Validasi path dan batasi ukuran file

FILE_PATH="$1"

# Batasi membaca file terlalu besar (>5MB)
if [ -f "$FILE_PATH" ]; then
    # Gunakan stat yang compatible dengan macOS
    FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null)

    # Jika stat -f gagal (bukan macOS), coba stat -c (Linux)
    if [ -z "$FILE_SIZE" ]; then
        FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null)
    fi

    MAX_SIZE=$((5 * 1024 * 1024))  # 5MB

    if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
        SIZE_MB=$((FILE_SIZE / 1024 / 1024))
        echo "⚠️  File is large: ${SIZE_MB}MB"
        echo "   Reading may use significant context."
    fi
fi

# Cek sensitive files
SENSITIVE_PATTERNS=(
    "\.env$"
    "\.env\."
    "firebase\.json"
    "google-services\.json"
    "GoogleService-Info\.plist"
    "\.p12$"
    "\.keystore$"
    "\.jks$"
    "secrets\.yaml"
    "secret\.yaml"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        echo "🔒 Sensitive file detected: $FILE_PATH"
        echo "   Ensure no secrets are logged or shared."
    fi
done

# Warning untuk file generated
GENERATED_PATTERNS=(
    "\.g\.dart$"
    "\.freezed\.dart$"
    "\.mocks\.dart$"
)

for pattern in "${GENERATED_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        echo "🔧 Generated file: $FILE_PATH"
        echo "   This file is auto-generated. Changes may be overwritten."
    fi
done

exit 0

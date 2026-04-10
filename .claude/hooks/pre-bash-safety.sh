#!/bin/bash
# Prehook untuk Bash tool
# Cegah command berbahaya untuk project ini

COMMAND="$*"

# Daftar command yang berisiko untuk project ini
DANGEROUS_COMMANDS=(
    "rm -rf"
    "git reset --hard"
    "git push --force"
    "flutter clean"
    "rm -rf build/"
    "rm -rf .dart_tool/"
    "rm -rf node_modules/"
    "dd if="
    "> /dev/"
    "format disk"
    "mkfs."
)

# Cek apakah command mengandung pattern berbahaya
for dangerous in "${DANGEROUS_COMMANDS[@]}"; do
    if echo "$COMMAND" | grep -q "$dangerous"; then
        echo ""
        echo "⚠️  ⚠️  ⚠️  WARNING ⚠️  ⚠️  ⚠️"
        echo "Command detected: $dangerous"
        echo "This may delete important files or git history!"
        echo ""
        read -p "Continue anyway? (type 'yes' to confirm): " confirm

        if [ "$confirm" != "yes" ]; then
            echo "❌ Command cancelled by prehook"
            exit 1  # Batalkan eksekusi
        fi
        break
    fi
done

# Auto-add dependency tracking untuk pub get/add
if echo "$COMMAND" | grep -q "flutter pub"; then
    DEPENDENCY_LOG="/Users/macbook/testclaude/.claude/dependency-log.txt"
    echo "📦 Tracking dependency change..."
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $COMMAND" >> "$DEPENDENCY_LOG"
fi

exit 0

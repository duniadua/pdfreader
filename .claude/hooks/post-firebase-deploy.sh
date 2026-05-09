#!/bin/bash
# Post-firebase-deploy hook
# Notify dan log deploy result

set -e

PROJECT_DIR="/Users/macbook/testclaude"
DEPLOY_STATUS="$1"  # "success" or "failure"
DEPLOY_TARGET="${2:-hosting}"

cd "$PROJECT_DIR"

echo "🔥 Post-Firebase-Deploy Hook"
echo "   Status: $DEPLOY_STATUS"
echo "   Target: $DEPLOY_TARGET"
echo ""

# Log deploy
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/firebase_deploy_$TIMESTAMP.log"

{
    echo "Firebase Deploy Log"
    echo "==================="
    echo "Timestamp: $(date)"
    echo "Status: $DEPLOY_STATUS"
    echo "Target: $DEPLOY_TARGET"
    echo ""
    
    if [ -f ".firebaserc" ]; then
        echo "Firebase Project:"
        cat .firebaserc
        echo ""
    fi
    
    # Get recent deploy history from firebase-debug.log if exists
    if [ -f ".claude/logs/firebase-debug.log" ]; then
        echo "Recent Functions Logs:"
        tail -20 ".claude/logs/firebase-debug.log"
    fi
} > "$LOG_FILE"

echo "📋 Log saved: $LOG_FILE"

# Update latest deploy log
cp "$LOG_FILE" "$LOG_DIR/firebase_deploy_latest.log"

# Cleanup old logs (keep last 10)
cd "$LOG_DIR"
ls -t firebase_deploy_*.log 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

# Notify based on status
if [ "$DEPLOY_STATUS" = "success" ]; then
    echo ""
    echo "✅✅✅ Firebase Deploy SUCCESSFUL ✅✅✅"
    
    # macOS notification
    if [ "$(uname)" = "Darwin" ]; then
        osascript -e 'display notification "Firebase Deploy Complete!" with title "Firebase" sound name "Glass"' 2>/dev/null || true
    fi
    
    # Show deploy URL if available
    if [ -f "firebase.json" ]; then
        HOSTING_URL=$(grep -A5 '"hosting"' firebase.json 2>/dev/null | grep "public" | sed 's/.*"//;s/".*//' || echo "")
        if [ -n "$HOSTING_URL" ]; then
            echo ""
            echo "🌐 Deployed to: $HOSTING_URL"
        fi
    fi
else
    echo ""
    echo "❌ Firebase Deploy FAILED"
    echo ""
    echo "Check logs at: $LOG_FILE"
    echo "View function logs: firebase functions:log"
    
    # macOS notification
    if [ "$(uname)" = "Darwin" ]; then
        osascript -e 'display notification "Firebase Deploy Failed!" with title "Firebase Error"' 2>/dev/null || true
    fi
fi

echo ""

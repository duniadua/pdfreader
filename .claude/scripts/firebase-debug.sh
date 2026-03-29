#!/bin/bash
# Firebase Debug Helper Script
# Usage: ./firebase-debug.sh [command] [options]
#
# Commands:
#   logs           - View recent Firebase Functions logs
#   state [id]     - Check chat session state in Firestore
#   functions      - List deployed functions
#   test-auth      - Test Firebase authentication
#   export-data    - Export chat sessions for analysis
#   check-health   - Overall Firebase health check

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

case "$1" in
  logs)
    echo -e "${GREEN}📋 Fetching recent Firebase Functions logs...${NC}"
    firebase functions:log
    ;;

  state)
    if [ -z "$2" ]; then
      echo -e "${RED}Error: Please provide a session ID${NC}"
      echo "Usage: $0 state <session_id>"
      exit 1
    fi
    echo -e "${GREEN}🔍 Fetching chat session state for: $2${NC}"
    firebase firestore:get "chatSessions/$2"
    ;;

  functions)
    echo -e "${GREEN}📦 Listing deployed Firebase Functions...${NC}"
    firebase functions:list
    ;;

  test-auth)
    echo -e "${GREEN}🔐 Testing Firebase authentication...${NC}"
    firebase auth:list --limit 10
    ;;

  export-data)
    echo -e "${GREEN}📤 Exporting chat sessions for analysis...${NC}"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR="firebase_debug_export_$TIMESTAMP"
    mkdir -p "$OUTPUT_DIR"

    echo "Exporting to: $OUTPUT_DIR/"
    firebase firestore:get chatSessions > "$OUTPUT_DIR/chat_sessions.json"
    echo -e "${GREEN}✅ Export complete: $OUTPUT_DIR/chat_sessions.json${NC}"
    ;;

  check-health)
    echo -e "${GREEN}🏥 Running Firebase health check...${NC}"
    echo ""

    # Check functions
    echo -e "${YELLOW}Functions:${NC}"
    firebase functions:list 2>&1 | head -5

    echo ""
    echo -e "${YELLOW}Recent Errors (check logs command for details):${NC}"
    firebase functions:log 2>&1 | grep -i error | head -5 || echo "No recent errors found"

    echo ""
    echo -e "${YELLOW}Firestore Status:${NC}"
    echo "Run 'firebase firestore:indexes' in Firebase Console for detailed info"

    echo ""
    echo -e "${GREEN}✅ Health check complete${NC}"
    ;;

  *)
    echo "Firebase Debug Helper"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  logs              View recent Firebase Functions logs"
    echo "  state [id]        Check chat session state in Firestore"
    echo "  functions         List deployed functions"
    echo "  test-auth         Test Firebase authentication"
    echo "  export-data       Export chat sessions for analysis"
    echo "  check-health      Overall Firebase health check"
    echo ""
    echo "Examples:"
    echo "  $0 logs"
    echo "  $0 state abc123xyz"
    echo "  $0 export-data"
    exit 1
    ;;
esac

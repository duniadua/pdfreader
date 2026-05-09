#!/bin/bash

# Integration Test Runner Script
# Convenience script for running rate limiting integration tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FUNCTIONS_DIR="$PROJECT_ROOT/functions"

echo -e "${GREEN}🧪 Rate Limiting Integration Test Runner${NC}\n"

# Check if emulators are running
check_emulators() {
  echo -e "${YELLOW}📡 Checking Firebase emulators...${NC}"

  if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Firestore emulator is running${NC}\n"
    return 0
  else
    echo -e "${RED}❌ Firestore emulator is not running${NC}"
    echo -e "\n${YELLOW}Start emulators with:${NC}"
    echo -e "  firebase emulators:start --only firestore\n"
    return 1
  fi
}

# Run all integration tests
run_all_tests() {
  echo -e "${GREEN}🚀 Running all integration tests...${NC}\n"

  cd "$FUNCTIONS_DIR"

  npm test -- test/integration/ --verbose
}

# Run specific test file
run_test_file() {
  local test_file=$1

  if [ ! -f "$FUNCTIONS_DIR/test/integration/$test_file" ]; then
    echo -e "${RED}❌ Test file not found: $test_file${NC}\n"
    echo "Available test files:"
    ls -1 "$FUNCTIONS_DIR/test/integration/"
    exit 1
  fi

  echo -e "${GREEN}🧪 Running $test_file...${NC}\n"

  cd "$FUNCTIONS_DIR"

  npm test -- "test/integration/$test_file" --verbose
}

# Run tests matching pattern
run_matching_tests() {
  local pattern=$1

  echo -e "${GREEN}🔍 Running tests matching: $pattern${NC}\n"

  cd "$FUNCTIONS_DIR"

  npm test -- -t "$pattern" --verbose
}

# Run with coverage
run_coverage() {
  echo -e "${GREEN}📊 Running tests with coverage...${NC}\n"

  cd "$FUNCTIONS_DIR"

  npm run test:coverage -- test/integration/
}

# Show help
show_help() {
  cat << EOF
${GREEN}Rate Limiting Integration Test Runner${NC}

${YELLOW}Usage:${NC}
  $0 [command] [options]

${YELLOW}Commands:${NC}
  all              Run all integration tests (default)
  rate-limit       Run rate limit tests
  concurrent       Run concurrent request tests
  circuit          Run circuit breaker tests
  fail-open        Run fail-open behavior tests
  remote-config    Run remote config tests
  coverage         Run tests with coverage report
  match <pattern>  Run tests matching pattern
  help             Show this help message

${YELLOW}Examples:${NC}
  $0 all                    # Run all tests
  $0 rate-limit             # Run rate limit tests
  $0 match "concurrent"      # Run tests matching "concurrent"
  $0 coverage               # Run with coverage

${YELLOW}Prerequisites:${NC}
  - Firebase emulators running (Firestore on port 8080)
  - Dependencies installed (npm install)
  - TypeScript built (npm run build)

EOF
}

# Main script logic
main() {
  # Check emulators first
  if ! check_emulators; then
    exit 1
  fi

  # Parse command
  local command=${1:-all}

  case $command in
    all)
      run_all_tests
      ;;
    rate-limit)
      run_test_file "rateLimit.test.ts"
      ;;
    concurrent)
      run_test_file "concurrentRateLimit.test.ts"
      ;;
    circuit)
      run_test_file "circuitBreaker.test.ts"
      ;;
    fail-open)
      run_test_file "failOpen.test.ts"
      ;;
    remote-config)
      run_test_file "remoteConfigChange.test.ts"
      ;;
    coverage)
      run_coverage
      ;;
    match)
      if [ -z "$2" ]; then
        echo -e "${RED}❌ Error: match command requires a pattern${NC}\n"
        show_help
        exit 1
      fi
      run_matching_tests "$2"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      echo -e "${RED}❌ Unknown command: $command${NC}\n"
      show_help
      exit 1
      ;;
  esac
}

# Run main
main "$@"

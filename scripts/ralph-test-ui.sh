#!/bin/bash
# Ralph UI Tester - Automated interaction testing via dev-browser
# Fast, token-efficient UI testing using CDP (Chrome DevTools Protocol)
#
# Usage:
#   ralph-test-ui <url> <test-script>     # Run inline test script
#   ralph-test-ui --file <url> <file.ts>  # Run test from file
#   ralph-test-ui --start                 # Start dev-browser server
#   ralph-test-ui --stop                  # Stop dev-browser server
#
# Examples:
#   ralph-test-ui "http://localhost:5173" 'await page.click("button:has-text(\"AC\")"); return await page.$eval(".display", el => el.textContent);'
#   ralph-test-ui --start

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-utils.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEV_BROWSER_DIR="$HOME/.claude/skills/dev-browser"
DEV_BROWSER_PORT=9222

# Check if dev-browser server is running
is_dev_browser_running() {
  curl -s "http://localhost:$DEV_BROWSER_PORT" > /dev/null 2>&1
}

# Start dev-browser server
start_server() {
  if is_dev_browser_running; then
    echo -e "${GREEN}✓ Dev-browser already running on port $DEV_BROWSER_PORT${NC}"
    return 0
  fi

  echo -e "${YELLOW}Starting dev-browser server...${NC}"
  cd "$DEV_BROWSER_DIR"
  ./server.sh &

  # Wait for server to be ready
  for i in {1..30}; do
    if is_dev_browser_running; then
      echo -e "${GREEN}✓ Dev-browser started on port $DEV_BROWSER_PORT${NC}"
      return 0
    fi
    sleep 1
  done

  echo -e "${RED}Failed to start dev-browser server${NC}"
  return 1
}

# Stop dev-browser server
stop_server() {
  echo -e "${YELLOW}Stopping dev-browser server...${NC}"
  pkill -f "dev-browser" 2>/dev/null || true
  pkill -f "port.*$DEV_BROWSER_PORT" 2>/dev/null || true
  echo -e "${GREEN}✓ Server stopped${NC}"
}

# Run inline test script
run_inline_test() {
  local url="$1"
  local test_code="$2"
  local page_name="${3:-ralph-test}"

  if ! is_dev_browser_running; then
    echo -e "${RED}Dev-browser not running. Start with: ralph-test-ui --start${NC}"
    return 1
  fi

  echo -e "${BLUE}=== Ralph UI Tester ===${NC}"
  echo "URL: $url"
  echo ""

  cd "$DEV_BROWSER_DIR"

  bun x tsx <<EOF
import { connect, waitForPageLoad } from "@/client.js";

const client = await connect("http://localhost:$DEV_BROWSER_PORT");
const page = await client.page("$page_name");

await page.goto("$url");
await waitForPageLoad(page);

// Run user test code
const testFn = async (page) => {
  $test_code
};

try {
  const result = await testFn(page);
  if (result !== undefined) {
    console.log("Result:", result);
  }
  console.log("✅ Test completed");
} catch (error) {
  console.error("❌ Test failed:", error.message);
  process.exit(1);
}

await client.disconnect();
EOF
}

# Run test from file
run_file_test() {
  local url="$1"
  local test_file="$2"
  local page_name="${3:-ralph-test}"

  if ! is_dev_browser_running; then
    echo -e "${RED}Dev-browser not running. Start with: ralph-test-ui --start${NC}"
    return 1
  fi

  if [ ! -f "$test_file" ]; then
    echo -e "${RED}Test file not found: $test_file${NC}"
    return 1
  fi

  echo -e "${BLUE}=== Ralph UI Tester ===${NC}"
  echo "URL: $url"
  echo "Test file: $test_file"
  echo ""

  cd "$DEV_BROWSER_DIR"

  # Create wrapper that includes the test file
  local test_code=$(cat "$test_file")

  bun x tsx <<EOF
import { connect, waitForPageLoad } from "@/client.js";

const client = await connect("http://localhost:$DEV_BROWSER_PORT");
const page = await client.page("$page_name");

await page.goto("$url");
await waitForPageLoad(page);

// Imported test code
$test_code

await client.disconnect();
EOF
}

# Click helper for common operations
run_click_sequence() {
  local url="$1"
  shift
  local clicks=("$@")

  if ! is_dev_browser_running; then
    echo -e "${RED}Dev-browser not running. Start with: ralph-test-ui --start${NC}"
    return 1
  fi

  echo -e "${BLUE}=== Ralph UI Tester (Click Sequence) ===${NC}"
  echo "URL: $url"
  echo "Clicks: ${clicks[*]}"
  echo ""

  cd "$DEV_BROWSER_DIR"

  # Build click commands
  local click_code=""
  for selector in "${clicks[@]}"; do
    click_code+="await page.click('$selector'); await new Promise(r => setTimeout(r, 100));"
  done

  bun x tsx <<EOF
import { connect, waitForPageLoad } from "@/client.js";

const client = await connect("http://localhost:$DEV_BROWSER_PORT");
const page = await client.page("ralph-clicks");

await page.goto("$url");
await waitForPageLoad(page);

$click_code

console.log("✅ Click sequence completed");
await client.disconnect();
EOF
}

# Parse arguments
case "${1:-}" in
  --start)
    start_server
    ;;
  --stop)
    stop_server
    ;;
  --file)
    run_file_test "$2" "$3" "${4:-ralph-test}"
    ;;
  --clicks)
    shift
    URL="$1"
    shift
    run_click_sequence "$URL" "$@"
    ;;
  --help|-h)
    echo "Ralph UI Tester - Fast interaction testing via dev-browser"
    echo ""
    echo "Usage:"
    echo "  ralph-test-ui --start                    Start dev-browser server"
    echo "  ralph-test-ui --stop                     Stop dev-browser server"
    echo "  ralph-test-ui <url> '<test-code>'        Run inline test"
    echo "  ralph-test-ui --file <url> <file.ts>    Run test from file"
    echo "  ralph-test-ui --clicks <url> <sel>...   Run click sequence"
    echo ""
    echo "Examples:"
    echo "  ralph-test-ui --start"
    echo "  ralph-test-ui 'http://localhost:5173' 'await page.click(\"button\"); return await page.title();'"
    echo "  ralph-test-ui --clicks 'http://localhost:5173' 'button:has-text(\"3\")' 'button:has-text(\"+\")'"
    ;;
  *)
    if [ -n "$1" ] && [ -n "$2" ]; then
      run_inline_test "$1" "$2" "${3:-ralph-test}"
    else
      echo "Usage: ralph-test-ui <url> '<test-code>' or ralph-test-ui --help"
      exit 1
    fi
    ;;
esac

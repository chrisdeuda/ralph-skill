#!/bin/bash
# Ralph UI Validator - Automated UI verification
# Uses dev-browser (ARIA snapshot) by default, falls back to vision
#
# Usage:
#   ralph-validate-ui <url> <criteria>              # Auto (dev-browser or vision)
#   ralph-validate-ui --quick <url> <selectors...>  # Zero tokens - element exists check
#   ralph-validate-ui --vision <url> <criteria>     # Force vision mode
#
# Examples:
#   ralph-validate-ui "http://localhost:5173" "Calculator with Clear History button"
#   ralph-validate-ui --quick "http://localhost:5173" ".clear-btn" "button:has-text('=')"
#   ralph-validate-ui --vision "http://localhost:5173" "Modern dark theme UI"

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

# Validate using dev-browser ARIA snapshot (cheap - no vision)
validate_with_dev_browser() {
  local url="$1"
  local criteria="$2"

  echo -e "${YELLOW}🔍 Using dev-browser (ARIA snapshot)...${NC}"

  cd "$DEV_BROWSER_DIR"

  # Get ARIA snapshot
  SNAPSHOT=$(bun x tsx <<EOF
import { connect, waitForPageLoad } from "@/client.js";
const client = await connect("http://localhost:$DEV_BROWSER_PORT");
const page = await client.page("ralph-validate");
await page.goto("$url");
await waitForPageLoad(page);
const snapshot = await client.getAISnapshot("ralph-validate");
console.log(snapshot);
await client.disconnect();
EOF
2>/dev/null)

  if [ -z "$SNAPSHOT" ]; then
    echo -e "${RED}Failed to get ARIA snapshot${NC}"
    return 1
  fi

  echo -e "${GREEN}✓ Got ARIA snapshot${NC}"
  echo ""

  # Use Claude to analyze (text only - much cheaper than vision)
  RESULT=$(claude --model haiku -p "Analyze this ARIA accessibility snapshot against the criteria.

CRITERIA: $criteria

ARIA SNAPSHOT:
$SNAPSHOT

Respond with EXACTLY one line:
- PASS: [reason] - if criteria is met
- FAIL: [reason] - if criteria is NOT met" 2>/dev/null)

  echo "$RESULT"
  return 0
}

# Validate using vision (expensive but handles visual criteria)
validate_with_vision() {
  local url="$1"
  local criteria="$2"
  local screenshot_path="$(pwd)/ralph-ui-validation.png"

  echo -e "${YELLOW}📸 Using vision mode (screenshot)...${NC}"

  npx --yes playwright screenshot "$url" "$screenshot_path" --wait-for-timeout=3000 2>/dev/null

  if [ ! -f "$screenshot_path" ]; then
    echo -e "${RED}❌ Failed to capture screenshot${NC}"
    return 1
  fi

  echo -e "${GREEN}✓ Screenshot captured${NC}"
  echo ""

  RESULT=$(claude --model sonnet -p "Validate this UI screenshot against criteria.

CRITERIA: $criteria

Respond with EXACTLY one line:
- PASS: [reason] - if criteria is met
- FAIL: [reason] - if criteria is NOT met

Be strict but fair." @"$screenshot_path" 2>/dev/null)

  rm -f "$screenshot_path" 2>/dev/null
  echo "$RESULT"
  return 0
}

# Quick mode - just check if elements exist (zero tokens!)
validate_quick() {
  local url="$1"
  shift
  local selectors=("$@")

  echo -e "${YELLOW}⚡ Quick mode (element existence check)...${NC}"
  echo "URL: $url"
  echo "Selectors: ${selectors[*]}"
  echo ""

  local all_pass=true

  for selector in "${selectors[@]}"; do
    # Use playwright to check if element exists
    EXISTS=$(npx --yes playwright screenshot "$url" /dev/null --wait-for-timeout=2000 2>&1 | grep -c "error" || true)

    # Actually check with a proper script
    CHECK=$(cd "$DEV_BROWSER_DIR" && bun x tsx <<EOF 2>/dev/null || echo "FAIL"
import { connect, waitForPageLoad } from "@/client.js";
const client = await connect("http://localhost:$DEV_BROWSER_PORT");
const page = await client.page("ralph-quick");
await page.goto("$url");
await waitForPageLoad(page);
const el = await page.\$("$selector");
console.log(el ? "EXISTS" : "MISSING");
await client.disconnect();
EOF
)

    if echo "$CHECK" | grep -q "EXISTS"; then
      echo -e "  ${GREEN}✓${NC} $selector"
    else
      echo -e "  ${RED}✗${NC} $selector"
      all_pass=false
    fi
  done

  echo ""
  if $all_pass; then
    RESULT="PASS: All elements found"
  else
    RESULT="FAIL: Some elements missing"
  fi
  echo "$RESULT"
}

# Parse arguments
MODE="auto"
URL=""
CRITERIA=""

case "${1:-}" in
  --quick)
    MODE="quick"
    shift
    URL="$1"
    shift
    SELECTORS=("$@")
    ;;
  --vision)
    MODE="vision"
    URL="$2"
    CRITERIA="$3"
    ;;
  --dev-browser|--aria)
    MODE="dev-browser"
    URL="$2"
    CRITERIA="$3"
    ;;
  *)
    URL="${1:-http://localhost:5173}"
    CRITERIA="${2:-UI renders correctly}"
    ;;
esac

echo -e "${BLUE}=== Ralph UI Validator ===${NC}"
echo "Mode: $MODE"
echo "URL: $URL"
[ -n "$CRITERIA" ] && echo "Criteria: $CRITERIA"
echo ""

# Execute validation
case "$MODE" in
  quick)
    validate_quick "$URL" "${SELECTORS[@]}"
    ;;
  vision)
    validate_with_vision "$URL" "$CRITERIA"
    ;;
  dev-browser)
    validate_with_dev_browser "$URL" "$CRITERIA"
    ;;
  auto)
    # Try dev-browser first, fall back to vision
    if is_dev_browser_running; then
      validate_with_dev_browser "$URL" "$CRITERIA"
    else
      echo -e "${YELLOW}dev-browser not running, using vision mode${NC}"
      echo -e "${YELLOW}Tip: Start with: ~/.claude/skills/dev-browser/server.sh &${NC}"
      echo ""
      validate_with_vision "$URL" "$CRITERIA"
    fi
    ;;
esac

# Check result
echo ""
if echo "$RESULT" | grep -qi "^PASS"; then
  echo -e "${GREEN}════════════════════════════${NC}"
  echo -e "${GREEN}✅ UI VALIDATION PASSED${NC}"
  echo -e "${GREEN}════════════════════════════${NC}"
  notify "✅ UI Validated" "${CRITERIA:-Elements exist}"
  exit 0
else
  echo -e "${RED}════════════════════════════${NC}"
  echo -e "${RED}❌ UI VALIDATION FAILED${NC}"
  echo -e "${RED}════════════════════════════${NC}"
  notify "❌ UI Failed" "${CRITERIA:-Elements missing}" "max"
  exit 1
fi

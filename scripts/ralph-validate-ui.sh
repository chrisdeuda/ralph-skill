#!/bin/bash
# Ralph UI Validator - Automated UI verification
# Auto mode priority: playwriter > dev-browser > vision (by efficiency)
#
# Usage:
#   ralph-validate-ui <url> <criteria>              # Auto (best available mode)
#   ralph-validate-ui --playwriter <url> <criteria> # Use playwriter MCP (recommended)
#   ralph-validate-ui --quick <url> <selectors...>  # Zero tokens - element exists check
#   ralph-validate-ui --vision <url> <criteria>     # Force vision mode (expensive)
#
# Environment Variables:
#   RALPH_DEV_URL       - Default URL (auto-detected from vite/next config)
#   RALPH_VALIDATE_MODE - Default mode: playwriter, dev-browser, vision, quick
#
# Examples:
#   ralph-validate-ui "http://localhost:5173" "Calculator with Clear History button"
#   ralph-validate-ui --playwriter "http://localhost:5173" "Number buttons 0-9 visible"
#   ralph-validate-ui --quick "http://localhost:5173" ".clear-btn" "button"
#   RALPH_VALIDATE_MODE=playwriter ralph-validate-ui  # Use env var
#
# Mode Efficiency (tokens + speed):
#   playwriter:   ~50ms, minimal tokens, requires MCP + Chrome extension
#   dev-browser:  ~100ms, text analysis, requires separate server
#   vision:       ~3-5s, high tokens, always available (fallback)

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
PLAYWRITER_PORT=19988

# Check if playwriter MCP is available (WebSocket server running)
is_playwriter_running() {
  curl -s --max-time 1 "http://localhost:$PLAYWRITER_PORT" > /dev/null 2>&1
}

# Auto-detect dev server URL from common configs
detect_dev_url() {
  # Check environment variable first
  if [ -n "$RALPH_DEV_URL" ]; then
    echo "$RALPH_DEV_URL"
    return
  fi

  # Try to detect from vite.config (default 5173)
  if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
    echo "http://localhost:5173"
    return
  fi

  # Try to detect from next.config (default 3000)
  if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
    echo "http://localhost:3000"
    return
  fi

  # Try to detect from package.json scripts
  if [ -f "package.json" ]; then
    if grep -q "\"dev\".*vite" package.json 2>/dev/null; then
      echo "http://localhost:5173"
      return
    fi
    if grep -q "\"dev\".*next" package.json 2>/dev/null; then
      echo "http://localhost:3000"
      return
    fi
    if grep -q "\"start\".*react-scripts" package.json 2>/dev/null; then
      echo "http://localhost:3000"
      return
    fi
  fi

  # Default fallback
  echo "http://localhost:3000"
}

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

# Validate using playwriter MCP (recommended for Claude Code)
validate_with_playwriter() {
  local url="$1"
  local criteria="$2"

  echo -e "${YELLOW}🎭 Using Playwriter MCP mode...${NC}"
  echo ""
  echo "This mode requires Claude to execute playwriter commands."
  echo ""
  echo -e "${BLUE}Instructions for Claude:${NC}"
  echo "  1. Navigate to: $url"
  echo "  2. Use screenshotWithAccessibilityLabels({ page }) to capture UI"
  echo "  3. Validate against criteria: $criteria"
  echo ""
  echo -e "${YELLOW}Playwriter code pattern:${NC}"
  echo ""
  echo "  // Navigate to page"
  echo "  await page.goto('$url');"
  echo "  await page.waitForLoadState('networkidle');"
  echo ""
  echo "  // Take screenshot with accessibility labels"
  echo "  await screenshotWithAccessibilityLabels({ page });"
  echo ""
  echo "  // Search for specific elements"
  echo "  const snapshot = await accessibilitySnapshot({ page, search: /$criteria/i });"
  echo "  console.log(snapshot);"
  echo ""
  echo -e "${GREEN}Criteria to validate:${NC} $criteria"
  echo ""
  echo -e "${BLUE}Key Playwriter Functions:${NC}"
  echo "  - screenshotWithAccessibilityLabels({ page })  # Visual + aria-refs"
  echo "  - accessibilitySnapshot({ page, search })      # Search elements"
  echo "  - page.locator('aria-ref=e123').click()        # Click by ref"
  echo "  - context.waitForEvent('page')                 # Handle new tabs"
  echo "  - mcp__playwriter__reset                       # Reset if stuck"
  echo ""
  echo "Run this in Claude with playwriter MCP enabled."

  # Return success - actual validation is done by Claude
  RESULT="INFO: Playwriter mode - manual Claude validation required"
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
# Support RALPH_VALIDATE_MODE env var (playwriter, dev-browser, vision, quick)
MODE="${RALPH_VALIDATE_MODE:-auto}"
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
  --playwriter|--pw)
    MODE="playwriter"
    URL="$2"
    CRITERIA="$3"
    ;;
  *)
    URL="${1:-$(detect_dev_url)}"
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
  playwriter)
    validate_with_playwriter "$URL" "$CRITERIA"
    ;;
  auto)
    # Priority: playwriter > dev-browser > vision (by efficiency)
    if is_playwriter_running; then
      echo -e "${GREEN}Playwriter detected - using most efficient mode${NC}"
      echo ""
      validate_with_playwriter "$URL" "$CRITERIA"
    elif is_dev_browser_running; then
      validate_with_dev_browser "$URL" "$CRITERIA"
    else
      echo -e "${YELLOW}No browser automation running, using vision mode${NC}"
      echo -e "${YELLOW}Tip: Use Playwriter MCP (fastest) or dev-browser${NC}"
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
elif echo "$RESULT" | grep -qi "^INFO"; then
  echo -e "${BLUE}════════════════════════════${NC}"
  echo -e "${BLUE}ℹ️  PLAYWRITER MODE${NC}"
  echo -e "${BLUE}════════════════════════════${NC}"
  echo "Use Claude with playwriter MCP to validate UI"
  exit 0
else
  echo -e "${RED}════════════════════════════${NC}"
  echo -e "${RED}❌ UI VALIDATION FAILED${NC}"
  echo -e "${RED}════════════════════════════${NC}"
  notify "❌ UI Failed" "${CRITERIA:-Elements missing}" "max"
  exit 1
fi

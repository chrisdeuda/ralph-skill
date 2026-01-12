#!/bin/bash
# Ralph UI Validator - Automated visual verification using Claude vision
# Usage: ralph-validate-ui <url> <acceptance-criteria> [screenshot-path]
#
# Example:
#   ralph-validate-ui "http://localhost:5173" "Calculator has Clear History button"
#   ralph-validate-ui "http://localhost:3000/dashboard" "Shows user profile with avatar"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-utils.sh"

URL="${1:-http://localhost:5173}"
CRITERIA="${2:-UI renders correctly without errors}"
# Use current directory for screenshot (Claude CLI needs access)
SCREENSHOT_PATH="${3:-$(pwd)/ralph-ui-validation.png}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Ralph UI Validator ===${NC}"
echo "URL: $URL"
echo "Criteria: $CRITERIA"
echo ""

# Check if playwright is available
if ! command -v npx &> /dev/null; then
  echo -e "${RED}Error: npx not found. Install Node.js first.${NC}"
  exit 1
fi

# Take screenshot using playwright
echo -e "${YELLOW}📸 Taking screenshot...${NC}"
npx --yes playwright screenshot "$URL" "$SCREENSHOT_PATH" --wait-for-timeout=3000 2>/dev/null

if [ ! -f "$SCREENSHOT_PATH" ]; then
  echo -e "${RED}❌ Failed to capture screenshot${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Screenshot saved: $SCREENSHOT_PATH${NC}"
echo ""

# Use Claude to analyze the screenshot
echo -e "${YELLOW}🤖 Analyzing with Claude vision...${NC}"
echo ""

VALIDATION_PROMPT="You are validating a UI screenshot against acceptance criteria.

ACCEPTANCE CRITERIA:
$CRITERIA

Analyze the screenshot and respond with EXACTLY one of:
- PASS: [brief reason why it passes]
- FAIL: [brief reason why it fails]

Be strict but fair. Only pass if the criteria is clearly met."

# Run Claude with the screenshot
RESULT=$(claude --model sonnet -p "$VALIDATION_PROMPT @$SCREENSHOT_PATH" 2>/dev/null)

echo "$RESULT"
echo ""

# Cleanup screenshot
rm -f "$SCREENSHOT_PATH" 2>/dev/null

# Check result
if echo "$RESULT" | grep -qi "^PASS"; then
  echo -e "${GREEN}════════════════════════════${NC}"
  echo -e "${GREEN}✅ UI VALIDATION PASSED${NC}"
  echo -e "${GREEN}════════════════════════════${NC}"
  notify "✅ UI Validated" "Criteria: ${CRITERIA:0:50}..."
  exit 0
else
  echo -e "${RED}════════════════════════════${NC}"
  echo -e "${RED}❌ UI VALIDATION FAILED${NC}"
  echo -e "${RED}════════════════════════════${NC}"
  notify "❌ UI Failed" "Criteria: ${CRITERIA:0:50}..." "max"
  exit 1
fi

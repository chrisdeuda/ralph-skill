#!/bin/bash
# Ralph Playwriter Integration - Browser automation via Playwriter MCP
# Uses single execute tool with full Playwright API - more efficient than dev-browser
#
# Prerequisites:
#   1. Install Playwriter Chrome extension from Chrome Web Store
#   2. Click extension icon on tabs you want to control (shows "Connected")
#   3. Playwriter MCP configured in ~/.claude.json (for Claude Code)
#      OR ~/.claude/settings.json (for Claude Desktop)
#
# IMPORTANT: Claude Code uses ~/.claude.json, NOT ~/.claude/settings.json
#   Add to mcpServers in ~/.claude.json:
#   "playwriter": { "command": "npx", "args": ["playwriter@latest"] }
#
# Usage:
#   ralph-playwriter --status                    # Check connection status
#   ralph-playwriter --setup                     # Show setup instructions
#   ralph-playwriter --patterns                  # Show common code patterns
#   ralph-playwriter <playwright-code>           # Execute Playwright code
#
# Examples:
#   ralph-playwriter --status
#   ralph-playwriter --setup
#   ralph-playwriter 'await screenshotWithAccessibilityLabels({ page });'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-utils.sh" 2>/dev/null || true

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PLAYWRITER_PORT=19988

# Check if playwriter server is running
is_playwriter_running() {
  curl -s "http://localhost:$PLAYWRITER_PORT" > /dev/null 2>&1
}

# Show status
show_status() {
  echo -e "${BLUE}=== Playwriter Status ===${NC}"

  if is_playwriter_running; then
    echo -e "${GREEN}✓ Playwriter server running on port $PLAYWRITER_PORT${NC}"
    echo ""
    echo "To use Playwriter:"
    echo "  1. Open Chrome with Playwriter extension installed"
    echo "  2. Click extension icon on tab to control (turns green)"
    echo "  3. Use Claude with playwriter MCP tools"
  else
    echo -e "${RED}✗ Playwriter server not running${NC}"
    echo ""
    echo "To start Playwriter:"
    echo "  1. Ensure playwriter is in ~/.claude/settings.json mcpServers"
    echo "  2. Restart Claude to load the MCP"
    echo "  3. Install Chrome extension from Web Store"
  fi
}

# Show setup instructions
show_setup() {
  echo -e "${BLUE}=== Playwriter Setup for Claude Code ===${NC}"
  echo ""
  echo -e "${YELLOW}Step 1: Install Chrome Extension${NC}"
  echo "  - Search 'Playwriter' in Chrome Web Store"
  echo "  - Install the extension"
  echo ""
  echo -e "${YELLOW}Step 2: Configure MCP in ~/.claude.json${NC}"
  echo "  Add to your mcpServers:"
  echo ""
  echo '  "playwriter": {'
  echo '    "command": "npx",'
  echo '    "args": ["playwriter@latest"]'
  echo '  }'
  echo ""
  echo -e "${YELLOW}Step 3: Restart Claude Code${NC}"
  echo "  - Run: /mcp to verify playwriter is connected"
  echo ""
  echo -e "${YELLOW}Step 4: Activate on Tab${NC}"
  echo "  - Navigate to your dev server URL"
  echo "  - Click the Playwriter extension icon"
  echo "  - Wait for 'Connected' status"
  echo ""
  echo -e "${GREEN}NOTE: Claude Desktop uses ~/.claude/settings.json instead${NC}"
}

# Show common patterns
show_patterns() {
  echo -e "${BLUE}=== Playwriter Common Patterns ===${NC}"
  echo ""
  echo -e "${YELLOW}📸 Screenshot with Labels (most useful)${NC}"
  echo '  await screenshotWithAccessibilityLabels({ page });'
  echo ""
  echo -e "${YELLOW}🔍 Search Accessibility Tree${NC}"
  echo '  const snapshot = await accessibilitySnapshot({ page, search: /button|submit/i });'
  echo '  console.log(snapshot);'
  echo ""
  echo -e "${YELLOW}🖱️ Click Element by aria-ref${NC}"
  echo "  await page.locator('aria-ref=e182').click();"
  echo ""
  echo -e "${YELLOW}📝 Fill Form Input${NC}"
  echo "  await page.fill('input[name=\"email\"]', 'test@example.com');"
  echo ""
  echo -e "${YELLOW}🔄 Handle New Tab/Popup (e.g., PDF)${NC}"
  echo '  const [popup] = await Promise.all(['
  echo "    context.waitForEvent('page', { timeout: 15000 }),"
  echo "    page.locator('button:text(\"Publish\")').click()"
  echo '  ]);'
  echo '  await popup.waitForLoadState();'
  echo '  state.newPage = popup;'
  echo ""
  echo -e "${YELLOW}📜 Scroll and Screenshot${NC}"
  echo '  await page.mouse.wheel(0, 500);'
  echo '  await page.waitForTimeout(500);'
  echo '  await screenshotWithAccessibilityLabels({ page });'
  echo ""
  echo -e "${YELLOW}🔧 Reset Connection (when stuck)${NC}"
  echo "  Use: mcp__playwriter__reset tool"
  echo ""
  echo -e "${YELLOW}📊 Check All Pages${NC}"
  echo "  console.log('Pages:', context.pages().map(p => p.url()));"
  echo ""
  echo -e "${YELLOW}💾 Store State Between Calls${NC}"
  echo '  state.myData = someValue;  // persists across execute calls'
  echo ""
  echo -e "${GREEN}TIP: Use screenshotWithAccessibilityLabels first to get aria-ref IDs${NC}"
}

# Generate Playwright code template (legacy)
generate_template() {
  local action="$1"

  case "$action" in
    click)
      echo 'await page.click("selector");'
      ;;
    fill)
      echo 'await page.fill("selector", "value");'
      ;;
    screenshot)
      echo 'await screenshotWithAccessibilityLabels({ page });'
      ;;
    snapshot)
      echo 'const snapshot = await accessibilitySnapshot({ page }); console.log(snapshot);'
      ;;
    navigate)
      echo 'await page.goto("https://example.com");'
      ;;
    popup)
      echo 'const [popup] = await Promise.all([context.waitForEvent("page"), page.click("button")]); state.popup = popup;'
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available: click, fill, screenshot, snapshot, navigate, popup"
      ;;
  esac
}

# Main
case "${1:-}" in
  --status|-s)
    show_status
    ;;
  --setup)
    show_setup
    ;;
  --patterns|-p)
    show_patterns
    ;;
  --template|-t)
    generate_template "${2:-click}"
    ;;
  --help|-h)
    echo "Ralph Playwriter Integration"
    echo ""
    echo "Usage:"
    echo "  ralph-playwriter --status              Check connection status"
    echo "  ralph-playwriter --setup               Show setup instructions"
    echo "  ralph-playwriter --patterns            Show common code patterns"
    echo "  ralph-playwriter --template <action>   Generate code template"
    echo ""
    echo "Templates: click, fill, screenshot, snapshot, navigate, popup"
    echo ""
    echo "Playwriter MCP provides:"
    echo "  - Single 'execute' tool with full Playwright API"
    echo "  - screenshotWithAccessibilityLabels({ page }) for visual testing"
    echo "  - accessibilitySnapshot({ page, search }) for element search"
    echo "  - aria-ref selectors for precise element targeting"
    echo "  - state object for persisting data between calls"
    echo "  - mcp__playwriter__reset for connection recovery"
    echo ""
    echo "Speed Comparison:"
    echo "  Playwriter:   ~50ms/action, 1 tool, minimal tokens"
    echo "  Dev-browser:  ~100ms/action, full CDP, text snapshots"
    echo "  Vision:       ~3-5s/action, high token cost"
    echo ""
    echo "Claude Code vs Desktop:"
    echo "  Claude Code:    Configure MCP in ~/.claude.json"
    echo "  Claude Desktop: Configure MCP in ~/.claude/settings.json"
    ;;
  *)
    if [ -z "$1" ]; then
      show_status
    else
      echo -e "${YELLOW}Playwriter commands should be run via Claude MCP tools${NC}"
      echo ""
      echo "In Claude, use the playwriter execute tool:"
      echo "  mcp__playwriter__execute with your Playwright code"
      echo ""
      echo "Quick patterns:"
      echo "  - Screenshot: await screenshotWithAccessibilityLabels({ page });"
      echo "  - Search: await accessibilitySnapshot({ page, search: /pattern/ });"
      echo "  - Click: await page.locator('aria-ref=e123').click();"
      echo "  - Reset: Use mcp__playwriter__reset when stuck"
      echo ""
      echo "Run: ralph-playwriter --patterns for more examples"
    fi
    ;;
esac

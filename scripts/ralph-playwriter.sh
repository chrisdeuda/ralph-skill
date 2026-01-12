#!/bin/bash
# Ralph Playwriter Integration - Browser automation via Playwriter MCP
# Uses single execute tool with full Playwright API - more efficient than dev-browser
#
# Prerequisites:
#   1. Install Playwriter Chrome extension from Web Store
#   2. Click extension icon on tabs you want to control (turns green)
#   3. Playwriter MCP configured in ~/.claude/settings.json
#
# Usage:
#   ralph-playwriter --status                    # Check connection status
#   ralph-playwriter --snapshot <description>    # Get accessibility snapshot with labels
#   ralph-playwriter <playwright-code>           # Execute Playwright code
#
# Examples:
#   ralph-playwriter --status
#   ralph-playwriter --snapshot "Find login button"
#   ralph-playwriter 'await page.click("button:has-text(\"Submit\")")'

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

# Generate Playwright code template
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
      echo 'await screenshotWithAccessibilityLabels();'
      ;;
    snapshot)
      echo 'const snapshot = await page.accessibility.snapshot(); console.log(JSON.stringify(snapshot, null, 2));'
      ;;
    navigate)
      echo 'await page.goto("https://example.com");'
      ;;
    *)
      echo "Unknown action: $action"
      echo "Available: click, fill, screenshot, snapshot, navigate"
      ;;
  esac
}

# Main
case "${1:-}" in
  --status|-s)
    show_status
    ;;
  --template|-t)
    generate_template "${2:-click}"
    ;;
  --help|-h)
    echo "Ralph Playwriter Integration"
    echo ""
    echo "Usage:"
    echo "  ralph-playwriter --status              Check connection status"
    echo "  ralph-playwriter --template <action>   Generate code template"
    echo ""
    echo "Templates: click, fill, screenshot, snapshot, navigate"
    echo ""
    echo "Playwriter MCP provides:"
    echo "  - Single 'execute' tool with full Playwright API"
    echo "  - screenshotWithAccessibilityLabels() for Vimium-style labels"
    echo "  - Bypass automation detection by disconnecting extension"
    echo "  - ~50-100ms per action, minimal context window usage"
    echo ""
    echo "Speed Comparison:"
    echo "  Playwriter:   ~50ms/action, 1 tool, minimal tokens"
    echo "  Dev-browser:  ~100ms/action, full CDP, text snapshots"
    echo "  Vision:       ~3-5s/action, high token cost"
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
      echo "Your code:"
      echo "  $1"
    fi
    ;;
esac

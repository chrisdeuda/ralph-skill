#!/bin/bash
# Shared utilities for Ralph scripts

# Notification helper (macOS) - centered dialog popup with sound (non-blocking)
# Usage: notify "Title" "Message"
notify() {
  local title="$1"
  local msg="$2"
  say "$msg" 2>/dev/null &
  osascript <<EOF &
display dialog "$msg" with title "$title" buttons {"OK"} default button "OK"
EOF
}

#!/bin/bash
# Shared utilities for Ralph scripts

# ntfy.sh topic for push notifications (Apple Watch/iPhone)
NTFY_TOPIC="${RALPH_NTFY_TOPIC:-claude-mac}"

# Notification helper - sends to both Mac dialog and ntfy.sh (iPhone/Watch)
# Usage: notify "Title" "Message" [priority]
# Priority: low, default, high, urgent, max
notify() {
  local title="$1"
  local msg="$2"
  local priority="${3:-high}"

  # Mac dialog popup (non-blocking)
  osascript <<EOF &
display dialog "$msg" with title "$title" buttons {"OK"} default button "OK"
EOF

  # Push notification via ntfy.sh (vibrates Apple Watch)
  curl -s -H "Priority: $priority" -H "Title: $title" -d "$msg" "ntfy.sh/$NTFY_TOPIC" > /dev/null 2>&1 &
}

# Checkpoint notification - max priority for Watch vibration
notify_checkpoint() {
  local msg="$1"
  notify "🛑 CHECKPOINT" "$msg" "max"
}

# Task complete notification
notify_task_done() {
  local msg="$1"
  notify "✅ Task Done" "$msg" "default"
}

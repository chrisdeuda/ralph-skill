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

# ============================================
# PROGRAMMATIC LOGGING FUNCTIONS
# ============================================

# Log task start - writes to both progress.md and global ralph-log.md
# Usage: log_task_start "task_description" "model" "mode" "plan_dir" "plan_name"
log_task_start() {
  local task="$1"
  local model="$2"
  local mode="$3"
  local plan_dir="$4"
  local plan_name="$5"
  local timestamp=$(date +'%Y-%m-%d %H:%M')

  local progress_file="$plan_dir/progress.md"
  local global_log="plans/ralph-log.md"

  # Ensure directories exist
  mkdir -p "$plan_dir"
  mkdir -p "plans"

  # Create files if they don't exist
  [ ! -f "$progress_file" ] && echo "# Progress Log" > "$progress_file"
  [ ! -f "$global_log" ] && echo "# Ralph Activity Log" > "$global_log"

  # Log entry
  local entry="
---
## [$plan_name] ${task:0:60}
**Status:** In Progress | **Time:** $timestamp | **Model:** $model | **Mode:** $mode"

  # Append to both files
  echo "$entry" >> "$progress_file"
  echo "$entry" >> "$global_log"

  echo "[LOG] Task started: ${task:0:40}..."
}

# Log task completion - writes to both progress.md and global ralph-log.md
# Usage: log_task_complete "task_description" "status" "result_summary" "plan_dir"
log_task_complete() {
  local task="$1"
  local status="$2"  # "completed", "blocked", "error"
  local result="$3"
  local plan_dir="$4"
  local timestamp=$(date +'%H:%M')

  local progress_file="$plan_dir/progress.md"
  local global_log="plans/ralph-log.md"

  # Status emoji
  local status_label
  case "$status" in
    completed) status_label="✅ Completed" ;;
    blocked)   status_label="⏸️ Blocked" ;;
    error)     status_label="❌ Error" ;;
    *)         status_label="Finished" ;;
  esac

  # Log entry
  local entry="
### Result
**Status:** $status_label | **Completed:** $timestamp
$result"

  # Append to both files
  echo "$entry" >> "$progress_file"
  echo "$entry" >> "$global_log"

  echo "[LOG] Task $status: ${task:0:40}..."
}

# Log iteration summary - useful for AFK mode
# Usage: log_iteration "iteration_num" "total" "task" "plan_dir"
log_iteration() {
  local iteration="$1"
  local total="$2"
  local task="$3"
  local plan_dir="$4"
  local timestamp=$(date +'%H:%M')

  local progress_file="$plan_dir/progress.md"

  echo "[$timestamp] Iteration $iteration/$total: ${task:0:50}" >> "$progress_file"
}

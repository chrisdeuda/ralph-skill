#!/bin/bash
# Run a single Ralph iteration
# Usage: ralph-once <plan-dir> [model] [mode]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$HOME/.ralph-pids"

# Track Claude PID for ralph-kill
track_pid() {
  echo "$1" >> "$PID_FILE"
}

untrack_pid() {
  if [ -f "$PID_FILE" ]; then
    sed -i '' "/$1/d" "$PID_FILE" 2>/dev/null || true
  fi
}

# Kill and cleanup a Claude process
kill_and_cleanup() {
  local pid="$1"
  if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
    kill "$pid" 2>/dev/null || true
    sleep 0.5
    # Force kill if still running
    if ps -p "$pid" > /dev/null 2>&1; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
  untrack_pid "$pid"
}

if [ -z "$1" ]; then
  echo "Usage: ralph-once <plan-dir> [model] [mode]"
  echo "Example: ralph-once plans/260109-1430-my-feature/"
  echo "         ralph-once plans/260109-feature/ sonnet prototype"
  echo "Models: haiku, sonnet, opus (default: auto-detect)"
  echo "Modes: prototype (fast), production (quality, default)"
  exit 1
fi

export PLAN_DIR="$1"
MODEL_OVERRIDE="${2:-}"
export RALPH_MODE="${3:-production}"

# Verify plan exists
if [ ! -f "$PLAN_DIR/tasks.md" ]; then
  echo "Error: $PLAN_DIR/tasks.md not found"
  echo "Run: ralph-init <slug> to create a plan"
  exit 1
fi

# Load workflow
source "$SCRIPT_DIR/ralph-workflow.sh"

# Determine model and ccs args
if [ -n "$MODEL_OVERRIDE" ]; then
  MODEL="$MODEL_OVERRIDE"
  # Rebuild CCS_ARGS for override
  source "$SCRIPT_DIR/ralph-workflow.sh"
  CCS_ARGS=$(build_ccs_args "$MODEL")
else
  MODEL="$RALPH_MODEL"
fi

# Load shared utilities
source "$SCRIPT_DIR/ralph-utils.sh"

echo "=== Ralph Single Task ==="
echo "Plan: $PLAN_DIR"
echo "Source: $TASK_SOURCE"
echo "Mode: $RALPH_MODE"
echo "Next task: $NEXT_TASK"
echo "Model: $MODEL (auto-detected: $RALPH_MODEL)"
echo "CCS args: $CCS_ARGS"
echo "========================="

if [ -z "$NEXT_TASK" ]; then
  echo "No incomplete tasks found in $PLAN_DIR/tasks.md"
  COMPLETED_COUNT=$(grep -c "^\- \[x\]" "$TASKS_FILE" 2>/dev/null || echo "0")
  notify "Ralph ✅" "Plan: $PLAN_NAME
All $COMPLETED_COUNT tasks already complete!"
  exit 0
fi

# Log task start (programmatic)
log_task_start "$NEXT_TASK" "$MODEL" "$RALPH_MODE" "$PLAN_DIR" "$PLAN_NAME"

# Run with ccs (multi-provider support)
# CCS_ARGS is either a profile (glm, kimi) or model flag (--model sonnet)
OUTPUT_FILE=$(mktemp)
echo "Running: ccs $CCS_ARGS --dangerously-skip-permissions -p ..."
ccs $CCS_ARGS --dangerously-skip-permissions -p "$RALPH_WORKFLOW $RALPH_COMPLETE_MSG" > "$OUTPUT_FILE" 2>&1 &
CLAUDE_PID=$!
track_pid "$CLAUDE_PID"
wait $CLAUDE_PID || true
RESULT=$(cat "$OUTPUT_FILE")
rm -f "$OUTPUT_FILE"

# Kill and cleanup after task completion
kill_and_cleanup "$CLAUDE_PID"
echo "🧹 Cleaned up task process (PID: $CLAUDE_PID)"

# Log task completion (programmatic)
if echo "$RESULT" | grep -q "ALL_TASKS_DONE\|TASK_COMPLETE"; then
  log_task_complete "$NEXT_TASK" "completed" "Task completed successfully" "$PLAN_DIR"
elif echo "$RESULT" | grep -q "TASK_BLOCKED\|ERROR\|error"; then
  log_task_complete "$NEXT_TASK" "blocked" "Task encountered issues" "$PLAN_DIR"
else
  log_task_complete "$NEXT_TASK" "completed" "Iteration finished" "$PLAN_DIR"
fi

COMPLETED_COUNT=$(grep -c "^\- \[x\]" "$TASKS_FILE" 2>/dev/null || echo "0")
REMAINING_COUNT=$(grep -c "^\- \[ \]" "$TASKS_FILE" 2>/dev/null || echo "0")
notify "Ralph Task Done ✅" "Plan: $PLAN_NAME
Completed: ${NEXT_TASK:0:40}
Progress: $COMPLETED_COUNT done, $REMAINING_COUNT remaining"

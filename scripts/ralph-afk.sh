#!/bin/bash
# Run Ralph in AFK loop mode
# Usage: ralph-afk <plan-dir> <iterations> [model]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ralph-afk <plan-dir> <iterations> [model]"
  echo "Example: ralph-afk plans/260109-1430-my-feature/ 5"
  echo "Models: haiku, sonnet, opus, auto (default)"
  exit 1
fi

export PLAN_DIR="$1"
ITERATIONS="$2"
MODEL_OVERRIDE="${3:-auto}"

# Verify plan exists
if [ ! -f "$PLAN_DIR/tasks.md" ]; then
  echo "Error: $PLAN_DIR/tasks.md not found"
  echo "Run: ralph-init <slug> to create a plan"
  exit 1
fi

# Notification helper (macOS)
notify() {
  local title="$1"
  local msg="$2"
  say "$msg" 2>/dev/null &
  osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
}

echo "=== Ralph AFK Mode ==="
echo "Plan: $PLAN_DIR"
echo "Iterations: $ITERATIONS"
echo "Model: $MODEL_OVERRIDE"
echo "======================"

for ((i=1; i<=$ITERATIONS; i++)); do
  # Re-source to get fresh task detection each iteration
  source "$SCRIPT_DIR/ralph-workflow.sh"

  if [ "$MODEL_OVERRIDE" = "auto" ]; then
    MODEL="$RALPH_MODEL"
  else
    MODEL="$MODEL_OVERRIDE"
  fi

  echo ""
  echo "=== Iteration $i of $ITERATIONS ==="
  echo "Task: $NEXT_TASK"
  echo "Model: $MODEL"
  echo "=================================="

  if [ -z "$NEXT_TASK" ]; then
    echo "No more tasks found."
    notify "Ralph Complete" "All tasks done!"
    exit 0
  fi

  result=$(claude --model "$MODEL" --dangerously-skip-permissions -p "$RALPH_WORKFLOW $RALPH_COMPLETE_MSG")

  echo "$result"

  # Check for unique completion signal (not partial matches)
  if [[ "$result" == *"ALL_TASKS_DONE"* ]]; then
    echo ""
    echo "All tasks complete after $i iterations."
    notify "Ralph Complete" "All tasks done!"
    exit 0
  fi
done

echo ""
echo "Reached iteration limit ($ITERATIONS). Check progress.md for status."
notify "Ralph Done" "Iteration limit reached"

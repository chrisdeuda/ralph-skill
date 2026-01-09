#!/bin/bash
# Run a single Ralph iteration
# Usage: ralph-once <plan-dir> [model]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
  echo "Usage: ralph-once <plan-dir> [model]"
  echo "Example: ralph-once plans/260109-1430-my-feature/"
  echo "Models: haiku, sonnet, opus (default: auto-detect)"
  exit 1
fi

export PLAN_DIR="$1"
MODEL_OVERRIDE="${2:-}"

# Verify plan exists
if [ ! -f "$PLAN_DIR/tasks.md" ]; then
  echo "Error: $PLAN_DIR/tasks.md not found"
  echo "Run: ralph-init <slug> to create a plan"
  exit 1
fi

# Load workflow
source "$SCRIPT_DIR/ralph-workflow.sh"

# Determine model
if [ -n "$MODEL_OVERRIDE" ]; then
  MODEL="$MODEL_OVERRIDE"
else
  MODEL="$RALPH_MODEL"
fi

echo "=== Ralph Single Task ==="
echo "Plan: $PLAN_DIR"
echo "Next task: $NEXT_TASK"
echo "Model: $MODEL (auto-detected: $RALPH_MODEL)"
echo "========================="

if [ -z "$NEXT_TASK" ]; then
  echo "No incomplete tasks found in $PLAN_DIR/tasks.md"
  exit 0
fi

claude --model "$MODEL" --dangerously-skip-permissions -p "$RALPH_WORKFLOW $RALPH_COMPLETE_MSG"

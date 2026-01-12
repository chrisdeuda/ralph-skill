#!/bin/bash
# Run Ralph in AFK loop mode
# Usage: ralph-afk <plan-dir> <iterations> [model] [mode]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ralph-afk <plan-dir> <iterations> [model] [mode]"
  echo "Example: ralph-afk plans/260109-1430-my-feature/ 5"
  echo "         ralph-afk plans/260109-feature/ 10 auto prototype"
  echo "Models: haiku, sonnet, opus, auto (default)"
  echo "Modes: prototype (fast), production (quality, default)"
  exit 1
fi

export PLAN_DIR="$1"
ITERATIONS="$2"
MODEL_OVERRIDE="${3:-auto}"
export RALPH_MODE="${4:-production}"

# Verify plan exists
if [ ! -f "$PLAN_DIR/tasks.md" ] && [ ! -f "$PLAN_DIR/plan.md" ]; then
  echo "Error: No tasks.md or plan.md found in $PLAN_DIR"
  echo "Run: ralph-init <slug> to create a plan"
  exit 1
fi

# Load shared utilities
source "$SCRIPT_DIR/ralph-utils.sh"

echo "=== Ralph AFK Mode ==="
echo "Plan: $PLAN_DIR"
echo "Iterations: $ITERATIONS"
echo "Model: $MODEL_OVERRIDE"
echo "Mode: $RALPH_MODE"
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
  echo "Mode: $RALPH_MODE"
  echo "Checkpoint: $IS_CHECKPOINT"
  echo "=================================="

  if [ -z "$NEXT_TASK" ]; then
    echo "No more tasks found."
    notify "Ralph Complete" "All tasks done!"
    exit 0
  fi

  # CHECKPOINT DETECTION - pause for manual verification
  if [ "$IS_CHECKPOINT" = "yes" ]; then
    echo ""
    echo "⚠️  CHECKPOINT DETECTED: $NEXT_TASK"
    echo "This task requires manual verification before continuing."
    echo ""

    # Extract AC (acceptance criteria) from the task if available
    AC_LINE=$(grep -A2 "CHECKPOINT" "$TASKS_FILE" 2>/dev/null | grep -i "AC:" | head -1 | sed 's/.*AC://' | xargs)

    # Build detailed popup message
    POPUP_MSG="🛑 CHECKPOINT - Manual Verification Required

📋 What to verify:
${AC_LINE:-Test the prototype works correctly}

✅ If working:
   Run: ralph-afk $PLAN_DIR $((ITERATIONS-i)) $MODEL_OVERRIDE production

❌ If broken:
   Fix the issues, then re-run prototype phase

Plan: $PLAN_NAME"

    # Show detailed popup
    osascript <<EOF &
display dialog "$POPUP_MSG" with title "Ralph Checkpoint" buttons {"Open Terminal", "OK"} default button "OK"
EOF
    say "Checkpoint reached. Please verify the prototype works." 2>/dev/null &

    # Mark checkpoint as complete and log it
    claude --model haiku --dangerously-skip-permissions -p "@$PROGRESS_FILE @$TASKS_FILE
    This is a CHECKPOINT task. Do the following:
    1. Append to progress.md:
       ---
       ## CHECKPOINT: Manual Verification
       **Time:** $(date +'%Y-%m-%d %H:%M')
       **Status:** Paused for manual testing
       Please verify Phase 1 works correctly before running Phase 2.
    2. Mark the checkpoint task as [x] complete in tasks.md
    3. Output: CHECKPOINT_COMPLETE"

    echo ""
    echo "✋ Ralph paused at checkpoint."
    echo ""
    echo "📋 VERIFICATION CHECKLIST:"
    echo "   ${AC_LINE:-Test the prototype works correctly}"
    echo ""
    echo "👉 NEXT STEPS:"
    echo "   ✅ If working: ralph-afk $PLAN_DIR $((ITERATIONS-i)) $MODEL_OVERRIDE production"
    echo "   ❌ If broken: Fix issues, then re-run prototype phase"
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

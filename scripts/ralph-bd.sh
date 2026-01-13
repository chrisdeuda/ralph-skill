#!/bin/bash
# Ralph + Beads Integration - Run Ralph with bd issue tracker
# Usage: ralph-bd [iterations] [model] [mode]
#
# Prerequisites:
#   - bd CLI v0.40+ installed
#   - bd init run in the project
#   - Ralph agent bead created (auto-created if missing)
#
# Integration:
#   - Uses `bd ready` to get tasks (replaces tasks.md)
#   - Uses `bd update/close` for status updates
#   - Uses `bd agent` for state/heartbeat tracking
#   - Uses `bd slot` to claim/release work

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$HOME/.ralph-pids"

# Configuration
RALPH_AGENT_ID="${RALPH_AGENT_ID:-ralph}"
HEARTBEAT_INTERVAL=30

# Track Claude PID for ralph-kill
track_pid() {
  echo "$1" >> "$PID_FILE"
}

untrack_pid() {
  if [ -f "$PID_FILE" ]; then
    sed -i '' "/$1/d" "$PID_FILE" 2>/dev/null || true
  fi
}

kill_and_cleanup() {
  local pid="$1"
  if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
    kill "$pid" 2>/dev/null || true
    sleep 0.5
    if ps -p "$pid" > /dev/null 2>&1; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
  untrack_pid "$pid"
}

# Load shared utilities
source "$SCRIPT_DIR/ralph-utils.sh"

# Check if bd is available
check_bd() {
  if ! command -v bd &> /dev/null; then
    echo "Error: bd CLI not found. Install from https://github.com/steveyegge/beads"
    exit 1
  fi

  BD_VERSION=$(bd --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  echo "Using bd version: $BD_VERSION"
}

# Initialize Ralph as agent bead (if not exists)
init_ralph_agent() {
  # Check if ralph agent exists and has gt:agent label
  if ! bd agent show "$RALPH_AGENT_ID" 2>/dev/null | grep -q "agent_state"; then
    echo "Creating Ralph agent bead..."
    # Create agent bead with proper type
    AGENT_JSON=$(bd create "Ralph Agent" --type=agent --role-type=polecat -d "Autonomous AI coding agent" --json 2>/dev/null)
    if [ -n "$AGENT_JSON" ]; then
      NEW_ID=$(echo "$AGENT_JSON" | jq -r '.id')
      # Add required gt:agent label
      bd label add "$NEW_ID" gt:agent 2>/dev/null || true
      RALPH_AGENT_ID="$NEW_ID"
      echo "Ralph agent created: $RALPH_AGENT_ID"
    fi
  fi

  # Set state to idle
  bd agent state "$RALPH_AGENT_ID" idle 2>/dev/null || true
  echo "Ralph agent ready: $RALPH_AGENT_ID"
}

# Get next ready task from bd
get_next_bd_task() {
  bd ready --json 2>/dev/null | jq -r '.[0] // empty'
}

# Get task ID from JSON
get_task_id() {
  echo "$1" | jq -r '.id // empty'
}

# Get task title from JSON
get_task_title() {
  echo "$1" | jq -r '.title // empty'
}

# Get task description from JSON
get_task_description() {
  echo "$1" | jq -r '.description // empty'
}

# Get task priority from JSON
get_task_priority() {
  echo "$1" | jq -r '.priority // 2'
}

# Claim task (attach to ralph hook slot)
claim_task() {
  local task_id="$1"
  bd slot set "$RALPH_AGENT_ID" hook "$task_id" 2>/dev/null || true
  bd update "$task_id" --status in_progress --json 2>/dev/null || true
  bd agent state "$RALPH_AGENT_ID" working 2>/dev/null || true
}

# Release task (clear hook slot)
release_task() {
  bd slot clear "$RALPH_AGENT_ID" hook 2>/dev/null || true
  bd agent state "$RALPH_AGENT_ID" idle 2>/dev/null || true
}

# Complete task
complete_task() {
  local task_id="$1"
  local reason="$2"
  bd close "$task_id" --reason "$reason" --json 2>/dev/null || true
  release_task
}

# Send heartbeat
send_heartbeat() {
  bd heartbeat "$RALPH_AGENT_ID" 2>/dev/null || true
}

# Model detection based on task keywords
detect_model() {
  local task="$1"

  if echo "$task" | grep -qiE "lint|test|fix|style|docs|mark|clean|format"; then
    echo "haiku"
  elif echo "$task" | grep -qiE "debug|architect|refactor.*complex|multi-file|restructure"; then
    echo "opus"
  else
    echo "sonnet"
  fi
}

# Build prompt for Claude with bd task context
build_bd_prompt() {
  local task_id="$1"
  local task_title="$2"
  local task_desc="$3"
  local mode="$4"

  local mode_instruction=""
  if [ "$mode" = "prototype" ]; then
    mode_instruction="MODE: PROTOTYPE - Make it work. NO tests, NO lint. Just core functionality."
  else
    mode_instruction="MODE: PRODUCTION - Quality code. Full tests, edge cases, maintainable."
  fi

  cat << EOF
[Ralph-BD] Task: $task_id - $task_title

$mode_instruction

## Task Details
**ID:** $task_id
**Title:** $task_title
**Description:** $task_desc

## Instructions
1. Read the task description carefully
2. Implement the required changes
3. Test your implementation (if production mode)
4. Commit changes with descriptive message

## On Completion
When done, output exactly: TASK_COMPLETE

## On Error
If blocked or unable to complete, output: TASK_BLOCKED: [reason]
EOF
}

# Sync beads to git
sync_beads() {
  echo "Syncing beads to git..."
  bd sync 2>/dev/null || true
}

# Main function
main() {
  local iterations="${1:-5}"
  local model_override="${2:-auto}"
  local mode="${3:-production}"

  export RALPH_MODE="$mode"

  echo "=== Ralph + Beads Mode ==="
  echo "Iterations: $iterations"
  echo "Model: $model_override"
  echo "Mode: $mode"
  echo "Agent: $RALPH_AGENT_ID"
  echo "=========================="

  # Initialize
  check_bd
  init_ralph_agent

  for ((i=1; i<=$iterations; i++)); do
    echo ""
    echo "=== Iteration $i of $iterations ==="

    # Get next task
    TASK_JSON=$(get_next_bd_task)

    if [ -z "$TASK_JSON" ] || [ "$TASK_JSON" = "null" ]; then
      echo "No ready tasks found."
      release_task
      notify "Ralph Complete" "All bd tasks done!" "default"
      sync_beads
      exit 0
    fi

    TASK_ID=$(get_task_id "$TASK_JSON")
    TASK_TITLE=$(get_task_title "$TASK_JSON")
    TASK_DESC=$(get_task_description "$TASK_JSON")
    TASK_PRIORITY=$(get_task_priority "$TASK_JSON")

    echo "Task: $TASK_ID - $TASK_TITLE"
    echo "Priority: $TASK_PRIORITY"

    # Detect model
    if [ "$model_override" = "auto" ]; then
      MODEL=$(detect_model "$TASK_TITLE $TASK_DESC")
    else
      MODEL="$model_override"
    fi
    echo "Model: $MODEL"

    # Claim task
    claim_task "$TASK_ID"
    send_heartbeat

    # Build prompt
    PROMPT=$(build_bd_prompt "$TASK_ID" "$TASK_TITLE" "$TASK_DESC" "$mode")

    # Run Claude
    OUTPUT_FILE=$(mktemp)
    claude --model "$MODEL" --dangerously-skip-permissions -p "$PROMPT" > "$OUTPUT_FILE" 2>&1 &
    CLAUDE_PID=$!
    track_pid "$CLAUDE_PID"

    # Heartbeat loop while Claude runs
    while ps -p "$CLAUDE_PID" > /dev/null 2>&1; do
      sleep $HEARTBEAT_INTERVAL
      send_heartbeat
    done

    wait $CLAUDE_PID || true
    RESULT=$(cat "$OUTPUT_FILE")
    rm -f "$OUTPUT_FILE"

    kill_and_cleanup "$CLAUDE_PID"
    echo "$RESULT"

    # Check result
    if echo "$RESULT" | grep -q "TASK_COMPLETE"; then
      echo "Task $TASK_ID completed."
      complete_task "$TASK_ID" "Completed by Ralph"
      notify_task_done "$TASK_TITLE"
    elif echo "$RESULT" | grep -q "TASK_BLOCKED"; then
      BLOCK_REASON=$(echo "$RESULT" | grep -oP 'TASK_BLOCKED: \K.*' | head -1)
      echo "Task $TASK_ID blocked: $BLOCK_REASON"
      bd update "$TASK_ID" --status blocked --json 2>/dev/null || true
      bd agent state "$RALPH_AGENT_ID" stuck 2>/dev/null || true
      notify_checkpoint "Task blocked: $BLOCK_REASON"
      release_task
    else
      echo "Task iteration complete (no explicit signal)"
      # Assume success, complete the task
      complete_task "$TASK_ID" "Iteration complete"
    fi

    send_heartbeat
  done

  echo ""
  echo "Reached iteration limit ($iterations)."
  release_task
  sync_beads
  notify "Ralph Paused" "Iteration limit reached" "default"
}

# Help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Ralph + Beads Integration"
  echo ""
  echo "Usage: ralph-bd [iterations] [model] [mode]"
  echo ""
  echo "Arguments:"
  echo "  iterations  Number of tasks to process (default: 5)"
  echo "  model       haiku, sonnet, opus, auto (default: auto)"
  echo "  mode        prototype, production (default: production)"
  echo ""
  echo "Environment:"
  echo "  RALPH_AGENT_ID   Agent bead ID (default: ralph)"
  echo "  RALPH_NTFY_TOPIC ntfy.sh topic for push notifications"
  echo ""
  echo "Examples:"
  echo "  ralph-bd                    # 5 iterations, auto model, production"
  echo "  ralph-bd 10                 # 10 iterations"
  echo "  ralph-bd 5 sonnet prototype # prototype mode with sonnet"
  exit 0
fi

main "$@"

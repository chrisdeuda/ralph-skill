#!/bin/bash
# Shared workflow for Ralph automation
# Used by: ralph-once.sh, ralph-afk.sh

# Require PLAN_DIR to be set
if [ -z "$PLAN_DIR" ]; then
  echo "Error: PLAN_DIR not set"
  exit 1
fi

TASKS_FILE="$PLAN_DIR/tasks.md"
PROGRESS_FILE="$PLAN_DIR/progress.md"

# Model selection based on task keywords
detect_model() {
  local task="$1"

  # Simple tasks -> Haiku (cheapest)
  if echo "$task" | grep -qiE "lint|test|fix|style|docs|mark|clean|format|reset|clear"; then
    echo "haiku"
  # Complex tasks -> Opus (most capable)
  elif echo "$task" | grep -qiE "debug|architect|refactor.*complex|multi-file|restructure"; then
    echo "opus"
  # Default medium tasks -> Sonnet
  else
    echo "sonnet"
  fi
}

# Get next incomplete task from tasks.md
get_next_task() {
  grep -m1 "^\- \[ \]" "$TASKS_FILE" 2>/dev/null | sed 's/- \[ \] //' || echo ""
}

# Export for scripts
NEXT_TASK=$(get_next_task)
RALPH_MODEL=$(detect_model "$NEXT_TASK")
export NEXT_TASK RALPH_MODEL TASKS_FILE PROGRESS_FILE

# Main workflow prompt
RALPH_WORKFLOW="@$TASKS_FILE @$PROGRESS_FILE \\
1. Read the tasks.md and progress.md files. \\
2. Find the next incomplete task (unchecked checkbox). \\
3. BEFORE starting, append to progress.md using this EXACT format: \\
   --- \\
   ## Task N: [task description] \\
   **Status:** In Progress | **Time:** [YYYY-MM-DD HH:MM] | **Model:** $RALPH_MODEL \\
   ### Plan \\
   - [step 1] \\
   - [step 2] \\
4. Implement the task AND write tests to verify the acceptance criteria (AC). \\
5. IMPORTANT - Append-only logging: As you work, APPEND to progress.md (never update/overwrite previous entries): \\
   ### Actions \\
   - [HH:MM] [action taken] \\
   - [HH:MM] [file created/modified] \\
   If something fails or you need to retry: \\
   - [HH:MM] ERROR: [what failed] \\
   - [HH:MM] RETRY: [what you are trying instead] \\
   - [HH:MM] INVESTIGATING: [what you are looking into] \\
   This creates a thought trail showing your problem-solving process. \\
6. Run linting if available: npm run lint -- --fix (skip if no lint script) \\
7. Run unit tests if available: npm test (must pass before completing) \\
   If tests fail, append: \\
   - [HH:MM] TEST FAILED: [which test, why] \\
   - [HH:MM] FIX ATTEMPT: [what you are changing] \\
8. When done, append to progress.md (do not modify earlier entries): \\
   ### Result \\
   **Status:** Completed | **Completed:** [HH:MM] \\
   [what was achieved] \\
   ### Tests \\
   - [test file]: [N] tests (PASS/FAIL) \\
9. Mark the task as complete in tasks.md by changing [ ] to [x]. \\
10. Commit all changes with a descriptive message. \\
ONLY WORK ON A SINGLE TASK."

# Completion signal for loop detection (unique to avoid false matches)
RALPH_COMPLETE_MSG='If all tasks in tasks.md are complete (no unchecked boxes remain), output exactly: ALL_TASKS_DONE'

export RALPH_WORKFLOW RALPH_COMPLETE_MSG

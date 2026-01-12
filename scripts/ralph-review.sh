#!/bin/bash
# Review PRD before implementation
# Usage: ralph-review <plan-dir>
# Analyzes tasks and surfaces unclear requirements

set -e

if [ -z "$1" ]; then
  echo "Usage: ralph-review <plan-dir>"
  echo "Example: ralph-review plans/260109-my-feature/"
  echo ""
  echo "Analyzes your PRD and asks clarifying questions before Ralph runs."
  exit 1
fi

PLAN_DIR="$1"

# Find task source
if [ -f "$PLAN_DIR/tasks.md" ]; then
  TASK_FILE="$PLAN_DIR/tasks.md"
elif [ -f "$PLAN_DIR/plan.md" ]; then
  TASK_FILE="$PLAN_DIR/plan.md"
else
  echo "Error: No tasks.md or plan.md found in $PLAN_DIR"
  exit 1
fi

echo "=== Ralph PRD Review ==="
echo "Analyzing: $TASK_FILE"
echo "========================"
echo ""

# Build review prompt
REVIEW_PROMPT="You are reviewing a PRD before autonomous implementation begins.

Read @$TASK_FILE carefully and:

1. **Surface Unclear Requirements** - List any tasks that are ambiguous:
   - Missing API endpoints or data shapes?
   - Unclear acceptance criteria?
   - Missing error handling expectations?
   - Assumptions that need validation?

2. **Identify Risk Points** - Which tasks could waste time if assumptions are wrong?
   - API integrations (what's the contract?)
   - State management (what's the data flow?)
   - External dependencies (what versions?)

3. **Suggest Clarifications** - For each unclear item, propose:
   - Specific question to resolve it
   - Default assumption if not answered

4. **Validate Phase Structure** - Check if PRD follows prototype-first:
   - Phase 1 should be 'make it work' (no tests, no lint)
   - Should have CHECKPOINT before quality work
   - Phase 2+ for tests, lint, polish

Output format:
## Unclear Requirements
- [ ] Task N: [issue] → Question: [what to ask]

## Risk Points
- Task N: [what could go wrong]

## Missing Phase Structure
[suggestions if PRD jumps straight to tests/quality]

## Ready to Run?
[YES if clear, NO if needs clarification]"

claude -p "$REVIEW_PROMPT"

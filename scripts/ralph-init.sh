#!/bin/bash
# Initialize or find a Ralph plan
# Usage: ralph-init <slug> [description]
#
# If a plan with matching slug exists, it will be reused.
# Works with both standalone tasks.md AND /plan output (plan.md + phase-*.md)

set -e

if [ -z "$1" ]; then
  echo "Usage: ralph-init <slug> [description]"
  echo "Example: ralph-init user-auth 'User authentication feature'"
  echo ""
  echo "This will:"
  echo "  1. Search for existing plans matching the slug"
  echo "  2. Reuse existing plan if found"
  echo "  3. Create new plan only if none exists"
  exit 1
fi

SLUG="$1"
DESC="${2:-$SLUG}"
DATE=$(date +%y%m%d)

# Search for existing plans with this slug (any date/time prefix)
EXISTING=$(find plans -maxdepth 1 -type d -name "*-${SLUG}" 2>/dev/null | sort -r | head -1)

if [ -n "$EXISTING" ]; then
  echo "Found existing plan: $EXISTING"

  # Check if it has tasks
  if [ -f "$EXISTING/tasks.md" ]; then
    PENDING=$(grep -c "^\- \[ \]" "$EXISTING/tasks.md" 2>/dev/null || echo 0)
    DONE=$(grep -c "^\- \[x\]" "$EXISTING/tasks.md" 2>/dev/null || echo 0)
    echo "  tasks.md: $DONE done, $PENDING pending"
  fi

  if [ -f "$EXISTING/plan.md" ]; then
    PHASES=$(ls "$EXISTING"/phase-*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "  plan.md + $PHASES phase files (from /plan)"
  fi

  echo ""
  read -p "Use this plan? [Y/n] " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    PLAN_DIR="$EXISTING"
    echo "Using existing plan: $PLAN_DIR"
  else
    # Create new with timestamp to differentiate
    TIME=$(date +%H%M)
    PLAN_DIR="plans/${DATE}-${TIME}-${SLUG}"
    echo "Creating new plan: $PLAN_DIR"
  fi
else
  # No existing plan, create new (without time for cleaner names)
  PLAN_DIR="plans/${DATE}-${SLUG}"

  # If that exact path exists, add time
  if [ -d "$PLAN_DIR" ]; then
    TIME=$(date +%H%M)
    PLAN_DIR="plans/${DATE}-${TIME}-${SLUG}"
  fi

  echo "Creating new plan: $PLAN_DIR"
fi

# Create directory if needed
mkdir -p "$PLAN_DIR"

# Only create tasks.md if no task source exists
if [ ! -f "$PLAN_DIR/tasks.md" ] && [ ! -f "$PLAN_DIR/plan.md" ]; then
  cat > "$PLAN_DIR/tasks.md" << EOF
# $DESC

## Overview
<!-- Brief description of the feature/task -->

## Tasks

<!-- Add tasks with acceptance criteria -->
- [ ] Task 1 description
  - **AC:** Acceptance criteria here

- [ ] Task 2 description
  - **AC:** What "done" looks like

## Notes
<!-- Any additional context for Ralph -->
EOF
  echo "Created: $PLAN_DIR/tasks.md"
fi

# Create progress.md if not exists
if [ ! -f "$PLAN_DIR/progress.md" ]; then
  cat > "$PLAN_DIR/progress.md" << EOF
# Progress: $DESC

Started: $(date +"%Y-%m-%d %H:%M")

---
EOF
  echo "Created: $PLAN_DIR/progress.md"
fi

echo ""
echo "Plan ready at: $PLAN_DIR"
echo ""
echo "Next steps:"
if [ -f "$PLAN_DIR/plan.md" ]; then
  echo "  Plan created by /plan - Ralph will use phase files"
  echo "  Run: ralph-once $PLAN_DIR"
else
  echo "  1. Edit $PLAN_DIR/tasks.md to add your tasks"
  echo "  2. Run: ralph-once $PLAN_DIR"
fi
echo "  Or AFK: ralph-afk $PLAN_DIR 5"

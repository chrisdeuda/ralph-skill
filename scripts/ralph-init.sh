#!/bin/bash
# Initialize a new Ralph plan
# Usage: ralph-init <slug> [description]

set -e

if [ -z "$1" ]; then
  echo "Usage: ralph-init <slug> [description]"
  echo "Example: ralph-init user-auth 'User authentication feature'"
  exit 1
fi

SLUG="$1"
DESC="${2:-$SLUG}"
DATE=$(date +%y%m%d)
TIME=$(date +%H%M)
PLAN_DIR="plans/${DATE}-${TIME}-${SLUG}"

# Create plan directory
mkdir -p "$PLAN_DIR"

# Create tasks.md template
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

# Create empty progress.md
cat > "$PLAN_DIR/progress.md" << EOF
# Progress: $DESC

Started: $(date +"%Y-%m-%d %H:%M")

---
EOF

echo "Created Ralph plan at: $PLAN_DIR"
echo ""
echo "Next steps:"
echo "  1. Edit $PLAN_DIR/tasks.md to add your tasks"
echo "  2. Run: ralph-once $PLAN_DIR"
echo "  3. Or AFK: ralph-afk $PLAN_DIR 5"

#!/bin/bash
# Ralph Status Dashboard
# Shows progress across all plans
# Usage: ralph-status [watch]

PLANS_DIR="${1:-plans}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_status() {
  clear
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}                    RALPH STATUS DASHBOARD                      ${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo ""

  # Check if plans directory exists
  if [ ! -d "$PLANS_DIR" ]; then
    echo -e "${RED}No plans directory found at: $PLANS_DIR${NC}"
    exit 1
  fi

  # Find all plan directories
  for plan_dir in "$PLANS_DIR"/*/; do
    [ -d "$plan_dir" ] || continue

    plan_name=$(basename "$plan_dir")

    # Skip reports directory
    [[ "$plan_name" == "reports" ]] && continue

    # Count tasks
    total=0
    done=0

    # Check tasks.md
    if [ -f "$plan_dir/tasks.md" ]; then
      total=$((total + $(grep -c "^\- \[ \]" "$plan_dir/tasks.md" 2>/dev/null || echo 0)))
      total=$((total + $(grep -c "^\- \[x\]" "$plan_dir/tasks.md" 2>/dev/null || echo 0)))
      done=$((done + $(grep -c "^\- \[x\]" "$plan_dir/tasks.md" 2>/dev/null || echo 0)))
    fi

    # Check phase files
    for phase in "$plan_dir"/phase-*.md; do
      [ -f "$phase" ] || continue
      total=$((total + $(grep -c "^\- \[ \]" "$phase" 2>/dev/null || echo 0)))
      total=$((total + $(grep -c "^\- \[x\]" "$phase" 2>/dev/null || echo 0)))
      done=$((done + $(grep -c "^\- \[x\]" "$phase" 2>/dev/null || echo 0)))
    done

    # Skip if no tasks
    [ "$total" -eq 0 ] && continue

    # Calculate percentage
    if [ "$total" -gt 0 ]; then
      pct=$((done * 100 / total))
    else
      pct=0
    fi

    # Status indicator
    if [ "$done" -eq "$total" ]; then
      status="${GREEN}✓ DONE${NC}"
    elif [ "$done" -gt 0 ]; then
      status="${YELLOW}▶ IN PROGRESS${NC}"
    else
      status="${RED}○ PENDING${NC}"
    fi

    # Progress bar
    bar_width=20
    filled=$((pct * bar_width / 100))
    empty=$((bar_width - filled))
    bar=$(printf "%${filled}s" | tr ' ' '█')
    bar_empty=$(printf "%${empty}s" | tr ' ' '░')

    echo -e "${BLUE}┌─${NC} ${plan_name}"
    echo -e "${BLUE}│${NC}  $status  [$bar$bar_empty] $pct% ($done/$total tasks)"

    # Show current task if in progress
    if [ -f "$plan_dir/tasks.md" ]; then
      current=$(grep -m1 "^\- \[ \]" "$plan_dir/tasks.md" 2>/dev/null | sed 's/- \[ \] //')
      [ -n "$current" ] && echo -e "${BLUE}│${NC}  Next: ${current:0:50}..."
    fi

    # Show last activity from progress.md
    if [ -f "$plan_dir/progress.md" ]; then
      last_time=$(grep -o "\*\*Time:\*\* [0-9-]* [0-9:]*" "$plan_dir/progress.md" 2>/dev/null | tail -1 | sed 's/\*\*Time:\*\* //')
      [ -n "$last_time" ] && echo -e "${BLUE}│${NC}  Last: $last_time"
    fi

    echo -e "${BLUE}└─${NC}"
    echo ""
  done

  # Show global log tail
  if [ -f "$PLANS_DIR/ralph-log.md" ]; then
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    RECENT ACTIVITY (ralph-log.md)             ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    tail -20 "$PLANS_DIR/ralph-log.md" 2>/dev/null
  fi

  echo ""
  echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
  echo -e "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "Watch global log: ${YELLOW}tail -f plans/ralph-log.md${NC}"
}

# Check if watch mode
if [ "$1" = "watch" ] || [ "$2" = "watch" ]; then
  while true; do
    show_status
    sleep 5
  done
else
  show_status
fi

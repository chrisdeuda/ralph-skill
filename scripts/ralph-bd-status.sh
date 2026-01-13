#!/bin/bash
# Ralph + Beads Status - Show Ralph agent status and work queue
# Usage: ralph-bd-status

# Auto-detect Ralph agent if not specified
if [ -z "$RALPH_AGENT_ID" ]; then
  RALPH_AGENT_ID=$(bd list --type=agent --json 2>/dev/null | jq -r '.[0].id // "ralph"')
fi

echo "=== Ralph + Beads Status ==="
echo ""

# Check bd availability
if ! command -v bd &> /dev/null; then
  echo "Error: bd CLI not found"
  exit 1
fi

# Agent status
echo "## Agent: $RALPH_AGENT_ID"
AGENT_INFO=$(bd agent show "$RALPH_AGENT_ID" 2>/dev/null)
if [ -n "$AGENT_INFO" ]; then
  STATE=$(echo "$AGENT_INFO" | grep "agent_state:" | awk '{print $2}')
  HEARTBEAT=$(echo "$AGENT_INFO" | grep "last_activity:" | cut -d: -f2- | xargs)
  HOOK=$(echo "$AGENT_INFO" | grep "hook:" | awk '{print $2}')

  echo "State: ${STATE:-(not set)}"
  echo "Heartbeat: ${HEARTBEAT:-(never)}"
  echo "Current work: ${HOOK:-(none)}"
else
  echo "Ralph agent not found. Run ralph-bd to initialize."
fi

echo ""

# Ready tasks
echo "## Ready Tasks"
READY_TASKS=$(bd ready --json 2>/dev/null)
READY_COUNT=$(echo "$READY_TASKS" | jq 'length // 0')

if [ "$READY_COUNT" -gt 0 ]; then
  echo "Found $READY_COUNT task(s) ready:"
  echo "$READY_TASKS" | jq -r '.[] | "  [\(.id)] P\(.priority) - \(.title)"'
else
  echo "No tasks ready"
fi

echo ""

# In-progress tasks
echo "## In Progress"
IN_PROGRESS=$(bd list --status in_progress --json 2>/dev/null)
IP_COUNT=$(echo "$IN_PROGRESS" | jq 'length // 0')

if [ "$IP_COUNT" -gt 0 ]; then
  echo "$IN_PROGRESS" | jq -r '.[] | "  [\(.id)] \(.title)"'
else
  echo "None"
fi

echo ""

# Stats
echo "## Stats"
bd stats 2>/dev/null | head -10 || echo "Run 'bd stats' for full statistics"

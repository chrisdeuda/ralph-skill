#!/bin/bash
# Kill Claude processes spawned by Ralph
# Only kills processes tracked in ~/.ralph-pids, not all claude processes

PID_FILE="$HOME/.ralph-pids"

usage() {
  echo "Usage: ralph-kill [options]"
  echo ""
  echo "Options:"
  echo "  -a, --all     Kill ALL claude processes (use with caution)"
  echo "  -l, --list    List tracked Ralph Claude processes"
  echo "  -c, --clean   Clean up stale PIDs from tracking file"
  echo "  -h, --help    Show this help"
  echo ""
  echo "Default: Kill only Claude processes spawned by Ralph"
}

list_pids() {
  if [ ! -f "$PID_FILE" ]; then
    echo "No Ralph processes tracked."
    return
  fi

  echo "Tracked Ralph Claude processes:"
  while read -r pid; do
    if ps -p "$pid" > /dev/null 2>&1; then
      echo "  PID $pid - running"
    else
      echo "  PID $pid - (dead)"
    fi
  done < "$PID_FILE"
}

clean_pids() {
  if [ ! -f "$PID_FILE" ]; then
    echo "No PID file to clean."
    return
  fi

  local temp_file=$(mktemp)
  local cleaned=0

  while read -r pid; do
    if ps -p "$pid" > /dev/null 2>&1; then
      echo "$pid" >> "$temp_file"
    else
      ((cleaned++))
    fi
  done < "$PID_FILE"

  mv "$temp_file" "$PID_FILE"
  echo "Cleaned $cleaned stale PIDs."
}

kill_ralph_processes() {
  if [ ! -f "$PID_FILE" ]; then
    echo "No Ralph processes to kill."
    return
  fi

  local killed=0

  while read -r pid; do
    if ps -p "$pid" > /dev/null 2>&1; then
      echo "Killing PID $pid..."
      kill "$pid" 2>/dev/null
      ((killed++))
    fi
  done < "$PID_FILE"

  # Clear the PID file
  > "$PID_FILE"

  echo "✅ Killed $killed Ralph Claude process(es)."
}

kill_all_claude() {
  echo "⚠️  Killing ALL claude processes..."
  local count=$(pgrep -f "claude" | wc -l | tr -d ' ')
  pkill -f "claude" 2>/dev/null
  echo "Killed $count claude process(es)."

  # Also clear Ralph PID file
  > "$PID_FILE" 2>/dev/null
}

# Parse arguments
case "${1:-}" in
  -a|--all)
    kill_all_claude
    ;;
  -l|--list)
    list_pids
    ;;
  -c|--clean)
    clean_pids
    ;;
  -h|--help)
    usage
    ;;
  "")
    kill_ralph_processes
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
esac

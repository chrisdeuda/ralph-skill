#!/bin/bash
# Publish Ralph skill commands to global commands directory
# Usage: ralph-publish-commands.sh [--dry-run]
#
# This syncs commands from ~/.claude/skills/ralph/commands/
# to ~/.claude/commands/ralph/ so they show up as /ck:ralph:* commands

set -e

SKILL_DIR="$HOME/.claude/skills/ralph"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"
RALPH_COMMANDS_DIR="$GLOBAL_COMMANDS_DIR/ralph"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo -e "${YELLOW}DRY RUN - no files will be modified${NC}"
fi

echo -e "${BLUE}Publishing Ralph commands to global directory...${NC}"

# Ensure directories exist
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$RALPH_COMMANDS_DIR"
fi

# Track counts
copied=0
skipped=0

# Process each command file in skill directory
for cmd_file in "$SKILL_DIR/commands/"*.md; do
  [[ -f "$cmd_file" ]] || continue

  filename=$(basename "$cmd_file")

  # Main ralph.md goes to global root, others go to ralph/ subfolder
  if [[ "$filename" == "ralph.md" ]]; then
    dest="$GLOBAL_COMMANDS_DIR/ralph.md"
  else
    # Convert ralph-init.md to init.md for /ck:ralph:init naming
    subcommand_name="${filename#ralph-}"
    dest="$RALPH_COMMANDS_DIR/$subcommand_name"
  fi

  # Check if update needed
  if [[ -f "$dest" ]]; then
    if diff -q "$cmd_file" "$dest" > /dev/null 2>&1; then
      echo -e "  ${YELLOW}SKIP${NC} $filename (unchanged)"
      ((skipped++))
      continue
    fi
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "  ${GREEN}WOULD COPY${NC} $cmd_file -> $dest"
  else
    cp "$cmd_file" "$dest"
    echo -e "  ${GREEN}COPIED${NC} $filename -> $dest"
  fi
  ((copied++))
done

echo ""
echo -e "${GREEN}Done!${NC} Copied: $copied, Skipped: $skipped"

# Regenerate catalog if not dry run
if [[ "$DRY_RUN" == false && "$copied" -gt 0 ]]; then
  echo ""
  echo -e "${BLUE}Regenerating commands catalog...${NC}"
  cd "$HOME" && python3 "$HOME/.claude/scripts/scan_commands.py" 2>/dev/null | tail -5
fi

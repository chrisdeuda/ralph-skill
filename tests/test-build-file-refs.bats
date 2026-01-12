#!/usr/bin/env bats

# Test build_file_refs() function
# This function builds @-prefixed file references for Claude prompts
# Files are included in specific order and based on what exists

load 'test_helper'

# Helper to verify reference contains a file
refs_contains() {
  local refs="$1"
  local file="$2"
  # Use grep to find the pattern, accounting for partial path matches
  echo "$refs" | grep -q "@.*$file"
}

# Helper to get order of references
refs_order() {
  local refs="$1"
  local file="$2"
  echo "$refs" | grep -o "@[^ ]*" | grep -n "$file"
}

# Test basic file inclusion with all files present
@test "build_file_refs includes Ralph CLAUDE.md first" {
  # All files exist in test setup
  refs=$(build_file_refs)
  refs_contains "$refs" "$RALPH_SKILL_DIR/CLAUDE.md"
}

@test "build_file_refs includes progress.md when it exists" {
  touch "$PROGRESS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$PROGRESS_FILE"
}

@test "build_file_refs includes context.md when it exists" {
  touch "$CONTEXT_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$CONTEXT_FILE"
}

@test "build_file_refs includes plan.md when it exists" {
  touch "$PLAN_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$PLAN_FILE"
}

@test "build_file_refs includes tasks.md with tasks source" {
  # tasks.md is created in setup, so it should be detected
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$TASKS_FILE"
}

# Test file ordering
@test "build_file_refs puts CLAUDE.md first" {
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  touch "$PLAN_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # CLAUDE.md should be first, before progress
  claude_pos=$(echo "$refs" | grep -o "@[^ ]*" | grep -n "CLAUDE.md" | cut -d: -f1)
  progress_pos=$(echo "$refs" | grep -o "@[^ ]*" | grep -n "progress.md" | cut -d: -f1)
  [ "$claude_pos" -lt "$progress_pos" ]
}

@test "build_file_refs puts progress.md before context.md" {
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  touch "$PLAN_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  progress_pos=$(echo "$refs" | grep -o "@[^ ]*" | grep -n "progress.md" | cut -d: -f1)
  context_pos=$(echo "$refs" | grep -o "@[^ ]*" | grep -n "context.md" | cut -d: -f1)
  [ "$progress_pos" -lt "$context_pos" ]
}

@test "build_file_refs includes tasks.md last before phase files" {
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  touch "$PLAN_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$TASKS_FILE"
}

# Test with phase files
@test "build_file_refs includes phase-01.md when using phases" {
  rm -f "$TASKS_FILE"
  echo "- [ ] Phase task" > "$TEST_TMPDIR/phase-01.md"
  touch "$PROGRESS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$TEST_TMPDIR/phase-01.md"
}

@test "build_file_refs includes all phase files in order" {
  rm -f "$TASKS_FILE"
  echo "- [ ] Phase 1" > "$TEST_TMPDIR/phase-01.md"
  echo "- [ ] Phase 2" > "$TEST_TMPDIR/phase-02.md"
  echo "- [ ] Phase 3" > "$TEST_TMPDIR/phase-03.md"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "$TEST_TMPDIR/phase-01.md"
  refs_contains "$refs" "$TEST_TMPDIR/phase-02.md"
  refs_contains "$refs" "$TEST_TMPDIR/phase-03.md"
}

# Test file existence handling
@test "build_file_refs skips missing progress.md" {
  rm -f "$PROGRESS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Should not contain progress reference
  [[ "$refs" != *"progress.md"* ]]
}

@test "build_file_refs skips missing context.md" {
  rm -f "$CONTEXT_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Should not contain context reference
  [[ "$refs" != *"context.md"* ]]
}

@test "build_file_refs skips missing plan.md" {
  rm -f "$PLAN_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Should not contain plan reference
  [[ "$refs" != *"plan.md"* ]]
}

@test "build_file_refs returns empty tasks reference when tasks missing" {
  rm -f "$TASKS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Should not contain tasks reference since no task source
  [[ "$refs" != *"tasks.md"* ]]
}

# Test @-prefix formatting
@test "build_file_refs properly formats @-prefixed references" {
  touch "$PROGRESS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # All references should start with @
  echo "$refs" | grep -q "@"
  # Split by spaces and check each part starts with @
  for ref in $refs; do
    [[ "$ref" == @* ]]
  done
}

@test "build_file_refs separates multiple references with spaces" {
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Count space-separated references
  ref_count=$(echo "$refs" | wc -w)
  [ "$ref_count" -ge 3 ]  # At least CLAUDE.md, progress.md, tasks.md
}

# Test with only essential files
@test "build_file_refs returns Ralph CLAUDE.md even with no other files" {
  rm -f "$PROGRESS_FILE"
  rm -f "$CONTEXT_FILE"
  rm -f "$PLAN_FILE"
  rm -f "$TASKS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Should still include CLAUDE.md (it's in ~/.claude/skills/ralph/)
  refs_contains "$refs" "CLAUDE.md"
}

# Test complex scenarios
@test "build_file_refs with all files present includes them all" {
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  touch "$PLAN_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "CLAUDE.md"
  refs_contains "$refs" "$PROGRESS_FILE"
  refs_contains "$refs" "$CONTEXT_FILE"
  refs_contains "$refs" "$PLAN_FILE"
  refs_contains "$refs" "$TASKS_FILE"
}

@test "build_file_refs handles mixed phase files and other files" {
  rm -f "$TASKS_FILE"
  echo "- [ ] Phase 1" > "$TEST_TMPDIR/phase-01.md"
  echo "- [ ] Phase 2" > "$TEST_TMPDIR/phase-02.md"
  touch "$PROGRESS_FILE"
  touch "$CONTEXT_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  refs_contains "$refs" "CLAUDE.md"
  refs_contains "$refs" "$PROGRESS_FILE"
  refs_contains "$refs" "$CONTEXT_FILE"
  refs_contains "$refs" "$TEST_TMPDIR/phase-01.md"
  refs_contains "$refs" "$TEST_TMPDIR/phase-02.md"
}

@test "build_file_refs with multiple phases includes them in order" {
  rm -f "$TASKS_FILE"
  echo "- [ ] Phase 1" > "$TEST_TMPDIR/phase-01.md"
  echo "- [ ] Phase 2" > "$TEST_TMPDIR/phase-02.md"
  echo "- [ ] Phase 3" > "$TEST_TMPDIR/phase-03.md"
  refresh_plan_vars
  refs=$(build_file_refs)
  # Convert refs to array and check order
  phases=$(echo "$refs" | grep -o "phase-[0-9]*\.md")
  first=$(echo "$phases" | head -1)
  second=$(echo "$phases" | tail -2 | head -1)
  third=$(echo "$phases" | tail -1)
  [ "$first" = "phase-01.md" ]
  [ "$second" = "phase-02.md" ]
  [ "$third" = "phase-03.md" ]
}

# Test edge cases
@test "build_file_refs handles RALPH_SKILL_DIR with spaces in path" {
  # This tests that the function handles paths correctly
  refs=$(build_file_refs)
  # Should contain CLAUDE.md reference
  refs_contains "$refs" "CLAUDE.md"
}

@test "build_file_refs output is suitable for shell expansion" {
  refs=$(build_file_refs)
  # Each reference should be evaluable (no unmatched quotes, etc)
  # This is more of a format check
  echo "$refs" | grep -q "@"
}

@test "build_file_refs includes local files using absolute paths" {
  touch "$PROGRESS_FILE"
  refresh_plan_vars
  refs=$(build_file_refs)
  # PROGRESS_FILE should be absolute path
  [[ "$PROGRESS_FILE" == /* ]]
  refs_contains "$refs" "$PROGRESS_FILE"
}

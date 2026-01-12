#!/usr/bin/env bats

# Test build_session_name() function
# This function creates session names for Claude picker display
# Format: [Ralph] plan-slug: T1 - first 40 chars of task

load 'test_helper'

# Test basic session name format
@test "build_session_name returns proper format" {
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == "[Ralph]"* ]]
  [[ "$session" == *": T"* ]]
  [[ "$session" == *" - "* ]]
}

@test "build_session_name includes plan name" {
  refresh_plan_vars
  session=$(build_session_name)
  # Extract plan name from PLAN_NAME
  [[ "$session" == *"$PLAN_NAME"* ]]
}

@test "build_session_name starts with [Ralph]" {
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == "[Ralph]"* ]]
}

# Test task numbering
@test "build_session_name task number T1 with no completed tasks" {
  # Setup has one task that's unchecked
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *": T1 "* ]]
}

@test "build_session_name increments task number based on completed tasks" {
  # Create tasks file with one completed task
  echo "- [x] Completed task
- [ ] Next task" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *": T2 "* ]]
}

@test "build_session_name counts multiple completed tasks" {
  # Create tasks file with multiple completed tasks
  echo "- [x] Task 1
- [x] Task 2
- [x] Task 3
- [ ] Task 4" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *": T4 "* ]]
}

@test "build_session_name shows all completed tasks" {
  # 5 completed tasks means next task is T6
  echo "- [x] Task 1
- [x] Task 2
- [x] Task 3
- [x] Task 4
- [x] Task 5
- [ ] Task 6" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *": T6 "* ]]
}

# Test task preview
@test "build_session_name includes task preview after dash" {
  refresh_plan_vars
  session=$(build_session_name)
  # Session should have " - " followed by task preview
  [[ "$session" == *" - "* ]]
  # Extract part after " - "
  preview=${session#*" - "}
  [[ -n "$preview" ]]
}

@test "build_session_name truncates long task to 40 chars" {
  # Create a very long task name
  local long_task="This is a very long task that is definitely more than forty characters total"
  echo "- [ ] $long_task" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  # Extract preview part
  preview=${session#*" - "}
  # Preview should be at most 40 chars
  [ "${#preview}" -le 40 ]
}

@test "build_session_name shows first 40 chars of task exactly" {
  # Create task with more than 40 chars
  local task="This task is way longer than forty characters to test truncation"
  echo "- [ ] $task" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  # Extract preview
  preview=${session#*" - "}
  # Should be exactly 40 chars or less
  [ "${#preview}" -le 40 ]
  # Should start with the beginning of the task
  [[ "$preview" == "This task is way longer than forty cha"* ]]
}

@test "build_session_name handles short task names" {
  echo "- [ ] Short" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *" - Short"* ]]
}

@test "build_session_name preserves spaces in task preview" {
  echo "- [ ] Task with many    spaces" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *"Task with many    spaces"* ]]
}

# Test special characters
@test "build_session_name handles special characters in task" {
  echo "- [ ] Task: with (special) & characters!" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *"Task: with (special)"* ]]
}

@test "build_session_name includes quoted text in task" {
  echo '- [ ] Task with "quoted string" inside' > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *'Task with "quoted'* ]]
}

# Test plan name handling
@test "build_session_name handles numeric plan names" {
  # PLAN_NAME is set from directory name (basename of PLAN_DIR)
  # This test validates the plan name is included as-is
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *"$PLAN_NAME"* ]]
}

@test "build_session_name format has correct separators" {
  refresh_plan_vars
  session=$(build_session_name)
  # Should be: [Ralph] PLAN_NAME: TN - preview
  [[ "$session" == "[Ralph]"*": T"*" - "* ]]
}

# Test with no NEXT_TASK
@test "build_session_name handles empty NEXT_TASK" {
  echo "- [x] All done" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  # Should still have proper format even with no next task
  [[ "$session" == "[Ralph]"* ]]
  [[ "$session" == *": T"* ]]
}

# Test with realistic task descriptions
@test "build_session_name with realistic feature task" {
  echo "- [ ] Implement user authentication with JWT tokens" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *"Implement user authentication"* ]]
}

@test "build_session_name with realistic bug fix task" {
  echo "- [ ] Fix: database connection timeout after 30 seconds" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *"Fix: database connection timeout"* ]]
}

@test "build_session_name with milestone task" {
  echo "- [ ] CHECKPOINT: manual verification before deployment" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *"CHECKPOINT: manual verification"* ]]
}

# Test edge cases with task file
@test "build_session_name handles mixed checked and unchecked tasks" {
  echo "- [x] Done 1
- [x] Done 2
- [ ] Current task
- [ ] Next task
- [ ] Future task" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *": T3 "* ]]
}

@test "build_session_name with only checked tasks uses count + 1" {
  echo "- [x] Task 1
- [x] Task 2" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  [[ "$session" == *": T3 "* ]]
}

@test "build_session_name handles malformed checkbox markers gracefully" {
  echo "- [ ] Valid task
- invalid checkbox line
- [x] Another valid task" > "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  session=$(build_session_name)
  # Only counts properly formatted [x] markers
  [[ "$session" == *": T2 "* ]]
}

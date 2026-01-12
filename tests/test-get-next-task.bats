#!/usr/bin/env bats

# Test get_next_task() and related functions
# get_next_task() finds the next unchecked task from tasks.md or phase files
# This is critical for Ralph's task automation loop

# Helper function to create a tasks.md file
setup_tasks_file() {
  local content="$1"
  echo "$content" > "$TEST_TMPDIR/tasks.md"
}

# Helper function to create phase files
setup_phase_file() {
  local phase_num="$1"
  local content="$2"
  echo "$content" > "$TEST_TMPDIR/phase-$phase_num.md"
}

load 'test_helper'

# Test get_next_task_from_tasks() - Extract task from tasks.md
@test "get_next_task_from_tasks returns first unchecked task" {
  setup_tasks_file "- [ ] First task
- [ ] Second task
- [ ] Third task"
  result=$(get_next_task_from_tasks)
  [ "$result" = "First task" ]
}

@test "get_next_task_from_tasks skips checked tasks" {
  setup_tasks_file "- [x] Completed task
- [ ] Next task to do
- [ ] Another task"
  result=$(get_next_task_from_tasks)
  [ "$result" = "Next task to do" ]
}

@test "get_next_task_from_tasks handles task with colon" {
  setup_tasks_file "- [ ] Task 1: Implement feature
- [ ] Task 2: Add tests"
  result=$(get_next_task_from_tasks)
  [ "$result" = "Task 1: Implement feature" ]
}

@test "get_next_task_from_tasks returns empty when no unchecked tasks" {
  setup_tasks_file "- [x] Completed
- [x] Done"
  result=$(get_next_task_from_tasks)
  [ -z "$result" ]
}

@test "get_next_task_from_tasks returns empty when file missing" {
  rm -f "$TEST_TMPDIR/tasks.md"
  result=$(get_next_task_from_tasks)
  [ -z "$result" ]
}

@test "get_next_task_from_tasks handles task with special characters" {
  setup_tasks_file "- [ ] Fix: bug in \$variable handling"
  result=$(get_next_task_from_tasks)
  [ "$result" = 'Fix: bug in $variable handling' ]
}

# Test get_next_task_from_phases() - Extract task from phase files
@test "get_next_task_from_phases finds task in first phase" {
  setup_phase_file "01" "- [ ] Phase 1 task
- [x] Completed task"
  setup_phase_file "02" "- [ ] Phase 2 task"
  result=$(get_next_task_from_phases)
  [ "$result" = "Phase 1 task" ]
}

@test "get_next_task_from_phases skips first phase if complete" {
  setup_phase_file "01" "- [x] Phase 1 task
- [x] Another phase 1 task"
  setup_phase_file "02" "- [ ] Phase 2 task
- [ ] Another phase 2"
  result=$(get_next_task_from_phases)
  [ "$result" = "Phase 2 task" ]
}

@test "get_next_task_from_phases processes phases in order" {
  setup_phase_file "03" "- [ ] Phase 3 task"
  setup_phase_file "01" "- [ ] Phase 1 task"
  setup_phase_file "02" "- [ ] Phase 2 task"
  result=$(get_next_task_from_phases)
  # Should return Phase 1 task (01 comes before 02 and 03 in sort order)
  [ "$result" = "Phase 1 task" ]
}

@test "get_next_task_from_phases returns empty when all phases complete" {
  setup_phase_file "01" "- [x] Phase 1 done"
  setup_phase_file "02" "- [x] Phase 2 done"
  result=$(get_next_task_from_phases)
  [ -z "$result" ]
}

@test "get_next_task_from_phases returns empty when no phase files" {
  result=$(get_next_task_from_phases)
  [ -z "$result" ]
}

# Test detect_task_source() - Determine which task format to use
@test "detect_task_source returns 'tasks' when tasks.md exists" {
  setup_tasks_file "- [ ] A task"
  result=$(detect_task_source)
  [ "$result" = "tasks" ]
}

@test "detect_task_source returns 'phases' when phase files exist" {
  rm -f "$TEST_TMPDIR/tasks.md"
  setup_phase_file "01" "- [ ] A phase task"
  refresh_plan_vars
  result=$(detect_task_source)
  [ "$result" = "phases" ]
}

@test "detect_task_source returns 'tasks' when both tasks.md and phases exist" {
  setup_tasks_file "- [ ] A task"
  setup_phase_file "01" "- [ ] Phase task"
  result=$(detect_task_source)
  # tasks.md takes precedence
  [ "$result" = "tasks" ]
}

@test "detect_task_source returns 'none' when no task files exist" {
  rm -f "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  result=$(detect_task_source)
  [ "$result" = "none" ]
}

# Test get_next_task() - Main function
@test "get_next_task returns task from tasks.md" {
  setup_tasks_file "- [ ] Main task 1
- [ ] Main task 2"
  result=$(get_next_task)
  [ "$result" = "Main task 1" ]
}

@test "get_next_task returns task from phases" {
  rm -f "$TEST_TMPDIR/tasks.md"
  setup_phase_file "01" "- [ ] First phase task"
  refresh_plan_vars
  result=$(get_next_task)
  [ "$result" = "First phase task" ]
}

@test "get_next_task returns empty when no task files" {
  rm -f "$TEST_TMPDIR/tasks.md"
  refresh_plan_vars
  result=$(get_next_task)
  [ -z "$result" ]
}

@test "get_next_task returns empty when all tasks completed in tasks.md" {
  setup_tasks_file "- [x] Done 1
- [x] Done 2
- [x] Done 3"
  result=$(get_next_task)
  [ -z "$result" ]
}

@test "get_next_task skips multiple checked tasks" {
  setup_tasks_file "- [x] Task 1
- [x] Task 2
- [x] Task 3
- [ ] Task 4
- [ ] Task 5"
  result=$(get_next_task)
  [ "$result" = "Task 4" ]
}

# Edge cases and robustness
@test "get_next_task_from_tasks handles tasks with dashes in description" {
  setup_tasks_file "- [ ] Task: implement feature - with dashes
- [ ] Another task"
  result=$(get_next_task_from_tasks)
  [ "$result" = "Task: implement feature - with dashes" ]
}

@test "get_next_task_from_tasks handles long task descriptions" {
  local long_task="Implement comprehensive error handling with custom error codes and detailed logging across all API endpoints"
  setup_tasks_file "- [ ] $long_task"
  result=$(get_next_task_from_tasks)
  [ "$result" = "$long_task" ]
}

@test "get_next_task_from_tasks ignores malformed lines" {
  setup_tasks_file "- invalid format
- [ ] Valid task
- [x] Done task"
  result=$(get_next_task_from_tasks)
  [ "$result" = "Valid task" ]
}

@test "get_next_task_from_phases handles phase files with extra spaces" {
  setup_phase_file "01" "-  [ ]  Task with spaces
- [ ] Another task"
  result=$(get_next_task_from_phases)
  # grep looks for "^\- \[ \]" (dash-space-bracket-space-bracket), so extra spaces won't match
  # It should find "- [ ] Another task" instead
  [ "$result" = "Another task" ]
}

@test "get_next_task_from_tasks handles whitespace variations" {
  setup_tasks_file "- [ ] First task with proper spacing"
  result=$(get_next_task_from_tasks)
  [ "$result" = "First task with proper spacing" ]
}

@test "get_next_task handles task source preference (tasks.md over phases)" {
  setup_tasks_file "- [ ] From tasks file"
  setup_phase_file "01" "- [ ] From phase file"
  result=$(get_next_task)
  # tasks.md should take priority
  [ "$result" = "From tasks file" ]
}

@test "get_next_task with partially completed phase file" {
  rm -f "$TEST_TMPDIR/tasks.md"
  setup_phase_file "01" "- [x] Phase 1 step 1
- [x] Phase 1 step 2
- [ ] Phase 1 step 3"
  setup_phase_file "02" "- [ ] Phase 2 step 1"
  refresh_plan_vars
  result=$(get_next_task)
  [ "$result" = "Phase 1 step 3" ]
}

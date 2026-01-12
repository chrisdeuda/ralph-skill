# Context

## Key Files
<!-- List files Ralph should focus on - saves exploration time -->
- scripts/ralph-workflow.sh    # Main file with functions to test
- scripts/ralph-afk.sh         # AFK loop runner
- scripts/ralph-once.sh        # Single iteration runner
- scripts/ralph-init.sh        # Plan initializer

## Functions to Test (in ralph-workflow.sh)
- detect_model()              # Task → model selection
- is_checkpoint()             # Checkpoint detection
- get_next_task()             # Find next unchecked task
- build_file_refs()           # Build @ file references
- build_session_name()        # Session name for picker

## Patterns
<!-- Document codebase patterns Ralph should follow -->
- Test framework: BATS (Bash Automated Testing System)
- Test location: tests/ directory
- Naming: test-*.bats for test files
- Helper: tests/test_helper.bash for shared setup

## BATS Test Format
```bash
#!/usr/bin/env bats

load 'test_helper'

@test "detect_model returns haiku for lint tasks" {
  result=$(detect_model "fix lint errors")
  [ "$result" = "haiku" ]
}
```

## Notes
- Install BATS: `brew install bats-core`
- Run tests: `bats tests/`
- Working directory: ~/.claude/skills/ralph/

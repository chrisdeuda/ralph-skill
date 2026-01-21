---
name: ralph
description: Autonomous AI coding loop. Use when user wants to run tasks from a plan autonomously, go AFK while coding, or automate repetitive development work. Triggers on "ralph", "afk coding", "autonomous loop", "run tasks automatically".
---

# Ralph - Autonomous AI Coding Loop

Run AI coding in a loop, letting it work autonomously on a list of tasks from your plans directory.

## Modes

| Mode | Script | Use Case |
|------|--------|----------|
| Review | `ralph-review` | Pre-flight check, surface unclear requirements |
| HITL (human-in-the-loop) | `ralph-once` | Learning, prompt refinement, risky tasks |
| AFK (away from keyboard) | `ralph-afk` | Bulk work, low-risk tasks, overnight runs |

## Quality Modes

| Mode | Flag | Behavior |
|------|------|----------|
| Prototype | `prototype` | Speed over perfection. No tests, no lint, just make it work |
| Production | `production` | Full quality. Tests, edge cases, maintainable code |

## Plan Structure

Ralph works with your existing plans directory:

```
plans/{date}-{slug}/
├── tasks.md      # Task file with checkboxes [ ] and [x]
├── context.md    # Key files to focus on (optional, saves tokens)
└── progress.md   # Auto-generated progress log
```

### context.md (Optional - Saves Exploration Tokens)

Create this file to tell Ralph which files are relevant, avoiding re-discovery each task:

```markdown
# Context

## Key Files
- src/components/Calculator.jsx   # Main component to modify
- src/utils/parser.js             # Parser logic
- src/components/Display.jsx      # Display component

## Patterns
- Components use useReducer for state
- Tests located in __tests__/ directories
- Use × and ÷ symbols instead of * and /
```

Ralph reads context.md FIRST before starting any task, saving exploration time.

## Usage

### Initialize Ralph in a project
```bash
# Create plan directory with tasks
ralph-init "my-feature"
# Creates: plans/260109-my-feature/tasks.md
```

### Run single iteration (HITL)
```bash
ralph-once plans/260109-my-feature/
# Or with model override:
ralph-once plans/260109-my-feature/ sonnet
```

### Run AFK loop
```bash
ralph-afk plans/260109-my-feature/ 5
# Runs 5 iterations with auto model selection
# Or with model override:
ralph-afk plans/260109-my-feature/ 10 haiku
```

## Model Selection (Multi-Provider via CCS)

Ralph uses `ccs` (Claude Code Switcher) for multi-provider support:

| Keywords | Provider | Cost |
|----------|----------|------|
| plan, architect, design, debug, analyze | Claude Opus | $$$ |
| implement, create, add, build, lint, test, fix, docs, clean, format, update, write | GLM | ¢ |
| (default) | Claude Sonnet | $$ |

**Strategy**: Claude for planning/complex reasoning, GLM for implementation/execution.

### Explicit Provider Tags

Force a specific provider by adding tags to task descriptions:

```markdown
- [ ] [GLM] Implement the login form
- [ ] [OPUS] Debug the authentication flow
- [ ] [SONNET] Add error handling
- [ ] [KIMI] Write documentation
```

### Override via CLI

```bash
ralph-once <plan> glm           # Force GLM for all
ralph-once <plan> opus          # Force Claude Opus
ralph-afk <plan> 5 auto         # Auto-select per task (default)
```

## Task File Format (tasks.md)

```markdown
# Feature Name

## Tasks

- [ ] First task description
  - **AC:** Acceptance criteria
- [ ] Second task
  - **AC:** What done looks like
- [x] Completed task
```

## Progress Tracking

Ralph appends to `progress.md` (never overwrites):

```markdown
---
## Task N: [description]
**Status:** In Progress | **Time:** YYYY-MM-DD HH:MM | **Model:** sonnet

### Plan
- Step 1
- Step 2

### Actions
- [HH:MM] Action taken
- [HH:MM] ERROR: What failed (if any)
- [HH:MM] FIX: What was tried

### Result
**Status:** Completed | **Completed:** HH:MM
```

## Feedback Loops

Ralph runs these checks before marking complete:
1. `npm run lint -- --fix` (if available)
2. `npm test` (must pass)
3. Commits changes with descriptive message

## Recommended Workflow (Validate First)

```
1. ralph-init my-feature     # Creates plan with prototype-first structure
2. Edit tasks.md             # Add your tasks, resolve Open Questions
3. ralph-review <plan>       # Pre-flight: surface unclear requirements
4. ralph-afk <plan> 5 auto prototype  # Phase 1: Make it work (no tests)
   → Ralph auto-pauses at CHECKPOINT
5. Manual test               # Verify it actually works!
6. ralph-afk <plan> 5 auto production # Phase 2: Add quality (tests, lint)
```

## Checkpoints

Add `CHECKPOINT:` to any task to force Ralph to pause:

```markdown
- [ ] CHECKPOINT: Manual verification
  - **AC:** Manually test the feature works
  - **PAUSE:** Stop here, verify before Phase 2
```

Ralph will:
1. Detect checkpoint task
2. Log pause to progress.md
3. Mark checkpoint complete
4. Exit with instructions for next steps

## Best Practices

1. **Prototype first** - Get it working before adding tests
2. **Use checkpoints** - Pause between prototype and quality phases
3. **Review PRD first** - Run `ralph-review` to catch unclear requirements
4. **Small tasks** - One feature per checkbox, not epics
5. **Cap iterations** - Always limit AFK runs (5-10 small, 30-50 large)

## Scripts

Run these from any project directory:

- `~/.claude/skills/ralph/scripts/ralph-init.sh` - Initialize plan
- `~/.claude/skills/ralph/scripts/ralph-review.sh` - Review PRD for unclear requirements
- `~/.claude/skills/ralph/scripts/ralph-once.sh` - Single iteration
- `~/.claude/skills/ralph/scripts/ralph-afk.sh` - AFK loop
- `~/.claude/skills/ralph/scripts/ralph-workflow.sh` - Shared workflow
- `~/.claude/skills/ralph/scripts/ralph-publish-commands.sh` - Publish commands globally
- `~/.claude/skills/ralph/scripts/ralph-validate-ui.sh` - UI validation (ARIA/vision)
- `~/.claude/skills/ralph/scripts/ralph-test-ui.sh` - UI interaction testing

## Publishing Commands

To make Ralph commands available as `/ck:ralph:*` slash commands:

```bash
~/.claude/skills/ralph/scripts/ralph-publish-commands.sh
# Or dry-run first:
~/.claude/skills/ralph/scripts/ralph-publish-commands.sh --dry-run
```

This syncs commands from the skill to `~/.claude/commands/ralph/` and regenerates the catalog.

## UI Testing Options

Ralph supports multiple browser automation backends. Choose based on your needs:

| Method | Latency | Tokens | Best For |
|--------|---------|--------|----------|
| **Playwriter** (recommended) | ~50ms | minimal | Production apps, bypasses bot detection |
| Dev-browser | ~100ms | ~500-2000 | Local dev, ARIA snapshots |
| Vision | ~3-5s | ~1500-5000 | Visual design validation |

### Option 1: Playwriter (Recommended)

Single MCP tool with full Playwright API. Best for real apps with auth.

**Setup:**
1. Install [Playwriter Chrome extension](https://chromewebstore.google.com)
2. Click extension icon on tabs to control (turns green)
3. Ensure `playwriter` in `~/.claude/settings.json` mcpServers

**Usage via Claude MCP:**
```
# In Claude, use playwriter execute tool with Playwright code:
await page.click("button:has-text('Submit')");
await page.fill("#email", "test@example.com");

# Screenshot with Vimium-style labels for element discovery:
await screenshotWithAccessibilityLabels();
```

**Key advantage:** Can bypass automation detection by disconnecting extension during sensitive operations (Google login, etc).

### Option 2: Dev-Browser

CDP-based with persistent browser state. Good for local development.

```bash
# Start server
~/.claude/skills/ralph/scripts/ralph-test-ui.sh --start

# Validate UI
ralph-validate-ui "http://localhost:5173" "Calculator has buttons"

# Interaction test
ralph-test-ui "http://localhost:5173" 'await page.click("button")'
```

### Option 3: Vision Mode

Screenshot-based validation for visual design criteria.

```bash
ralph-validate-ui --vision "http://localhost:5173" "Modern dark theme UI"
```

### Using in Checkpoints

```markdown
- [ ] CHECKPOINT: Validate UI
  - **AC:** `ralph-validate-ui "http://localhost:5173" "All buttons visible"`
```

## Installation

Add to your shell profile (~/.zshrc or ~/.bashrc):

```bash
# Ralph aliases
alias ralph-init="~/.claude/skills/ralph/scripts/ralph-init.sh"
alias ralph-review="~/.claude/skills/ralph/scripts/ralph-review.sh"
alias ralph-once="~/.claude/skills/ralph/scripts/ralph-once.sh"
alias ralph-afk="~/.claude/skills/ralph/scripts/ralph-afk.sh"
alias ralph-validate-ui="~/.claude/skills/ralph/scripts/ralph-validate-ui.sh"
alias ralph-test-ui="~/.claude/skills/ralph/scripts/ralph-test-ui.sh"
```

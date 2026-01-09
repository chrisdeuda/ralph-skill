# Ralph - Autonomous AI Coding Loop

Run AI coding in a loop, letting Claude work autonomously on a list of tasks while you're AFK.

## Installation

### 1. Clone to Claude skills directory

```bash
cd ~/.claude/skills
git clone https://github.com/chrisdeuda/ralph-skill.git ralph
```

**Location:** `~/.claude/skills/ralph/`

### 2. Make scripts executable

```bash
chmod +x ~/.claude/skills/ralph/scripts/*.sh
```

### 3. Add shell aliases (optional, for terminal use)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Ralph - Autonomous AI Coding Loop
alias ralph-init="~/.claude/skills/ralph/scripts/ralph-init.sh"
alias ralph-once="~/.claude/skills/ralph/scripts/ralph-once.sh"
alias ralph-afk="~/.claude/skills/ralph/scripts/ralph-afk.sh"
```

Then reload: `source ~/.zshrc`

### 4. Copy slash command (for /ralph in Claude)

```bash
cp ~/.claude/skills/ralph/commands/ralph.md ~/.claude/commands/
```

## Directory Structure

```
~/.claude/skills/ralph/
├── README.md              # This file
├── skill.md               # Skill documentation (auto-loaded by Claude)
├── scripts/
│   ├── ralph-init.sh      # Create new plan
│   ├── ralph-once.sh      # Single iteration (HITL mode)
│   ├── ralph-afk.sh       # AFK loop mode
│   └── ralph-workflow.sh  # Shared workflow prompt
└── commands/
    └── ralph.md           # Slash command for Claude
```

## Usage

### In Claude (slash command)

```
/ralph                                    # Show help, list plans
/ralph plans/260109-feature/              # Single iteration
/ralph plans/260109-feature/ 5            # 5 AFK iterations
/ralph plans/260109-feature/ 10 haiku     # Force haiku model
```

### In Terminal

```bash
# Create a new plan
ralph-init my-feature
# Creates: plans/YYMMDD-HHMM-my-feature/tasks.md

# Run single iteration (watch and intervene)
ralph-once plans/260109-1500-my-feature/

# Run AFK loop (go do something else)
ralph-afk plans/260109-1500-my-feature/ 5
```

## Plan Structure

Ralph supports **two task sources**:

### Option 1: Standalone tasks.md
```
plans/{date}-{slug}/
├── tasks.md      # Task checkboxes [ ] and [x]
├── context.md    # Key files to focus on (optional)
└── progress.md   # Auto-generated progress log
```

### Option 2: /plan phase files (recommended)
```
plans/{date}-{slug}/
├── plan.md              # Overview from /plan command
├── phase-01-setup.md    # Checkboxes in each phase
├── phase-02-impl.md
├── context.md           # Key files (optional, saves tokens)
└── progress.md          # Ralph's log
```

Ralph auto-detects which format you're using.

### tasks.md format

```markdown
# Feature Name

## Tasks

- [ ] First task description
  - **AC:** Acceptance criteria here
- [ ] Second task
  - **AC:** What "done" looks like
- [x] Completed task (Ralph marks these)
```

### context.md format (optional, saves exploration tokens)

```markdown
# Context

## Key Files
- src/components/Calculator.jsx   # Main component
- src/components/ButtonGrid.jsx   # Button layout

## Patterns
- Components use useReducer for state
- Tests in __tests__/ next to components
```

## Model Selection

Ralph auto-selects models based on task keywords:

| Keywords | Model | Cost |
|----------|-------|------|
| lint, test, fix, docs, clean, format | Haiku | $ |
| implement, create, add, build | Sonnet | $$ |
| debug, architect, refactor, restructure | Opus | $$$ |

Override with: `ralph-once <plan> opus`

## Modes

| Mode | Command | Use Case |
|------|---------|----------|
| **HITL** | `ralph-once` | Learning, risky tasks, prompt refinement |
| **AFK** | `ralph-afk` | Bulk work, low-risk tasks, overnight runs |

**Best practice:** Start with HITL to refine, then go AFK once confident.

## Updating

```bash
cd ~/.claude/skills/ralph
git pull origin master
```

## Credits

Based on [Matt Pocock's Ralph Wiggum technique](https://aihero.dev/11-tips-for-ai-coding-with-ralph-wiggum).

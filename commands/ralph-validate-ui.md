---
description: Validate UI with Claude vision against acceptance criteria
argument-hint: "<url> <criteria>"
---

# Ralph Validate UI - Automated Visual Verification

Use Claude's vision capability to validate UI screenshots against acceptance criteria.

## Arguments
- `$ARGUMENTS` contains: `<url> <criteria> [screenshot-path]`
  - url: Page URL to screenshot (e.g., http://localhost:5173)
  - criteria: What to verify (e.g., "Calculator has Clear History button")
  - screenshot-path: Optional. Where to save screenshot

## How It Works

1. Takes screenshot of the URL using Playwright
2. Sends screenshot to Claude vision model
3. Claude analyzes against acceptance criteria
4. Returns PASS or FAIL with reasoning

## Instructions

Run the validation script:

```bash
~/.claude/skills/ralph/scripts/ralph-validate-ui.sh <url> <criteria>
```

## Usage Examples

```bash
# Validate calculator UI
ralph-validate-ui "http://localhost:5173" "Calculator displays with number buttons and Clear History button"

# Validate dashboard
ralph-validate-ui "http://localhost:3000/dashboard" "Dashboard shows user avatar and navigation sidebar"

# Validate login page
ralph-validate-ui "http://localhost:3000/login" "Login form has email and password fields with submit button"
```

## Integration with Ralph Workflow

Use at CHECKPOINT to automate verification:

```markdown
- [ ] CHECKPOINT: Validate UI
  - **AC:** ralph-validate-ui "http://localhost:5173" "Feature X is visible and working"
```

## Exit Codes

- `0` - PASS: UI meets criteria
- `1` - FAIL: UI does not meet criteria

## Requirements

- Node.js with npx
- Playwright (auto-installed via npx)
- Claude CLI with vision support

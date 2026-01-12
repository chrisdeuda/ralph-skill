# Ralph Guardrails - Do NOT Repeat These Mistakes

> **Append-only log.** When Ralph encounters a failure, add it here so the same mistake never happens twice.

## Format

```markdown
- [YYYY-MM-DD] **Category:** Description of what went wrong and what NOT to do
```

## Active Guardrails

- [2026-01-12] **Testing:** DO NOT mock APIs in tests - mocked tests pass but real API fails. Always test against real endpoints.
- [2026-01-12] **Workflow:** DO NOT write tests before manual verification - tests for broken code are wasted effort.
- [2026-01-12] **Types:** DO NOT use `any` type - it hides real type errors that surface at runtime.
- [2026-01-12] **Lint:** DO NOT fix lint before core functionality works - lint is polish, not validation.

---

<!-- Ralph appends new guardrails below this line -->

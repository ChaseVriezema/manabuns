---
name: taste-response-guidelines
description: "Use when receiving code review feedback from humans or external reviewers — establishes verify-first discipline before implementing suggestions"
---

# Review Response

Behavioral discipline for processing review feedback. Verify before implementing. Push back when wrong.

**Scope:** Human feedback, external PR reviewers, ad-hoc review output. Does NOT apply during cooking Phase 4 — cooking has its own structured protocol for food-critic findings.

## Response Pattern

```
1. READ    — Complete feedback without reacting
2. RESTATE — Restate the requirement in your own words (or ask if unclear)
3. VERIFY  — Check against codebase reality
4. EVALUATE — Technically sound for THIS codebase?
5. RESPOND — Technical acknowledgment or reasoned pushback
6. IMPLEMENT — One item at a time, test each
```

## Unclear Feedback

If ANY item is unclear, **stop and clarify ALL unclear items before implementing ANY.**

Partial understanding leads to wrong implementation. Don't guess — ask.

**Example:**
```
Reviewer gives items 1-6.
You understand 1, 2, 3, 6. Unclear on 4 and 5.

WRONG: Implement 1, 2, 3, 6 now. Ask about 4, 5 later.
RIGHT: "I understand 1, 2, 3, 6. Need clarification on 4 and 5 before proceeding."
```

## When to Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (feature isn't actually used)
- Technically incorrect for this stack
- Conflicts with the user's architectural decisions

**How:** Use technical reasoning, not defensiveness. Reference working code or tests. Ask specific questions. Escalate to the user if it's an architectural disagreement.

## YAGNI Check

See "Plugin-Wide Principles" in CLAUDE.md. When a reviewer suggests adding infrastructure:

1. Grep the codebase for actual usage
2. If nothing calls it, question whether it's needed
3. If it IS used, then implement properly

## Implementation Order

When fixing multiple items:

1. **Blocking** — breaks, security issues (first)
2. **Simple** — typos, imports, naming (second)
3. **Complex** — refactoring, logic changes (last)

Test each fix individually. Verify no regressions before moving on.

## Source-Specific Handling

### User feedback
- Trusted — implement after understanding
- Still ask if scope is unclear
- Skip to action, don't over-discuss

### External / automated feedback
- Verify against codebase before implementing
- Check if suggestion breaks existing functionality
- Check if there's a reason for the current implementation
- Push back if wrong — external reviewers don't always have full context

## Related Skills

- **oven:taste** — Dispatches standalone food-critic reviews (this skill handles the response side)

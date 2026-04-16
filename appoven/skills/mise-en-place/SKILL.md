---
name: mise-en-place
description: "Use when implementing any feature or fix — defines expected behavior before writing code, think-first discipline adapted for Unity projects where formal test frameworks are impractical"
---

# Mise en Place

## Overview

Code written without a clear definition of "done" drifts. Fixes applied without understanding expected behavior create new bugs.

**Core principle:** Define what correct looks like BEFORE writing code. Verify against that definition AFTER.

**This is TDD philosophy without requiring a test runner.** When tests are practical, write them. When they're not (Unity MonoBehaviours, editor tools, UI flows), use structured verification instead.

## The Iron Law

<HARD-GATE>
NO IMPLEMENTATION WITHOUT DEFINING EXPECTED BEHAVIOR FIRST

If you haven't written down what "done" looks like, you aren't ready to code. This is the skill's entire reason for existence — the LLM will rationalize skipping this for "obvious" changes.
</HARD-GATE>

## When to Use

- Before implementing any feature task (cooking follows this per task)
- Before fixing any bug (smoke-check Phase 4 references this)
- Before any code change where the expected outcome isn't already specified in the plan

**When NOT to use:**
- Pure refactoring where behavior is explicitly unchanged
- Config/metadata-only changes
- Documentation updates

## The Cycle: Define, Implement, Verify

This mirrors red-green-refactor but adapts to environments where automated tests aren't always available.

### 1. DEFINE (Red)

Before writing any implementation code, write down:

**Expected behavior spec** — what should happen, stated as observable outcomes:
```
GIVEN: [starting state or preconditions]
WHEN:  [action or trigger]
THEN:  [observable result]
```

Write one spec per behavior. Multiple behaviors = multiple specs.

**Choose a verification method** based on what's practical:

| Situation | Verification Method |
|-----------|-------------------|
| Pure logic, data transforms, utilities | Automated test (EditMode test, unit test) |
| ScriptableObject validation, serialization | Automated test (EditMode test) |
| MonoBehaviour lifecycle, scene interaction | PlayMode test if simple, manual verification if complex |
| Editor tools, inspector UI | Manual verification with specific steps |
| Visual/UX behavior | Manual verification with expected visual outcome described |
| Multi-system integration | Debug logging at boundaries + manual verification |

**If automated tests ARE practical — write them.** Don't skip tests just because Unity makes them harder. Pure C# logic, data models, and utility methods are all testable.

**If automated tests aren't practical** — write explicit manual verification steps:
```
Verification steps:
1. Open scene X
2. Enter play mode
3. Trigger [action]
4. Observe: [expected result]
5. Check console for: [expected log output or absence of errors]
```

### 2. IMPLEMENT (Green)

Write the **minimal code** that satisfies the expected behavior spec. Nothing more.

- One behavior at a time
- Don't optimize yet
- Don't add "while I'm here" improvements
- If the spec says X, implement X — not X + Y

### 3. VERIFY (Refactor)

Run the verification method you defined in step 1.

**For automated tests:** Run them. They must pass. If they don't, fix the implementation — don't change the test (unless the spec was wrong).

**For manual verification:** Follow your verification steps exactly. Document what you observed. If it doesn't match, fix the implementation.

**Then clean up:**
- Remove debug logging added for verification (unless it's valuable long-term)
- Clean up naming, extract methods, simplify — but don't change behavior
- Re-verify after cleanup

## For Cooking (Main Agent)

When used during cooking, the cycle integrates into each task:

1. Read the task spec — the expected behavior is defined in the plan
2. If the plan's spec is vague, ask the user for clarification before proceeding
3. Choose verification method based on the table above
4. If writing automated tests: write test first, verify it fails, implement, verify it passes
5. If manual verification: note the verification steps in your self-review
6. Record verification outcome in your self-review notes for the food critic

## For Bug Fixes

When used by smoke-check Phase 4:

1. The root cause is already identified (Phases 1-3)
2. Write the expected behavior spec: "GIVEN [root cause condition], WHEN [trigger], THEN [correct behavior instead of bug]"
3. **Strongly prefer an automated test** for bugs — regression tests prevent re-introduction
4. If a test isn't practical, write manual reproduction + verification steps
5. Implement the fix
6. Verify against the spec

## Red Flags — STOP

| Thought | Reality |
|---------|---------|
| "I know what to build, let me just start" | Define expected behavior first. Always. |
| "The plan is clear enough, I don't need a spec" | Plans describe what to build. Specs describe what done looks like. |
| "I'll figure out verification after" | Verification defined after implementation is confirmation bias. |
| "Tests aren't practical here" | Pure logic is always testable. Be honest about what's truly untestable. |
| "Manual verification is good enough" | It is — when the steps are explicit and followed. Not when it's "I'll just check." |
| "This is too small to need a spec" | Small changes have expected behaviors too. |
| "I'll add a test later" | Later never comes. Define verification now. |

## Key Principles

- **Define before implement** — know what done looks like before starting
- **Automate when practical** — real tests beat manual checks every time
- **Be honest about testability** — don't skip tests because they're inconvenient, only when they're genuinely impractical
- **Minimal implementation** — satisfy the spec, nothing more
- **Verify against the spec** — not against your intuition
- **Clean up after verifying** — refactor with confidence once behavior is confirmed

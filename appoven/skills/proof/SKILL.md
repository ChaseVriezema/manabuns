---
name: proof
description: "Use before claiming work is complete, fixed, or passing — requires running verification commands and confirming output before making any success claims"
---

# Proof

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

## The Iron Law

<HARD-GATE>
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

If you haven't run the verification command in this message, you cannot claim it passes. This is the skill's entire reason for existence — without enforcement, the LLM will claim success without verification.
</HARD-GATE>

## The Gate

Before claiming ANY status or expressing satisfaction:

1. **IDENTIFY** — What command or action proves this claim?
2. **RUN** — Execute it. Fresh, complete, no shortcuts.
3. **READ** — Full output. Check exit code. Count failures.
4. **CONFIRM** — Does the output support the claim?
   - **No:** State actual status with evidence
   - **Yes:** State claim WITH evidence
5. **ONLY THEN** — Make the claim

Skip any step = lying, not verifying.

## What Counts as Evidence

| Claim | Requires | NOT Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output showing 0 failures | Previous run, "should pass" |
| Build succeeds | Build command with exit 0 | Linter passing, "looks good" |
| Bug fixed | Original symptom verified resolved | Code changed, assumed fixed |
| No errors | Console/log output reviewed | "I didn't add any bugs" |
| Feature works | Verification steps executed with results | "Implementation matches spec" |
| Agent completed | Diff shows expected changes | Agent reports "success" |
| Requirements met | Line-by-line checklist verified | Tests passing |

## Unity-Specific Verification

Unity projects often can't verify purely through CLI. Apply the same rigor:

| What to Verify | How |
|----------------|-----|
| Code compiles | Check for compilation errors in console output |
| Editor tool works | Follow manual verification steps, report what you observed |
| PlayMode behavior | Describe expected vs actual observation |
| Serialization intact | Check inspector values, verify no data loss |
| No regressions | Run available tests, check console for new errors/warnings |

**When you can't run it** (e.g., PlayMode behavior requires a human), say so honestly:
```
I've verified: [what you actually checked]
Still needs human verification: [what requires manual play testing]
```

## Red Flags — STOP

If you catch yourself:

- Using "should", "probably", "seems to", "looks correct"
- Expressing satisfaction before verification ("Great!", "Done!", "That should do it")
- About to commit or create a PR without verification
- Trusting an agent's success report without checking the diff
- Relying on partial verification ("linter passed" when you need "build passed")
- Thinking "just this once I can skip it"
- ANY wording implying success without having run verification

**ALL of these mean: STOP. Run the verification.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Should work now" | Run it and find out |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter is not compiler is not runtime |
| "Agent said success" | Verify independently |
| "The code is straightforward" | Straightforward code still has bugs |
| "I already checked earlier" | Earlier is not now. Run it fresh. |
| "Partial check is enough" | Partial proves nothing about the whole |

## When to Use

**ALWAYS before:**
- Any claim that work is complete or correct
- Any expression of satisfaction about work state
- Committing changes
- Creating PRs
- Moving to the next task
- Reporting status to the user
- Handing off between pipeline stages (cooking → plating, smoke-check → done)

## Key Principles

- **Evidence before assertions** — run the command, read the output, then speak
- **Fresh verification** — previous runs don't count, re-run now
- **Full verification** — partial checks don't prove full correctness
- **Honest gaps** — if you can't verify something, say so instead of assuming
- **No performative confidence** — "should work" is not a status report

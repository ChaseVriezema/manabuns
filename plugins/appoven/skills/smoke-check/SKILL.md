---
name: smoke-check
model: sonnet
description: "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes"
---

# Smoke Check

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

**Announce at start:** "Something's burning -- let me find where the smoke is coming from."

## The Iron Law

<HARD-GATE>
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

If you haven't completed Phase 1, you cannot propose fixes. This is the skill's entire reason for existence — skipping investigation to jump to fixes defeats the purpose.
</HARD-GATE>

## When to Use

Use for ANY technical issue:
- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use this ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work
- You don't fully understand the issue

**Don't skip when:**
- Issue seems simple (simple bugs have root causes too)
- You're in a hurry (rushing guarantees rework)
- Someone wants it fixed NOW (systematic is faster than thrashing)

## Context Boundary (when invoked from order)

Smoke-check may be invoked directly or via order's routing. When invoked from order, it receives a **sealed problem brief**:

| Field | Content |
|-------|---------|
| **Problem** | Confirmed interpretation of what's broken |
| **Expected behavior** | What should happen instead |
| **Starting points** | File paths and areas from orientation |
| **Assumptions** | Confirmed assumptions from interview |
| **Player experience** | What the player sees when the bug occurs |

When invoked directly (no order handoff), smoke-check gathers context from the conversation itself.

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully**
   - Don't skip past errors or warnings
   - They often contain the exact solution
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Can you trigger it reliably?
   - What are the exact steps?
   - Does it happen every time?
   - If not reproducible, gather more data -- don't guess

3. **Check Recent Changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes
   - Environmental differences

4. **Gather Evidence in Multi-Component Systems**

   **WHEN system has multiple components (build pipeline, API layers, Unity editor vs runtime):**

   **BEFORE proposing fixes, add diagnostic instrumentation:**
   ```
   For EACH component boundary:
     - Log what data enters component
     - Log what data exits component
     - Verify environment/config propagation
     - Check state at each layer

   Run once to gather evidence showing WHERE it breaks
   THEN analyze evidence to identify failing component
   THEN investigate that specific component
   ```

   **Example (Unity multi-layer):**
   ```csharp
   // Layer 1: Editor script
   Debug.Log($"=== Editor state: {EditorApplication.isPlaying}, {EditorApplication.isCompiling} ===");

   // Layer 2: ScriptableObject data
   Debug.Log($"=== Config loaded: {config != null}, values: {config?.ToString()} ===");

   // Layer 3: Runtime initialization
   Debug.Log($"=== Awake called: {gameObject.name}, scene: {SceneManager.GetActiveScene().name} ===");

   // Layer 4: Actual operation
   Debug.Log($"=== Operation input: {input}, state: {currentState} ===");
   ```

   **This reveals:** Which layer fails (editor -> config OK, config -> runtime FAIL)

5. **Trace Data Flow**

   **WHEN error is deep in call stack:**

   See `root-cause-tracing.md` in this directory for the complete backward tracing technique.

   **Quick version:**
   - Where does bad value originate?
   - What called this with bad value?
   - Keep tracing up until you find the source
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

**Find the pattern before fixing:**

1. **Find Working Examples**
   - Locate similar working code in same codebase
   - What works that's similar to what's broken?

2. **Compare Against References**
   - If implementing pattern, read reference implementation COMPLETELY
   - Don't skim -- read every line
   - Understand the pattern fully before applying

3. **Identify Differences**
   - What's different between working and broken?
   - List every difference, however small
   - Don't assume "that can't matter"

4. **Understand Dependencies**
   - What other components does this need?
   - What settings, config, environment?
   - What assumptions does it make?

### Phase 3: Hypothesis and Testing

**Scientific method:**

1. **Form Single Hypothesis**
   - State clearly: "I think X is the root cause because Y"
   - Write it down
   - Be specific, not vague

2. **Test Minimally**
   - Make the SMALLEST possible change to test hypothesis
   - One variable at a time
   - Don't fix multiple things at once

3. **Verify Before Continuing**
   - Did it work? Yes -> Phase 4
   - Didn't work? Form NEW hypothesis
   - If 2+ hypotheses rejected without clear next direction: consider **Escalation** (see below)
   - DON'T add more fixes on top

4. **When You Don't Know**
   - Say "I don't understand X"
   - Don't pretend to know
   - Ask for help
   - Research more

### Phase 4: Implementation

**Fix the root cause, not the symptom:**

1. **Define Expected Behavior**
   - Use `oven:mise-en-place` to define expected behavior and choose a verification method before fixing
   - Automated test if practical (EditMode or PlayMode test)
   - Structured manual verification if not
   - MUST have a clear definition of "fixed" before writing the fix

2. **Implement Single Fix**
   - Address the root cause identified
   - ONE change at a time
   - No "while I'm here" improvements
   - No bundled refactoring

3. **Verify Fix**
   - Test passes now?
   - No other tests broken?
   - Issue actually resolved?

4. **If Fix Doesn't Work**
   - STOP
   - Count: How many fixes have you tried?
   - If < 3: Return to Phase 1, re-analyze with new information
   - **If >= 3: STOP and question the architecture (step 5 below)**
   - DON'T attempt Fix #4 without architectural discussion

5. **If 3+ Fixes Failed: Question Architecture**

   **Pattern indicating architectural problem:**
   - Each fix reveals new shared state/coupling/problem in different place
   - Fixes require "massive refactoring" to implement
   - Each fix creates new symptoms elsewhere

   **STOP and question fundamentals:**
   - Is this pattern fundamentally sound?
   - Are we "sticking with it through sheer inertia"?
   - Should we refactor architecture vs continue fixing symptoms?

   **Discuss with the user before attempting more fixes.** Consider **Escalation** to Opus for deeper architectural analysis (see below).

   This is NOT a failed hypothesis -- this is a wrong architecture.

## Escalation

This skill defaults to Sonnet for speed. When Sonnet can't crack it, escalate to Opus for deeper reasoning.

**Triggers — escalate when:**
- Phase 1 investigation is thorough but root cause remains unclear
- 2+ hypotheses rejected in Phase 3 without clear next direction
- 3+ fixes failed in Phase 4 (architectural problems)
- Bug involves complex multi-system interactions that need more reasoning depth

**How to escalate:**
Spawn an Opus agent (`model: "opus"`) with all evidence gathered so far. The agent re-analyzes with fresh eyes and deeper reasoning.

**Pass to the Opus agent:**
- Original bug description and error messages
- All evidence gathered (logs, stack traces, diagnostic output)
- What was investigated and ruled out
- Rejected hypotheses and why they failed
- Relevant file paths and system boundaries identified

Use the Opus agent's analysis to continue the process from wherever you left off — don't restart from scratch unless the analysis fundamentally changes the picture.

**Do NOT escalate for:**
- Routine debugging that's just taking time (follow the process)
- Skipping phases (Opus doesn't bypass the Iron Law)
- "I want a better answer" without evidence of being stuck

## Red Flags -- STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

**If 3+ fixes failed:** Question the architecture (see Phase 4.5)

## User Signals You're Doing It Wrong

**Watch for these redirections:**
- "Is that not happening?" -- You assumed without verifying
- "Will it show us...?" -- You should have added evidence gathering
- "Stop guessing" -- You're proposing fixes without understanding
- "Ultrathink this" -- Question fundamentals, not just symptoms
- "We're stuck?" (frustrated) -- Your approach isn't working

**When you see these:** STOP. Return to Phase 1.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll define expected behavior after confirming fix works" | Unverified fixes don't stick. Define what "fixed" looks like first. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms != understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Define behavior, fix, verify | Bug resolved, verified |

## When Process Reveals "No Root Cause"

If systematic investigation reveals issue is truly environmental, timing-dependent, or external:

1. You've completed the process
2. Document what you investigated
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

**But:** 95% of "no root cause" cases are incomplete investigation.

## Supporting Techniques

These techniques are part of smoke-check and available in this directory:

- **`root-cause-tracing.md`** -- Trace bugs backward through call stack to find original trigger
- **`defense-in-depth.md`** -- Add validation at multiple layers after finding root cause
- **`condition-based-waiting.md`** -- Replace arbitrary waits with condition polling (WaitUntil, UniTask)

**Related oven skills:**
- **oven:mise-en-place** -- Define expected behavior and verification method before fixing (Phase 4, Step 1)
- **oven:proof** -- Verify fix worked before claiming success (run verification, confirm output, then claim done)

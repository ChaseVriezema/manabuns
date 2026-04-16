---
name: plating
description: "Use after implementation is complete to review and refine recently changed code for clarity, consistency, and maintainability without changing behavior"
---

# Plating -- Post-Implementation Code Refinement

## Overview

Review recently changed code and refine it for clarity, consistency, and maintainability — without changing what it does. This is the polish pass before a branch is wrapped up.

**Core principle:** Functionality is frozen. Only improve *how* the code reads, not *what* it does. Every change must be behavior-preserving.

When dispatched from cooking, plating runs as a single agent that autonomously scopes, reviews, applies, and commits. When invoked standalone via `/plating`, the main agent orchestrates the same phases directly.

<HARD-GATE>
This skill is fully autonomous. No user prompts, no confirmation steps. Scan, apply, report back. Cooking depends on plating completing without interaction — if plating asks the user a question, it halts cooking unexpectedly.
</HARD-GATE>

**Announce at start:** "Let me plate this up — polishing without changing the recipe."

<HARD-GATE>
Do NOT change behavior, add features, fix bugs, or refactor architecture. If you find a bug or architectural issue during plating, include it in the final report — do not fix it. This skill is cosmetic only.
</HARD-GATE>

## Main Agent Context Budget

When dispatched as an agent from cooking: the plating agent handles all phases in its own context — reads files directly, reviews directly, applies directly. No sub-agents needed.

When standalone: the main agent reads files directly for small changesets (<= 10 files), or may batch into reviewer sub-agents for very large changesets (>10 files).

## When to Use

- After `oven:cooking` completes and reviews pass
- After any implementation work before committing/PR
- User asks to clean up, polish, or simplify recent changes
- User invokes `/plating` directly

**When NOT to use:**
- Code hasn't been written yet (use `oven:order` then `oven:prep` then `oven:recipe` then `oven:cooking`)
- You're debugging (use `oven:smoke-check`)
- You need to change behavior (that's implementation, not plating)
- Single-file, few-line changes (just do it inline — plating is for multi-file work)

## What Plating Touches

**In scope:**
- Naming — local variables, private members, and new identifiers introduced in the changeset (clearer, more consistent). Do not rename public/protected members — that's an API change.
- Structure — reduce nesting, simplify conditionals, flatten unnecessary indirection
- Redundancy — remove dead code (in the changeset OR pre-existing code made dead by the changeset), unused usings/imports, duplicate logic
- Consistency — match new/changed code to the surrounding style, follow project CLAUDE.md standards. Never change surrounding code to match new code.
- Comments — remove obvious ones, add clarity where logic isn't self-evident
- Organization — reorder members for readability (fields, then constructors, then public methods, then private). **Only when the file was substantially rewritten** — don't reorder members in files with minor changes, as it creates noisy diffs and merge conflicts.

**Out of scope:**
- Behavior changes of any kind
- New error handling or validation
- Architecture changes (extracting classes, changing inheritance, new abstractions)
- Performance optimizations (unless trivially obvious, like removing an allocation in a tight loop)
- Adding tests

## The Process

```
  Dispatched from cooking?
       |
  yes: Phases 1-4 run inline (single agent)
  |    Phase 5 SKIPPED (caller handles food-critic)
  |    Phase 6 is the final response
  |
  no (standalone):
       |
Phase 1: Scope the changeset
       |
Phase 2: Review for refinement opportunities
       |
  Zero findings? --yes--> Phase 6 (PLATING_NOTHING)
       |
       no
       |
Phase 3: Apply refinements directly
       |
Phase 4: Commit plating changes
       |
Phase 5: Food-critic review (logic errors only) -- standalone only
       |
Phase 6: Report back (PLATING_COMPLETE / PLATING_NOTHING / PLATING_BLOCKED)
```

### Phase 1: Scope the Changeset

Determine what code was recently changed. Use git to identify the diff:

1. Run `git diff --name-only` against the base branch (e.g. `main`) to get the list of changed files
2. Filter to source files only (e.g. `.cs`, `.ts`, `.js` — skip generated files, configs, meta files)
3. Note the file list and proceed immediately — no confirmation needed

If the user provides specific files instead, use those.

**If no changed source files are found** (empty diff, or all changed files are non-source): skip to Phase 6 and report `STATUS: PLATING_NOTHING` (dispatched mode) or announce "nothing to plate" (standalone mode). This is not a failure — there's simply nothing to refine.

### Phase 2: Review

Identify refinement opportunities in the changed files.

**Dispatched mode (from cooking):** Review all files directly — read each file, diff against base, identify refinement opportunities using the findings table format below. No sub-agents.

**Standalone mode with <= 10 files:** Review all files directly. Same approach as dispatched mode.

**Standalone mode with > 10 files:** May batch into reviewer sub-agents (`subagent_type: general-purpose`, `model: sonnet`). Cap at 5 concurrent agents, group files into batches of ~3-4 per agent.

See "Agent Output Protocol" in CLAUDE.md — each reviewer's final response IS its deliverable.

**What to pass each reviewer sub-agent:**
- The file path(s) to review
- The base branch name (so it can `git diff <base> -- <file>` to see only what changed)
- Project coding standards (from CLAUDE.md)
- The plating scope rules (what's in/out of scope above)
- The exact findings table format below (paste it into the agent's prompt)
- Explicit instruction: **"Your final response text IS your deliverable. Return your findings using the table format below, grouped by file. If you find nothing, respond with exactly: `No findings for [file path(s)]`."**

**If a reviewer sub-agent returns empty, garbled, or no output:** re-dispatch that batch only with a tighter prompt per Agent Failure Recovery in CLAUDE.md. After 1 re-dispatch attempt (2 total dispatches) for the same batch, skip those files and note them in the final report as "not reviewed — agent failure."

**What to check per file:**
1. Read the file
2. Diff against the base branch to isolate changed/added lines
3. Identify refinement opportunities **only in changed code** (exception: pre-existing code made dead by the changeset can be flagged for removal)
4. Categorize each finding

**Findings table format (per file):**

**`path/to/File.cs`:**

| Line(s) | Category | Current | Suggested | Why |
|---------|----------|---------|-----------|-----|
| 42-45 | Naming | `tmpVal` | `parsedScore` | Unclear abbreviation |
| 78 | Redundancy | Unused using | Remove | Dead import |

**Review constraints:**
- Only flag things in changed/added code — never touch pre-existing code unless the changeset made it dead (unused method, orphaned field, etc.)
- Every suggestion must be behavior-preserving
- If uncertain whether a change is behavior-preserving, skip it
- No architecture opinions — this isn't a code review

**After review completes:** Collect findings into a single report grouped by file.

**If zero findings across all files:** Announce "Nothing to plate — the code's already clean." Skip Phases 3-5 and go directly to Phase 6 (report). In dispatched mode, the report must still end with a status line — use `STATUS: PLATING_NOTHING`.

### Phase 3: Apply Refinements

Apply all findings directly using the Edit tool. No sub-agents — both dispatched and standalone modes apply directly.

**Rules:**
- Apply every finding — no skipping, no bonus changes
- One file at a time
- If a finding can't be applied cleanly (line numbers shifted, code changed since review), skip it and note it for the final report

**If ALL findings fail to apply** (e.g., the codebase changed between review and apply): skip to Phase 6 and report `STATUS: PLATING_BLOCKED` (dispatched mode) or announce the failure (standalone mode). Do not commit an empty changeset.

### Phase 4: Commit Plating Changes

<HARD-GATE>
Commit all plating refinements in a single commit. This commit MUST happen before Phase 5 or Phase 6. When dispatched from cooking, the caller uses `git diff <pre-plating-SHA>..HEAD` to review plating changes — if you don't commit, the diff is empty and the food-critic reviews nothing. In standalone mode, Phase 5's food-critic diffs the plating commit — without the commit, it has nothing to review.
</HARD-GATE>

**Commit message format:** `style: plating refinements` followed by a brief list of what changed (e.g., "rename locals in PlayerViewModel, remove unused usings in ScorePanel").

### Phase 5: Food-Critic Review

**Dispatched mode (from cooking): SKIP this phase entirely.** The cooking agent handles food-critic review of plating changes by dispatching its own fresh food-critic. Plating just reports back and lets the caller decide.

**Standalone mode:** Dispatch a **food-critic review agent** via the `Agent` tool (`subagent_type: general-purpose`, `model: sonnet`) to verify plating didn't accidentally change logic. See `food-critic-prompt.md` in the cooking skill directory for the complete prompt template.

**What to pass the food-critic (standalone only):**
- The git diff of the plating commit only (not the full branch diff)
- Use the **plating review** context block from the template
- Explicit instruction: **"Your final response text IS your deliverable. Use the Report Format from the prompt template exactly. End with `Verdict: PASS` or `Verdict: NEEDS FIXES`."**

**The food-critic's job is narrow:** only flag logic errors or behavior changes introduced by plating. Cosmetic opinions are irrelevant — plating already made those calls.

**If the agent returns empty, garbled, no output, or has no parseable Verdict line:** follow Agent Failure Recovery and Verdict Parsing in CLAUDE.md.

**If the food-critic flags logic errors (standalone mode):** revert the specific flagged changes, then commit the revert with message `revert: plating changes that introduced logic errors`. Do NOT attempt to fix them — plating is cosmetic, reverting is always safe.

### Phase 6: Report

**If PLATING_COMPLETE:** Report back with:
- The list of files modified during plating
- A summary of refinements applied, grouped by file
- Any findings that couldn't be applied cleanly (skipped in Phase 3)
- Food-critic verdict and any findings (standalone mode only; dispatched mode skips food-critic)
- Any bugs or architectural issues discovered during the review pass (plating didn't fix them — just flagging)

**If PLATING_NOTHING:** Report back with:
- Confirmation that no refinement opportunities were found
- Any bugs or architectural issues discovered during the review pass (if any)

**If PLATING_BLOCKED:** Report back with:
- What went wrong (no source files in diff, all edits failed to apply, etc.)
- Any partial work that was done and reverted

**Dispatched mode status line (must be the last line of the response):**
- `STATUS: PLATING_COMPLETE` — refinements applied and committed.
- `STATUS: PLATING_NOTHING` — zero findings, no changes made.
- `STATUS: PLATING_BLOCKED` — couldn't complete. Describe what went wrong so the caller can decide whether to re-dispatch or skip.

## Logic Error Handling

**Dispatched mode:** The caller (cooking) handles food-critic review of plating changes. If the caller's food critic flags logic errors, the caller reverts those specific changes. Plating itself does not handle logic errors in dispatched mode — it just reports and exits.

**Standalone mode:** Plating dispatches its own food-critic in Phase 5. If logic errors are flagged, plating reverts the flagged changes and commits the revert (see Phase 5).

In both modes, plating is cosmetic-only — reverting is always safe and preferable to patching.

## Red Flags -- STOP

See "Universal Red Flags" in CLAUDE.md for cross-skill red flags. Skill-specific flags below:

| Thought | Reality |
|---------|---------|
| "While I'm here, I'll fix this bug" | No. Report it, don't fix it. |
| "This method should really be extracted" | That's architecture, not plating. |
| "I'll add some error handling" | That changes behavior. Out of scope. |
| "The old code could use cleanup too" | Only touch changed code. |
| "This is too minor to flag" | Minor improvements add up. Flag it. |
| "I'll reorder these members while I'm here" | Only if the file was substantially rewritten. |
| "I should ask the user about this" | Plating is autonomous. Apply and report back. |
| "I should verify this myself before reporting" | That's the food-critic's job. Dispatch it and report. |

## Integration

**Typical workflow position:**
- `oven:order` -> `oven:prep` -> `oven:recipe` -> `oven:cooking` -> **`oven:plating`** (includes food-critic review) -> user decides next steps

**Related skills:**
- **oven:cooking** — Produces the code this skill refines. Dispatches plating as a single agent in its Phase 5.
- **food-critic** — Reviews plating changes for accidental logic errors. Prompt template lives in `skills/cooking/food-critic-prompt.md`.

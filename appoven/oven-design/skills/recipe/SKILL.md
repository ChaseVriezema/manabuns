---
name: recipe
description: "Use after /design (or when you have a validated feature design) to write a batched implementation plan with task sizing, pattern references, and player experience summary"
---

# Recipe

## Overview

Turn design output + architecture notes into a detailed, batched implementation plan. No agents -- the main agent writes this directly since both prep deliverables and the design output are already in context.

**Core principle:** The plan document leads with Player Experience (for the user) and follows with engineering details (for the build agents). The user reviews the player-facing section; the engineering sections are for autonomous execution.

**Announce at start:** "Let me put together the build plan."

## When to Use

- After `/design` completes and the design output is confirmed
- When you have a validated feature design ready to be turned into an implementation plan

**When NOT to use:**
- Before design is confirmed — you need the design output first
- For bug fixes (use debugging workflows instead)

## Inputs

This skill expects:
- **Functionality Map** (from prep) — what the game does today
- **Architecture Notes** (from prep) — internal engineering reference
- **Design Output** (from design) — player flow, scene inventory, feedback notes, edge cases, done criteria

If invoked standalone (user already has a design), gather equivalent context first.

## Plan Mode

This skill operates entirely within plan mode.

- **Coming from oven-design:design:** Call `EnterPlanMode` to begin.
- **Invoked standalone:** Call `EnterPlanMode` before beginning.

## Plan File Naming

Use the default plan file name that Claude Code generates. Do not rename plan files.

## The Process

```
Step 1: Enter plan mode
       ↓
Step 2: Write plan document (all 4 sections)
       ↓
Step 3: Exit plan mode for user approval
       ↓
  Approved? ──no──→ Revise and re-present
       │
       yes
       ↓
Step 4: Handoff to oven-design:build
```

## Plan Document Structure

### Header

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use oven-design:build to implement this plan.

**Goal:** [One sentence in player-experience terms]

**Branch:** [e.g., `feat/my-feature` (create new) or current branch name]

---
```

───────────────────────────────────────────────────────────────
### Section 1: Player Experience (top of plan, for user review)
───────────────────────────────────────────────────────────────

This is what the user sees and confirms. Written entirely in player/gameplay terms.

```markdown
## Player Experience

### Gameplay Flow

[ASCII flow diagram of the new gameplay/UX — the final "after" flow from design]

### Scenes & States

[Scene/state inventory with descriptions — what the player sees in each]

### Feedback

[Visual/audio feedback descriptions — what the player sees and hears at each interaction]

### Edge Cases

[How each edge case is handled — from the design phase decisions]

### Done Criteria

[What the player experiences when this feature is complete — plain language checklist]
```

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Section 2: Pattern Reference (internal, for build agents)
───────────────────────────────────────────────────────────────

Formalized from the prep phase's Architecture Notes. The user doesn't need to review this — it's for the build agents.

```markdown
## Pattern Reference

### Three-Tier Strategy Selection

**Tier:** [1: Follow existing / 2: Composable systems / 3: Greenfield extensible]
**Rationale:** [Why this tier was selected based on codebase context]

### Existing Patterns

[Which existing systems this follows — "Built like [existing system X]"]

### Key Files & Conventions

[Files being followed as reference, naming conventions, folder structure]

### Where New Code Goes

[Exact paths for new files and why they go there]

### Dependencies & Data Flow

[How new code connects to existing systems]
```

**Three-tier strategy integration:**
- **Tier 1 (existing pattern):** Reference the specific pattern being followed, the files that use it, and how the new code mirrors them
- **Tier 2 (no pattern):** Describe the composable system design — clear inputs/outputs, small enough to verify in one play session
- **Tier 3 (greenfield):** Document the extensible patterns chosen (DI, MVVM, config-driven, etc.) and why they fit

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Section 3: Tasks
───────────────────────────────────────────────────────────────

Each task includes:

```markdown
### Task N: [Short Description]

**Size:** S / M / L
**Complexity flag:** [Yes — reason / No]

**Files:**
- Create: `exact/path/to/NewFile.cs`
- Modify: `exact/path/to/Existing.cs`

**Expected behavior:**

GIVEN: [starting state or preconditions]
WHEN:  [action or trigger]
THEN:  [observable result]

**Implementation spec:**

[Detailed blueprint with key code snippets and pattern references.
The build agent writes the final code, adapting this blueprint to the
actual codebase state — resolving imports, matching local conventions,
integrating with existing code.]

[Key code snippets showing the important logic, structure, and interfaces.
Not verbatim copy-paste — the agent adapts to what it finds.]

**Verification:**

[How to verify this task works — build compiles, specific behavior
observable, test passes, etc.]
```

**Rules for tasks:**
- Exact file paths always — no ambiguity about where code goes
- Key code snippets showing the important logic, not complete copy-paste
- Each task is one logical unit of work
- GIVEN/WHEN/THEN for every task
- Verification method for every task
- Size estimate on every task
- Complexity flag when the task has potential to be harder than it looks

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Section 4: Batch Plan
───────────────────────────────────────────────────────────────

```markdown
## Batch Plan

 Batch │ Tasks    │ Size  │ Summary
═══════╪══════════╪═══════╪════════════════════════════════
  1    │ 1, 2, 3  │ S+S+S │ Create models, register types
───────┼──────────┼───────┼────────────────────────────────
  2    │ 4        │ L     │ Core gameplay logic
───────┼──────────┼───────┼────────────────────────────────
  3    │ 5, 6     │ M+S   │ Wire up UI, add config
```

**Batching rules (apply these when grouping tasks):**

| Rule | Rationale |
|------|-----------|
| S tasks batch until ~M equivalent (~3 S per batch) | Keep batches moderate |
| M can pair with one S | Keep batches moderate |
| L always runs solo | Avoid context bloat |
| Same-file tasks can't share a batch | Prevents merge conflicts |
| Dependency order preserved | Within and across batches |
| Batch boundary = commit boundary | Each batch is one commit |
| Complexity-flagged tasks get L treatment | Isolate risky work even if file count suggests S/M |

## Presenting the Plan

1. Write the plan to the plan mode file
2. Call `ExitPlanMode` to present for user approval
3. The user reviews **Section 1: Player Experience** — this is what they care about
4. If approved → proceed to handoff
5. If changes requested:
   - Re-enter plan mode
   - Revise affected sections
   - Re-present for approval

## Handoff Document

After the plan is approved, update the handoff document
before invoking build.

1. Read `.oven/HANDOFF.md` with the Read tool
2. Locate the RECIPE section between `<!-- SECTION:RECIPE -->` and
   `<!-- /SECTION:RECIPE -->`
3. **If the section is empty (first run):**
   Write: plan file path, Player Experience summary (from Section 1
   of the plan), and Batch Plan table (from Section 4).
4. **If the section has content (re-run):**
   Replace entirely with current plan content. Recipe's section is
   derived from the plan file, not from conversation decisions —
   the plan IS the authoritative source, so full replacement is correct.
5. Replace only the RECIPE section. Leave all other sections untouched.
6. Update the **Last updated** date in the header.
7. Stage and commit:
   - `git add .oven/HANDOFF.md`
   - `git commit -m "oven: recipe handoff — [feature name]"`

## Handoff

After updating the handoff document:
- Invoke `oven-design:build` passing the plan file path

## Red Flags — STOP

| Thought | Reality |
|---------|---------|
| "I'll skip the Player Experience section" | It's the user's only review surface. Always include it. |
| "I'll write complete copy-paste code" | Key snippets and blueprints. Build agents adapt to the real codebase. |
| "I'll put all tasks in one batch" | Follow the batching rules. Size and independence matter. |
| "This task is small, no need for GIVEN/WHEN/THEN" | Every task gets expected behavior. No exceptions. |
| "I'll skip the complexity flag" | If a task might be harder than it looks, flag it. |
| "The pattern reference doesn't matter" | Build agents need it to make correct engineering decisions. |

## Key Principles

- **Player Experience first** — top of plan, for user review
- **Pattern Reference for build agents** — formalized architecture notes
- **Blueprint specs, not copy-paste** — key snippets + pattern references
- **Every task gets:** size, files, GIVEN/WHEN/THEN, implementation spec, verification, complexity flag
- **Batching rules enforced** — size-based grouping with safety constraints
- **Three-tier strategy documented** — build agents know which engineering approach to follow
- **Plan file is the source of truth** — saved to `~/.claude/plans/`, revisions edit in place

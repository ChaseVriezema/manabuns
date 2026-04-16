---
name: recipe
description: "Use after oven:prep (or when you already have a design/spec) to write a detailed implementation plan with TDD, complete code, and exact file paths"
---

# Recipe Writing

## Overview

Write comprehensive implementation plans with complete code, TDD cycles, and exact file paths. Assumes the implementing engineer has zero codebase context — document everything they need.

**Core principle:** The main agent owns the entire process: it reads code, surveys for questions, interviews the user, drafts the plan, and presents for approval. No subagents are dispatched.

**Announce at start:** "I'm putting together the recipe."

## Inputs

This skill expects design artifacts (typically from `oven:prep`):
- System map (ASCII diagram, file table, dependency graph)
- Design decisions (user's answers)
- Edge case resolutions
- Branching strategy (new branch + name, or current branch)
- Menu file path (if this plan is part of a multi-plan menu)

If invoked standalone (user already has a spec), gather equivalent context from the user first.

## Plan Mode

This skill operates entirely within plan mode. Plan mode saves the plan to a standard file that persists across sessions.

- **Coming from oven:prep:** Plan mode is already active (order entered it at intake). No action needed.
- **Invoked standalone:** Call `EnterPlanMode` before beginning Phase 1.

## Scope Check

<HARD-GATE>
If the design artifacts describe multiple independent subsystems that weren't decomposed during order, STOP. Do not write a multi-subsystem plan. Send the user back to oven:order to decompose first, or scope the plan down to a single subsystem with user approval.
</HARD-GATE>

## Plan File Naming

Use the default plan file name that Claude Code generates. Do not rename plan files.
</HARD-GATE>

## Main Agent Context Budget

The main agent reads code directly in recipe — it needs exact patterns, signatures, and imports to write complete implementation code. Keep reads targeted: use the file table from prep's design artifacts as a map, don't explore broadly.

**What the main agent works with:**
- Design artifacts (from prep or user)
- Source files (read directly for exact patterns and signatures)
- User's answers to implementation questions
- The plan document (written and revised by main agent)

## The Process

```
Phase 1: Survey (read code, identify questions)
       ↓
Phase 2: Interview (ask questions 1 at a time)
       ↓
Phase 3: Drafting (write full plan, save to disk)
       ↓
  More questions? ──yes──→ Back to Phase 2
       │
       no
       ↓
Phase 4: Present Plan (present for approval)
       ↓
  Approved? ──no──→ Phase 5: Revision (revise plan with feedback)
       │                       ↓
       │                  Back to Phase 4
       yes
       ↓
Phase 6: Execution Handoff
```

### Phase 1: Survey

Read the actual source files referenced in the design artifacts to build implementation-level understanding. Use the file table from prep as your map — read targeted files, don't explore broadly.

**The survey pass:**
1. Read the actual source files to get exact patterns, signatures, imports
2. Identify the closest existing implementation to use as a reference pattern
3. Map file structure — what existing files need to change, what new files to create, what responsibilities each file owns. Lock in decomposition decisions: where boundaries fall, which concerns go in which files. Favor smaller, focused files with clear single responsibilities.
4. Trace the current flow through the affected systems (needed for the Design Overview's before/after diagram)
5. Identify **implementation questions** — choices only the user can make (naming, UX specifics, config values, behavioral edge cases not covered by the design)

**After surveying:**
- **If questions exist:** proceed to Phase 2 (Interview).
- **If no questions:** skip to Phase 3 (Drafting).

### Phase 2: Interview (Main Agent)

Work through the survey questions:

- **One question at a time** — never batch
- **Multiple choice preferred** — use AskUserQuestion with options
- **Lead with recommendation**

Collect all answers, then proceed to Phase 3.

### Phase 3: Drafting

With survey knowledge and the user's answers (if any), write the full plan.

**The drafting pass:**
1. Write the full plan following the document structure below
2. Write complete code (not "add validation here" or "implement logic")
3. Include exact file paths and line ranges for modifications
4. **Save the plan to disk** using the default plan file name
5. Check: did any new questions emerge during drafting?

**If new questions emerged during drafting:** loop back to Phase 2 — interview the user on the new questions, then return here to revise the plan.

**When no outstanding questions remain:** proceed to Phase 4.

### Plan Document Structure

**Header (required):**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use oven:cooking to implement this plan.

**Goal:** [One sentence]

**Architecture:** [2-3 sentences about approach]

**Systems touched:** [List from system map]

**Branch:** [e.g., `feat/my-feature` (create new) or `main` (current branch)]

**Menu:** [path to menu file, e.g., `~/.claude/plans/2026-03-19-my-project-menu.md` — omit if not part of a menu]

---
```

**Design Overview (required):**

This section gives the human reviewer a clear picture of what's changing and why before diving into tasks. It also provides useful architectural context for the implementing agent.

```markdown
## Design Overview

### Flow

<!-- ASCII or mermaid flowchart showing the new behavior.
     If modifying existing flow, show BEFORE and AFTER separately. -->

**Before:**
` ` `
[User action] → [System A] → [System B] → [Result]
` ` `

**After:**
` ` `
[User action] → [System A] → [New Component] → [System B] → [Result]
` ` `

### What's Changing (and What's Not)

**In scope:**
- [Specific change 1 — what it does and why]
- [Specific change 2]

**Out of scope:**
- [Thing that might seem related but isn't changing]
- [Adjacent system that remains untouched]

### Decisions & Rationale

#### [e.g., Where to validate input]
- **Approach:** Controller layer
- **Why:** Keeps models clean, matches existing pattern in `FooController.cs`
- **Matches current codebase:** Yes — all existing validation runs at the controller level
- **Alternative considered:** Model-level validation — rejected because it couples validation to persistence

#### [e.g., Event dispatch strategy]
- **Approach:** Fire-and-forget via existing EventBus
- **Why:** Avoids adding a new dependency; keeps change scope small
- **Matches current codebase:** Yes — `EventBus.Dispatch()` used in 12+ places
- **Alternative considered:** Direct callback — rejected because it creates tight coupling between systems

### Tradeoffs

#### [e.g., Validation location]
- **What we gain:** Clean separation — models stay pure data containers
- **What we give up:** Validation logic can't access model internals directly
- **Why it's worth it:** Matches existing patterns; controller already has access to everything it needs

### Architecture

[2-5 sentences: how new pieces integrate with the existing system. Reference the system map from prep if available. Call out new dependencies, patterns introduced, or coupling points.]

### Risks & Gotchas

- [Known risk or gotcha and what to watch for during review]
```

**Rules for Design Overview:**
- Flow diagrams are REQUIRED — if there's no meaningful flow change, show the existing flow with the modification point highlighted
- Before/After format when modifying existing behavior; single diagram for net-new features
- Each decision must include at least one alternative considered — if no alternatives exist, the decision doesn't need its own block
- Scope boundary must call out at least one "out of scope" item — forces explicit thought about what's NOT changing
- Keep it concise — this is an overview, not a design doc. Details live in the tasks.

---

**File Structure (required):**

Between Design Overview and tasks, lock in the file decomposition plan. Maps directly to the file structure survey (Phase 1, step 3).

` ` `markdown
## File Structure

### Existing Files (modified)

| File | Current Responsibility | What Changes |
|------|----------------------|-------------|
| `exact/path/to/File.cs` | Handles X | Adding Y, modifying Z |

### New Files

| File | Responsibility | Why Separate |
|------|---------------|-------------|
| `exact/path/to/NewFile.cs` | Owns X | Keeps single responsibility; extracted from File.cs |

### Boundary Rules

- [e.g., "NewService talks to GameController only through events"]
- [e.g., "View files never import Model types directly"]
` ` `

**Rules for File Structure:**
- Every file in the plan must appear here — no surprises during implementation
- New files must justify separation (the "Why Separate" column)
- Boundary rules make coupling decisions explicit and reviewable
- If a file would handle more than one concern, split it — smaller files help Claude implement correctly

---

**Task structure:**

Each task is one logical unit of work (2-5 minutes). Follow `oven:mise-en-place` — define expected behavior before coding:

```markdown
### Task N: [Short Description]

**Files:**
- Create: `exact/path/to/NewFile.cs`
- Modify: `exact/path/to/Existing.cs`
- Test: `exact/path/to/Tests/TestFile.cs` (if testable)

- [ ] **Step 1: Define expected behavior**

GIVEN: [starting state or preconditions]
WHEN:  [action or trigger]
THEN:  [observable result]

Verification method: [automated test / manual verification steps — see mise-en-place]

If automated test:
` ` `csharp
[Test]
public void ShouldDoSpecificThing()
{
    // arrange
    var sut = new MyClass();

    // act
    var result = sut.DoThing(input);

    // assert
    Assert.AreEqual(expected, result);
}
` ` `

If manual verification:
1. [Specific step to trigger behavior]
2. [What to observe / check]
3. [Expected outcome]

- [ ] **Step 2: Implement**

` ` `csharp
public class MyClass
{
    public Result DoThing(Input input)
    {
        return expected;
    }
}
` ` `

- [ ] **Step 3: Verify**

Run the verification method from Step 1. Confirm the expected behavior holds.

- [ ] **Step 4: Commit**

` ` `bash
git add exact/paths
git commit -m "feat: add specific thing"
` ` `
```

**Rules for tasks:**
- Exact file paths always — no ambiguity about where code goes
- Complete code in plan — copy-pasteable, not vague directions
- Each step is one action
- **DRY** — see "Plugin-Wide Principles" in CLAUDE.md. If two tasks would produce similar logic, extract to shared utility.
- **YAGNI** — see "Plugin-Wide Principles" in CLAUDE.md
- Frequent commits — one per task minimum
- For Unity: tests run via Test Runner, not CLI
- For non-testable work (UI, animations, views): describe visual verification steps instead of TDD

### Phase 4: Present Plan (Main Agent)

1. Write the received plan to the plan mode file (the path specified in the plan mode system message)
2. Call `ExitPlanMode` — this presents the plan to the user for approval
3. If the user approves → proceed to Phase 6
4. If the user requests changes → proceed to Phase 5

**If a menu file exists** for this project, update the current plan's `Plan file` entry in the menu with the plan file path (use `Edit` tool).

### Phase 5: Revision

1. Call `EnterPlanMode` to re-enter plan mode
2. Read the saved plan file and revise the affected sections using the `Edit` tool based on the user's feedback
3. **Loop back to Phase 4** — call `ExitPlanMode` to re-present the updated plan for approval

The plan file on disk is always the source of truth. Revisions edit it in place.

### Phase 6: Execution Handoff

After plan is approved:

1. Call `ExitPlanMode` — this presents the plan to the user with Claude Code's native approval UI, which includes "Clear context and run" as an option
2. **Do not invoke cooking yourself.** Let the user choose their execution mode via the native plan mode buttons.

The plan header's `REQUIRED SUB-SKILL: Use oven:cooking` directive tells the agent which skill to invoke — whether that's a fresh session (clear context) or the current session (accept and execute). The menu file path is also in the plan header if applicable.

## Key Principles

- **Complete code, not directions** — the plan is copy-pasteable
- **TDD where testable** — test → fail → implement → pass → commit
- **Visual verification where not** — describe what to check in the editor
- **Exact paths always** — no ambiguity about where code goes
- **Bite-sized tasks** — 2-5 minutes each, one logical unit
- **Survey first, draft second** — read code and answer questions before writing the plan, not after
- **Plan file is the source of truth** — revisions edit in place, cooking reads from disk
- **Loop until done** — questions loop, approval loop — no dead ends
- **No subagents** — the main agent owns the entire recipe process end to end
- **Frequent commits** — one per task minimum

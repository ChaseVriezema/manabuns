---
name: menu
description: "Use when you need to browse, manage, create, or continue multi-plan menus — lists active menus, shows progress, creates menus on demand, and lets you pick up where you left off"
---

# Menu Management

## Overview

Browse, manage, and create multi-plan menus. Menus are typically created by `oven:order` when decomposing large requests, but can also be created ad-hoc when the user wants to defer scope or track multiple related plans.

**Announce at start:** "Let me check the menu."

## When to Use

- User wants to see active multi-plan projects
- User wants to continue a menu from a previous session
- User says "continue" and references a menu file path
- User wants to manage menu items (skip, reorder, add, edit, abandon)
- User asks to "add to a menu", "put on a menu", or "create a menu"
- User wants to defer expanded scope from current work into a tracked menu item
- User has an existing plan and wants to add a second phase/scope as a separate tracked item

**When NOT to use:**
- Starting a new feature from scratch (use `oven:order` — it creates menus automatically if scope splits during interpretation)

## The Process

```
Step 1: Scan for menus (or read a specific one)
       ↓
  No menus + user asked to create? ──yes──→ Ad-hoc Creation → Present menu → Done
       │
  Found menus
       ↓
Step 2: List menus (if multiple)
       ↓
Step 3: Show selected menu details
       ↓
Step 4: Present actions
       ↓
  Continue? ──yes──→ Invoke oven:order with menu context
       │
  Management action → Update menu file → Done
```

### Step 1: Scan for Menus

**If the user provided a specific menu file path:** Read that file directly. Skip to Step 3.

**Otherwise:** Scan `~/.claude/plans/*-menu.md` for menu files.

- Read each file's YAML frontmatter to get: name, description, date, status
- Filter to `active` menus by default. If the user asks to see all (or says "show old menus"), include `complete` and `abandoned` menus too.
- If no menus found AND the user asked to create/add to a menu: proceed to **Ad-Hoc Menu Creation** below.
- If no menus found AND the user was just browsing: "No active menus found." — suggest starting a new feature with `oven:order` if they have work to do.
- Old/stale menus are the user's responsibility to clean up. Menus don't expire automatically — they stay until the user marks them complete/abandoned or deletes the file.

### Step 2: List Menus

**If only one active menu:** Select it automatically, skip to Step 3.

**If multiple active menus:** Display a summary of each:

| Menu | Description | Date | Progress |
|------|------------|------|----------|
| project-name | one-line description | 2026-03-11 | 2/4 done |

Use `AskUserQuestion` to let the user pick which menu to work with. Include the description and progress in the option labels.

### Step 3: Show Selected Menu

Display the full menu contents:
- Project name and overall goal
- Each plan with: name, goal, status, plan file path (if created), branch (if created), dependencies
- Highlight the next pending plan (first by dependency order, then by list order)
- Show overall progress (e.g., "2 of 4 plans complete")

### Step 4: Present Actions

Use `AskUserQuestion` with available actions based on menu state:

**Always available:**
- **Resume in-progress plan** — if any plan is stuck `in-progress` (crashed/interrupted session), offer to resume it first. This takes priority over continuing the next pending plan.
- **Continue next plan** — start the next pending plan via `oven:order`. Show which plan and its goal. If the next plan has an unfinished dependency, show a heads-up (informational only, don't block).
- **Pick a specific plan** — choose any pending or in-progress plan to start/resume, regardless of order. Show dependency info as context.

**Management actions:**
- **Reorder plans** — move a plan to a different position in the queue. Ask which plan and where to move it. Renumber the `### N.` headings in the menu file.
- **Skip a plan** — mark a pending plan as `skipped` in the menu file. Ask which plan to skip.
- **Add a plan** — append a new sub-plan. Ask for name, goal, and dependencies. Write it to the menu file.
- **Edit a plan's goal** — update the goal text of a pending plan. Ask which plan and what the new goal is.
- **Mark menu abandoned** — set menu frontmatter status to `abandoned`. Confirm first.
- **Mark menu complete** — set menu frontmatter status to `complete`. Only available if all plans are `done` or `skipped`.

### Continuing a Plan

When the user picks "Continue next plan" or "Pick a specific plan":

1. Note the selected plan's name and goal
2. Invoke `oven:order`, passing the menu file path and the selected plan's context
3. Order's Menu Resume handles the rest — it reads the menu, confirms stored context against current state, marks the plan in-progress, and runs the full order→prep→recipe→cooking cycle

### Ad-Hoc Menu Creation

When the user asks to create a menu or add something to a menu outside of `oven:order`'s scope check flow:

**1. Identify the plans from conversation context:**
- Is there an existing plan file? → That becomes a plan entry. Link to its plan file path and set status based on its current state (`done` if already executed, `in-progress` if mid-execution, `pending` if not yet started).
- Is the user deferring expanded scope? → Capture their description as a new `pending` plan entry.
- Is the user listing multiple items to track? → Each becomes its own plan entry.

**2. Capture context for deferred plans.**
When a plan is being deferred (not starting immediately), capture **everything** a future session needs in the `**Context:**` field. This is critical — each plan runs in a fresh context window, so anything not written here is lost forever.

Include:
- The user's original description of requirements (quote or closely paraphrase their words)
- Design decisions made during conversation and the reasoning behind them
- Rejected alternatives and why they were rejected
- Constraints, dependencies, or requirements that came up in discussion
- Any relevant synthesis output (system primer excerpts, dependency info, edge cases identified)

**Err on the side of too much context.** A verbose context field costs nothing; a missing decision costs the user repeating themselves. When ANY upfront conversation happened, this field is MANDATORY.

**3. Validate plan sizing.**
Each menu item represents a full prep→recipe→cooking cycle. That overhead is only justified for substantial work:
- Target **10-20 file changes** per plan with **1-2 clear overarching goals**
- If a proposed item is under 5 files or has a single trivial goal, merge it into a related plan
- If a single goal is genuinely large and can't be decomposed, it's fine as one big plan
- When in doubt, err toward fewer, larger plans over many small ones

<HARD-GATE>
**4. Write the menu file** at `~/.claude/plans/<project-name>-menu.md` — file name must end with `-menu.md` (see "Menu File Naming" in CLAUDE.md).
</HARD-GATE>

Use the standard template (see `oven:order`'s Menu File Format). Every plan gets a `**Context:**` and `**Scope:**` field — including ones starting immediately.

**5. Present the created menu for confirmation.**
Show the user the full menu with:
- Each plan's name, goal, scope, and context
- **What was captured** from the conversation — call out specific decisions and constraints embedded in context fields
- **What was omitted or deferred** — flag anything discussed but left out, and explain why
- Dependency order and whether the proposed sequencing makes sense
- Any cross-plan concerns (shared interfaces, data formats) that need consistency

Use `AskUserQuestion` to confirm:
- "Looks good" — menu is accurate
- "Needs changes" — user provides corrections

Iterate until the user confirms. Context loss is the primary failure mode of menus — this checkpoint catches it.

**Example scenario:**
User is looking at an existing IAP analytics plan and says "I also want to add inventory tracking to all gameplay events, but let's hold off — add it to a menu and keep the original scope."

Result:
- Plan 1: IAP Analytics → links to existing plan file, status matches current state
- Plan 2: General Gameplay Inventory Tracking → goal captures the one-liner, **Context** captures the user's full description ("inventory metadata on all gameplay events, inventory after field filled out for all events, before/after/diff when change detected")

## Menu File Operations

All menu file edits use the `Edit` tool. Always `Read` the file first, then make targeted edits.

- **Status updates:** Change the `- **Status:**` line for the affected plan
- **Adding plans:** Append a new `### N. <Plan Name>` section at the end of the `## Plans` section
- **Reordering:** Move the `### N.` section to its new position and renumber all plan headings sequentially. Update any `- **Depends on:**` references that used plan numbers.
- **Skipping:** Change status to `skipped`
- **Frontmatter updates:** Update `status:` field when marking abandoned/complete
- **Goal edits:** Replace the `- **Goal:**` line for the affected plan

## Key Principles

- **Menu is a living document** — it evolves as the project progresses
- **Dependencies are informational** — show them, don't enforce them
- **Full prep cycle per plan** — every sub-plan gets complete exploration and design
- **Fresh context per plan** — each plan runs in its own session for clean context
- **Simple file operations** — read, edit, done. No complex state management.

---
name: prep
description: "Use when starting a new feature or prototype to map what the game currently does before designing changes"
---

# Prep

## Overview

Map what exists -- both a player-facing functionality overview and an internal architecture reference for the planner. The user only sees the functionality layer.

**Core principle:** One explore agent maps the codebase and returns two deliverables. The main agent presents the player-facing one and holds the engineering one silently for later phases.

**Announce at start:** After branch setup completes, "Let me take a look at what your game does today."

## Branch Setup

<HARD-GATE>
This is the FIRST thing that happens — before exploration, before announcing, before anything else.

1. Run `git branch --show-current` to get the current branch name
2. Present the user with an AskUserQuestion based on the current branch:

   **If on a feature branch** (anything other than `main` or `master`):
   - **Option 1 (default):** Stay on `<current-branch>` (Recommended)
   - **Option 2:** Create a new branch — suggest `feat/<kebab-case-summary>` based on the feature request

   **If on `main` or `master`:**
   - **Option 1 (default):** Create a new branch — suggest `feat/<kebab-case-summary>` based on the feature request (Recommended)
   - **Option 2:** Stay on `<current-branch>` — description says "Not available — you're on [branch name]". If selected, re-prompt with only option 1 and Other.

   Both cases support **Other** via AskUserQuestion's built-in input for a custom branch name.

3. Act on the selection:
   - New branch or custom name: run `git checkout -b <branch-name>`
   - Stay on current: proceed without switching
4. Only THEN announce and begin exploration.
</HARD-GATE>

## When to Use

- User wants to build, add, or change something in their game
- Starting a new feature or prototype
- Any task where understanding the current game state is needed before designing

**When NOT to use:**
- Bug fixes
- Single-line changes
- Pure refactoring with no behavioral change

## Execution

Dispatch a **single general-purpose agent** via the Agent tool. The agent explores the codebase and returns both deliverables in a single response.

**What to pass the agent:**
- The user's feature request / description
- Any files or areas the user pointed to
- Instruction to return both deliverables (Functionality Map + Architecture Notes) in a single structured response

**Agent prompt structure:**

```
Agent tool (general-purpose):
  description: "Map game functionality and architecture"
  prompt: |
    You are exploring a game codebase to understand what it does today.
    Return TWO deliverables in your response, clearly separated.

    ## Feature Context

    [The user's feature request — what they want to build or change]

    ## Starting Points

    [Any files or areas the user mentioned, or "Explore from scratch"]

    ## Deliverable 1: Functionality Map

    Map what the game does from a PLAYER'S perspective. Use game design
    vocabulary — players, scenes, loops, effects — never engineering terms.

    Include:
    - Gameplay systems and loops inventory
    - Scene/menu/screen inventory with descriptions
    - Player flows (ASCII flow diagrams showing how the player moves
      through the game)
    - Data the player interacts with (what they see, create, earn, spend)
    - Audio/visual feedback that exists (animations, effects, sounds)

    Example flow:

      ┌───────────┐    ┌────────────┐    ┌──────────┐
      │ Main Menu │───→│  Gameplay  │───→│ Results  │
      └───────────┘    └────────────┘    └──────────┘
                            │
                            ▼
                       ┌──────────┐
                       │ Inventory │───→ Equip / Sell / Upgrade
                       └──────────┘

    ## Deliverable 2: Architecture Notes

    Map the engineering structure (this will NOT be shown to the user).

    Include:
    - File structure and responsibilities
    - Existing patterns (how similar features were built)
    - Data flow and dependencies between systems
    - Conventions (naming, folder structure, service patterns)
    - Where new code should go based on existing patterns
    - Testability surface (what can be unit tested, what needs manual
      verification)
```

## Context Flow

Both deliverables return to the main agent. From that point forward:

- **Functionality Map** is shown to the user as "Here's what your game does today. This is what I'll be working with when we design your new feature."
- **Architecture Notes** are held silently in context — used by design and recipe phases to inform question selection, edge case relevance, and pattern strategy. Never surfaced to the user.

## After Presenting the Functionality Map

Once the user has seen the Functionality Map:

1. Ask if the map looks accurate — "Does this capture what your game does, or am I missing anything?"
2. If the user corrects something, update the map accordingly
3. Once confirmed, write the handoff document (see Handoff Document section below)
4. Invoke `oven-design:design` — passing both deliverables in context

## Handoff Document

After the user confirms the Functionality Map, update the handoff document
before invoking design.

**If `.oven/HANDOFF.md` does not exist:**
1. Create the file using the handoff template (see below)
2. Populate the PREP section with:
   - The confirmed Functionality Map
   - Architecture Notes condensed for engineer readability (patterns,
     conventions, key files, where new code goes, testability)
3. Leave DESIGN, RECIPE, and BUILD sections as empty placeholders
   (keep the sentinel comments, remove the placeholder descriptions)
4. Stage and commit:
   - `git add .oven/HANDOFF.md`
   - `git commit -m "oven: prep handoff — [feature name]"`

**If `.oven/HANDOFF.md` already exists (re-run):**
1. Read the file with the Read tool
2. Locate the PREP section between `<!-- SECTION:PREP -->` and
   `<!-- /SECTION:PREP -->`
3. Compare existing content against current conversation:
   - Decisions from THIS session are authoritative (override conflicts)
   - Decisions in the existing doc not discussed this session stay as-is
   - New findings from this session get added
4. Replace only the PREP section. Leave all other sections untouched.
5. Update the **Last updated** date in the header.
6. Stage and commit:
   - `git add .oven/HANDOFF.md`
   - `git commit -m "oven: update prep handoff — [feature name]"`

### Handoff Template

```markdown
# Feature Handoff

**Branch:** [branch name]
**Feature:** [one-line player-experience description]
**Last updated:** [date]

---

<!-- SECTION:PREP -->
## What Exists Today

### Functionality Map

[The confirmed player-facing Functionality Map — systems, flows, scenes]

### Architecture Summary

[Architecture Notes condensed for engineer consumption: patterns found,
conventions, key file locations, where new code should go, testability]

<!-- /SECTION:PREP -->

---

<!-- SECTION:DESIGN -->
## What We're Building

<!-- /SECTION:DESIGN -->

---

<!-- SECTION:RECIPE -->
## The Plan

<!-- /SECTION:RECIPE -->

---

<!-- SECTION:BUILD -->
## What Was Built

<!-- /SECTION:BUILD -->
```

## Red Flags — STOP

| Thought | Reality |
|---------|---------|
| "I'll show them the architecture notes" | Architecture Notes are internal only. Never surface. |
| "I'll skip exploration, I know this codebase" | Agents find what you miss. Explore anyway. |
| "I'll use engineering terms to be precise" | Player-experience vocabulary always. No exceptions. |
| "The user doesn't need to see the functionality map" | The map is how the user confirms you understand their game. Always present it. |
| "I'll start designing before the user confirms the map" | Confirm the map first. Design starts in the next phase. |

## Key Principles

- **One agent, two deliverables** — simple and focused
- **Player-experience vocabulary** for everything the user sees
- **Architecture Notes are internal** — inform later phases silently
- **Confirm before moving on** — the user validates the Functionality Map before design begins
- **Handoff to design** — invoke `oven-design:design` after confirmation

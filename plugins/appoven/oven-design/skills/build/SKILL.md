---
name: build
description: "Use after /recipe (or when you have an approved implementation plan) to autonomously execute the batched plan, review with food-critic, and verify completion"
---

# Build

## Overview

Autonomous execution of the batched plan. No user check-ins until done (or until a complexity wall is hit).

**Core principle:** One agent per batch, food-critic review after all batches, self-fix loop for non-critical issues, complexity escape valve when things get too hard.

**Announce at start:** "Time to build — I'll work through this and check in when it's done."

## When to Use

- You have an approved implementation plan (from `oven-design:recipe`)
- Plan has a batch plan with sized tasks
- You're ready to build

**When NOT to use:**
- You don't have a plan yet (use `/prep` → `/design` → `/recipe` first)
- For bug fixes or debugging
- The plan is a single tiny task (just do it directly)

## Branch Safety

<HARD-GATE>
NEVER execute implementation directly on main/master. Before starting, verify you're on a feature branch. If not, create one and switch to it.
</HARD-GATE>

## No Auto-Push

<HARD-GATE>
NEVER push to the remote. Commit freely, but leave pushing to the user. This applies to the main agent, batch implementer agents, and fix agents — none of them should run `git push`.

**Exception:** `oven-design:serve` is the only oven-design skill permitted
to push. This gate applies to prep, design, recipe, build, and all
sub-agents.
</HARD-GATE>

## Progress Tracking

Use `TaskCreate` / `TaskUpdate` for live progress:

```
TaskCreate: subject="Batch 1: [summary]", description="[tasks in this batch]"
TaskCreate: subject="Batch 2: [summary]", description="[tasks in this batch]"
... (one per batch)
TaskCreate: subject="Food Critic Review", description="Full plan + diff review"
TaskCreate: subject="Verification", description="Build, tests, clean tree"
```

**Rules:**
- One task per batch, created at the start
- Mark `in_progress` when the batch agent is dispatched
- Mark `completed` when the commit is verified
- Food-critic and verification tracked as separate tasks
- If the complexity escape valve triggers, update the affected batch task

## The Process

```
Step 1: Load Plan (read recipe, extract batches, verify branch)
       ↓
Step 2: Execute Batches (one agent per batch, sequential)
       ↓
  Per batch: Dispatch → Verify commit → Next
       ↓
Step 3: Food-Critic Review (single Sonnet agent)
       ↓
Step 4: Self-Fix Loop (if Critical/Important findings)
       ↓
  Max 2 iterations, then surface to user
       ↓
Step 5: Verification & Completion
```

───────────────────────────────────────────────────────────────
### Step 1: Load Plan
───────────────────────────────────────────────────────────────

1. Read the plan file (passed from `oven-design:recipe` or provided by the user)
2. Extract the batch plan — which tasks are in each batch, in order
3. Extract the Pattern Reference section — build agents need this
4. Verify branch: `git branch --show-current` — must NOT be main/master
5. If on main/master, create and switch: `git checkout -b feat/<feature-name>`
6. **Check for resumption** — see Session Resumption section below

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 2: Execute Batches
───────────────────────────────────────────────────────────────

Sequential execution — one **Sonnet** agent per batch via the Agent tool.

**What to pass each batch agent** (use `implementer-prompt.md` template):
- All tasks in the batch (full spec with key code snippets from the plan)
- The Pattern Reference section from the recipe
- Scene-setting: which batches came before, what they built
- Instruction: implement all tasks, self-review, commit with descriptive message

**After each batch agent returns:**
1. Verify the commit landed: `git log -1 --oneline`
2. Collect any self-review concerns
3. Update the batch task to `completed`
4. Move to next batch

**Batch agent statuses:**

| Status | Action |
|--------|--------|
| **DONE** | Collect concerns, proceed to next batch |
| **DONE_WITH_CONCERNS** | Read concerns. If correctness/scope issue, assess before proceeding. If observational, note and proceed. |
| **NEEDS_CONTEXT** | Provide context, re-dispatch |
| **BLOCKED** | Trigger complexity escape valve (Step 5 below) |

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 3: Food-Critic Review
───────────────────────────────────────────────────────────────

After all batches complete, dispatch a **single general-purpose agent on Sonnet** via the Agent tool.

```
Agent tool (general-purpose):
  description: "Food critic review of [feature name]"
  model: sonnet
```

**What to pass the food-critic** (use `food-critic-prompt.md` template):
- Full plan text (Player Experience + Pattern Reference + all tasks)
- All batch implementer concerns, organized by batch
- Full git diff from branch start: `git diff main...HEAD`
- Use the **build review** context block from the template

**The food-critic reviews:**
- Correctness against plan
- Pattern adherence (three-tier strategy from Pattern Reference)
- Scope discipline (no unplanned additions)
- Player experience spec alignment (does the implementation match Section 1?)

**Reports findings as:** Critical / Important / Minor

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 4: Self-Fix Loop
───────────────────────────────────────────────────────────────

- **Critical and Important findings** are fixed automatically (no user input needed)
- **Small fixes:** Main agent applies directly
- **Larger fixes:** Dispatch a general-purpose Sonnet fix agent with the finding details and relevant code
- **After fixing Critical findings:** Re-run food-critic on the full diff to verify
- **Max 2 fix iterations** — if still failing after 2 rounds, surface remaining findings to the user
- **Minor findings:** Fix if quick, otherwise note for user in completion report

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Complexity Escape Valve
───────────────────────────────────────────────────────────────

**Triggers when:**
- An implementer returns BLOCKED or estimates significant scope beyond plan
- Food-critic flags something as architecturally unsound
- A fix iteration fails to resolve critical findings
- Following existing patterns isn't feasible for a specific task

**When triggered, pause and present to user using the Presenting Options Format from CLAUDE.md:**

╔═══════════════════════════════════════════════════════════════╗
║  `This part turned out to be more complex than expected`       ║
╚═══════════════════════════════════════════════════════════════╝

[plain-language explanation of what's hard and why, in player-experience terms]

\*

📌 ═══ `Option A: [simpler alternative, ~90% of the goal]` ═══

[description in player-experience terms]

|   | Detail |
|---|--------|
| ✅ | [what the player still gets] |
| ❌ | [what the player loses vs original] |

\*

📌 ═══ `Option B: [different simpler alternative]` ═══

[description in player-experience terms]

|   | Detail |
|---|--------|
| ✅ | [what the player still gets] |
| ❌ | [what the player loses vs original] |

\*

📌 ═══ `Option C: Attempt the original approach` ═══

|   | Detail |
|---|--------|
| ✅ | Full original vision |
| ❌ | May take significantly longer |

<HARD-GATE>
Alternatives MUST be framed in player-experience terms:
- "Option A means the animation plays but doesn't blend between states"
- NOT "Option A skips the state machine implementation"
</HARD-GATE>

After user chooses, re-plan the affected tasks and continue execution.

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 5: Verification & Completion
───────────────────────────────────────────────────────────────

Before reporting done:

1. **Proof verification** — build compiles, tests pass (if applicable)
2. **All changes committed** — no uncommitted work left behind
3. **Clean working tree** — `git status` confirms clean state
4. **If uncommitted changes exist** — commit them with a descriptive message

**Update the handoff document:**

1. Read `.oven/HANDOFF.md` with the Read tool.
   If the file does not exist, skip the handoff update and note it in the
   completion report ("No handoff document found — skipping handoff update").
2. Locate the BUILD section between `<!-- SECTION:BUILD -->` and
   `<!-- /SECTION:BUILD -->`
3. Write the build results:
   - Completion status (Complete / Partial with batch count)
   - Plain-language summary of what was built (player terms)
   - Each batch: status, commit hash, one-line description
   - Deviations from plan (escape valve choices, adjustments, or "None")
   - Food-critic verdict and any remaining notes
4. **If the section has content (re-run):** Replace entirely.
   Build results are factual outcomes, not accumulated decisions —
   the latest build run is the truth.
5. Replace only the BUILD section. Leave all other sections untouched.
6. Update the **Last updated** date in the header.
7. Stage and commit:
   - `git add .oven/HANDOFF.md`
   - `git commit -m "oven: build handoff — [feature name]"`

**Completion report to user (in player-experience terms):**
- "Here's what you asked for, here's what got built"
- Plain language summary tied to the Player Experience section of the plan
- Which batches completed
- Food-critic verdict
- Any deviations from original plan (escape valve choices, minor adjustments)

## Session Resumption

If a session ends mid-build, the user can re-invoke `/build`. The skill:

1. Reads the plan file from `~/.claude/plans/`
2. Checks the branch's commit history: `git log --oneline`
3. Matches commit messages against batch summaries to identify completed batches
4. Resumes from the next incomplete batch
5. Announces: "Picking up where we left off — Batch N is next."

## Red Flags — STOP

| Thought | Reality |
|---------|---------|
| "I'll check in with the user between batches" | Autonomous until done or blocked. No check-ins. |
| "I'll skip the food-critic, everything looks fine" | Food-critic review is mandatory. Never skip. |
| "I'll fix things the critic missed" | Only fix what the critic flagged. Don't improvise. |
| "The escape valve is too heavy, I'll push through" | Complexity walls exist for a reason. Pause and present options. |
| "I'll use engineering terms in the escape valve" | Player-experience vocabulary. Always. |
| "I'll keep trying after 2 fix iterations" | 2 iterations max. Then surface to user. |

## Key Principles

- **One agent per batch** — not per task. Batch boundaries from the recipe.
- **Autonomous execution** — no user check-ins until done or wall hit
- **Food-critic on Sonnet** — reviews full plan against full diff
- **Self-fix loop** — Critical/Important fixed automatically, max 2 iterations
- **Complexity escape valve** — 2 simpler alternatives + original option, all in player terms
- **Session resumption** — re-invoke `/build` to pick up where you left off
- **Verification before claiming done** — build, tests, clean tree, then report

## Supporting Files

- **`implementer-prompt.md`** — Batch implementer agent prompt template
- **`food-critic-prompt.md`** — Food-critic review agent prompt template

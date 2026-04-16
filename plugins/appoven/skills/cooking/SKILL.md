---
name: cooking
description: "Use after oven:recipe (or when you have an approved implementation plan) to execute tasks inline with food-critic review and single-agent plating"
---

# Cooking

## Overview

Execute implementation plans inline with food-critic review and single-agent plating.

**Core principle:** Direct implementation + food-critic review + autonomous plating = quality with minimal agent overhead.

**Announce at start:** "Time to start cooking — let me fire up the stove."

## When to Use

- You have an approved implementation plan (from `oven:recipe` or equivalent)
- Plan has discrete tasks
- You're ready to write code

**When NOT to use:**
- You don't have a plan yet (use `oven:order` then `oven:prep` then `oven:recipe` first)
- You're debugging (use `oven:smoke-check`)
- The "plan" is a single task (just do it)

## Branch Strategy

<HARD-GATE>
Before starting Phase 1, resolve the branching strategy. If the plan's `**Branch:**` field specifies a branch, use it directly — announce which branch and create/switch as needed, no confirmation required. Only fall back to asking the user via `AskUserQuestion` when the plan has no branch specified. Always respect the user's choice if asked — even if it's main.
</HARD-GATE>

## Progress Tracker

See "Progress Tracker Pattern" in CLAUDE.md for the standard rules. Create phase tasks at the start:

```
TaskCreate: subject="Phase 0: Branch Check", description="Use branch from plan, or ask user if not specified"
TaskCreate: subject="Phase 1: Load Plan", description="Read plan, extract tasks, note dependencies"
TaskCreate: subject="Phase 2: Implement Tasks Directly", description="Implement tasks inline, self-review each", activeForm="Executing tasks"
TaskCreate: subject="Phase 3: Food Critic Review", description="Dispatch food-critic to review full implementation"
TaskCreate: subject="Phase 4: Fix Food-Critic Findings Directly", description="Address food-critic findings (if needed)"
TaskCreate: subject="Phase 5: Plating Agent + Food-Critic Plating Review", description="Single plating agent, then food-critic plating review"
TaskCreate: subject="Phase 5b: Final Commit Gate", description="Verify all changes committed, nothing left behind"
TaskCreate: subject="Phase 6: Menu Check", description="Update menu, offer next plan or wrap up"
TaskCreate: subject="Phase 6b: Menu Context Propagation", description="Propagate implementation learnings to future menu plans"
TaskCreate: subject="Phase 7: Deferred Design Decisions", description="Surface design decisions deferred during Phase 4, route to order if needed"
```

**Do NOT create individual tasks for each implementation task** — the task tools don't support subtask nesting, so they'd appear as flat siblings of the phase tasks. Instead, track implementation progress through the Phase 2 task:

- Update Phase 2's `activeForm` with the current task name (e.g., `"Implementing: Dictionary lookups in Update callbacks"`)
- Update Phase 2's subject with the running count (e.g., `"Phase 2: Implement Tasks Directly (2/4)"`)
- Output a brief text status line after each task completes: `Task N/[total]: [name] — done. [concerns if any]`

**Rules:**
- Mark each phase task `in_progress` when starting, `completed` when done
- Track individual implementation task progress via Phase 2 subject + activeForm updates (not separate tasks)
- If Phase 4 has no fixes needed, mark it `completed` with subject "Phase 4: Fix Food-Critic Findings Directly (none needed)"

## The Process

```
Phase 0: Branch Setup (verify/create feature branch)
       |
Phase 1: Load Plan
       |
Phase 2: Implement all tasks directly
       |  (self-review each task, accumulate concerns)
       |
Phase 3: Food Critic Review (one-shot agent)
       |  (agent fails? → Agent Failure Recovery → re-dispatch or escalate)
       |
  PASS? ──yes──────────────────────────────── Phase 5
       |
       no (NEEDS FIXES)
       |
Phase 4: Main agent fixes directly
       |  commit fixes
       |  Fresh food-critic re-review (cumulative context)
       |  (agent fails? → Agent Failure Recovery)
       |
  PASS? ──yes──────────────────────────────── Phase 5
       |
       no ──► fix again → commit → fresh re-review (max 2 cycles)
              after 2 cycles ──► present to user ──► Phase 5
       |
Phase 5: Plating agent (one-shot)
       |  PLATING_COMPLETE ──► food-critic plating review
       |  PLATING_NOTHING ──► skip to Phase 5b
       |  PLATING_BLOCKED / empty ──► re-dispatch or skip
       |
  Food-critic plating review (one-shot)
       |  (agent fails? → Agent Failure Recovery)
       |
  Logic errors? ──yes──► Revert + commit revert
       |
       no
       |
Phase 5b: Final Commit Gate (verify clean working tree)
       |
Phase 6: Menu Check (if multi-plan menu exists)
       |
  Pending plans? ──no──► Phase 7
       |
       yes
       |
Phase 6b: Menu Context Propagation
       |
  Gather learnings → confirm with user → update menu
       |
  Announce next plan + print /menu continue command
       |
Phase 7: Deferred Design Decisions (if any)
       |
  Decisions? ──no──► Done
       |
       yes
       |
  Route to order? ──yes──► invoke oven:order
       |
       no ──► print list, done
```

### Phase 0: Branch Check

1. **Locate the plan file** — passed from `oven:recipe` or provided by the user. If no path was given, check `~/.claude/plans/` for the most recent plan file.
2. Check current branch: `git branch --show-current`
3. Read the plan header and extract the `**Branch:**` field.
4. **If the plan specifies a branch** (any value other than "not yet created" or empty):
   - Announce: "Using branch `{{branch}}` from the plan."
   - If the branch doesn't exist yet, create it and switch to it.
   - If the branch exists but isn't the current branch, switch to it.
   - If already on the correct branch, proceed.
5. **If the plan has no branch field, or the value is "not yet created" / empty**, fall back to asking the user:

```
AskUserQuestion:
  question: "You're on `{{current branch}}`. Want to stay here or create a feature branch?"
  header: "Branch strategy"
  options:
    - label: "Stay on {{current branch}}"
      description: "Work directly on the current branch"
    - label: "New branch"
      description: "Create a feature branch before starting"
```

6. **Respect the answer.** If the user picks "Stay on {{current branch}}", proceed — even if it's main.
7. If the user picks "New branch", suggest a name based on the plan (e.g., `feat/<plan-name>`) and create it.

### Phase 1: Load Plan

1. Read the plan file from disk (already located in Phase 0).
2. Extract ALL tasks with their full text upfront
3. Note inter-task dependencies (which tasks depend on prior tasks)
4. **Extract the menu file path** from the plan header's `**Menu:**` field (if present). This is the menu to update in Phase 6. If the field is absent or omitted, fall back to scanning `~/.claude/plans/*-menu.md` in Phase 6.
5. **If concerns about the plan:** Raise them with the user before starting

### Phase 2: Implement Tasks Directly

For each task, in plan order:

#### 2a: Define Expected Behavior

<HARD-GATE>
Follow `oven:mise-en-place` — define GIVEN/WHEN/THEN before writing any implementation code. Choose a verification method from the mise-en-place table. No implementation without a behavior spec. This is not optional for "obvious" tasks.
</HARD-GATE>

#### 2b: Implement

1. Read the task spec from the plan
2. Implement exactly what the task specifies
3. Follow the plan's File Structure section for decomposition rules

<HARD-GATE>
**Verify before claiming done.** Use `oven:proof` — run verification, confirm output matches expected behavior from Step 2a. Do not skip this because the code "looks right."
</HARD-GATE>

<HARD-GATE>
**Commit after every task.** Each task gets its own commit before moving to self-review or the next task. If you haven't committed, you aren't done with the task. Downstream reviews depend on accurate git diffs — uncommitted work is invisible to them.
</HARD-GATE>

#### 2c: Self-Review (Report Only — Do NOT Fix)

<HARD-GATE>
After completing each task, self-review your work. For each concern you find, **record it** — do NOT fix it. Your honest assessment feeds the food-critic reviewer in Phase 3. If you fix your own concerns, it undermines the food-critic review's purpose.
</HARD-GATE>

**Check:**

**Completeness:**
- Did you implement everything in the spec?
- Are there requirements you might have missed?
- Edge cases you didn't handle?

**Quality:**
- Are names clear and accurate?
- Is the code clean and maintainable?
- Anything you'd flag in code review?

**Discipline:**
- Did you avoid overbuilding (YAGNI)?
- Did you avoid duplicating logic (DRY)? If similar code exists elsewhere, did you extract a shared utility or reuse the existing one?
- Did you only build what was requested?
- Did you follow existing codebase patterns?

**Verification:**
- Did you verify against the expected behavior defined in Step 2a?
- Is the verification method appropriate (automated test if practical, manual steps if not)?

**Code Organization:**
- Are files staying focused and within planned boundaries?
- Any files growing beyond what the plan intended?

**What to record:** A concerns list with file:line references and a description of each concern. "No concerns" is a valid report. Accumulate concerns across tasks — these feed the food critic in Phase 3.

#### 2d: Progress Update

1. Update the Phase 2 task subject with the running count (e.g., `"Phase 2: Implement Tasks Directly (3/7)"`)
2. Update the Phase 2 task `activeForm` to the current task name
3. Output a brief text status line: `Task N/[total]: [name] — done. [concerns if any]`

**Stop conditions — pause and wait for user:**
- Stuck on a task (ask the user)
- Multiple tasks with compounding concerns

### Phase 3: Food Critic Review

<HARD-GATE>
After all tasks complete, dispatch a food-critic review agent via the `Agent` tool (`subagent_type: general-purpose`, `model: sonnet`). The food-critic review is NEVER skipped — regardless of how smoothly tasks went. See `food-critic-prompt.md` in this directory for the complete prompt template.
</HARD-GATE>

**What to pass the food-critic:**
- Full plan text (Design Overview + File Structure + all tasks)
- All self-review concerns, organized by task
- Full git diff from branch start to current HEAD
- Use the **cooking review** context block from the template
- Explicit instruction: **"Your final response text IS your deliverable. Use the Report Format from the prompt template exactly. End with `Verdict: PASS` or `Verdict: NEEDS FIXES`."**

**What NOT to pass:** Your session history, internal deliberation, or task-by-task logs. The reviewer should evaluate the work product, not your thought process.

The food-critic reviews the complete implementation against the plan, investigates self-review concerns, and returns structured findings in its response. Agent completes and is done (one-shot).

**If the agent returns empty, garbled, no output, or has no parseable Verdict line:** follow Agent Failure Recovery and Verdict Parsing in CLAUDE.md. Re-dispatch with a tighter prompt. After 2 failed dispatches, escalate to the user.

### Phase 4: Fix Issues

**If Phase 3 returned `Verdict: PASS`:** skip Phase 4 entirely. Mark it `completed` with subject "Phase 4: Fix Food-Critic Findings Directly (none needed)" and proceed to Phase 5.

<HARD-GATE>
**Bug fix vs. design decision.** Before applying any fix, classify it:

- **Bug fix** — the implementation is wrong relative to the plan. Wrong logic, missing null check the plan specified, incorrect wiring. The plan said X, the code does Y. Fix it.
- **Design decision** — the fix would remove, add, or change behavior beyond what the plan specified. Removing a feature because it's hard to fix, changing an API surface, dropping a capability, adding a fallback the plan didn't call for. These are scope/design decisions disguised as fixes.

**Only apply bug fixes.** Record design decisions in a **deferred design decisions** list (finding number, description, what the fix would have been, why it's a design decision). Do NOT apply them — they route to order after cooking completes.

If you're unsure whether a fix is a bug fix or a design decision, it's a design decision. The test: "Does the plan specify this behavior?" If yes and the code is wrong, it's a bug fix. If the plan doesn't address it, or the fix would change what the plan specified, it's a design decision.
</HARD-GATE>

1. Follow the **Review Triage Flow** in CLAUDE.md ("Food-Critic Severity Response > Review Triage Flow") exactly. Walk findings by severity, AskUserQuestion per item.
2. When the user picks "Fix it" on an item, classify it before applying. If it's a design decision, tell the user: "This is a design decision, not a bug fix — I'll defer it to order after cooking." Record it and move on.
3. Main agent fixes all bug-fix items directly (no subagents).
4. **Commit all fixes** before dispatching the re-review. The food-critic needs an accurate git diff — uncommitted fixes are invisible to it.
5. Dispatch a **fresh food-critic agent** (`subagent_type: general-purpose`, `model: sonnet`) with cumulative context:
   - Prior findings from Phase 3 (so the critic knows what was flagged)
   - Summary of what was fixed, what was skipped, and what was deferred as a design decision
   - Updated git diff
   - Use the **re-review (post-fix)** context block from `food-critic-prompt.md`
   - Instruction: "Re-review the affected areas. Focus on whether the fixes addressed the original findings and whether the fixes introduced new issues."
6. Fresh food-critic returns a structured findings report with a Verdict line. Parse it per Verdict Parsing in CLAUDE.md.
7. **If the agent returns empty, garbled, no output, or has no parseable Verdict line:** follow Agent Failure Recovery and Verdict Parsing in CLAUDE.md.
8. **If PASS:** proceed to Phase 5
9. **If NEEDS FIXES:** main agent fixes again (same classification rule — bug fixes only, defer design decisions) → **commit fixes** → dispatch another fresh food-critic with cumulative context → **max 2 fix+re-review cycles total** (original review + up to 2 fix cycles)
10. After 2 fix+re-review cycles with remaining issues: present remaining findings to the user per Fix Cycle Cap in CLAUDE.md, then proceed to Phase 5. Cooking does not terminate here — the user has seen the findings and can address them later.

<HARD-GATE>
**Fix cycle cap:** If issues persist after 2 fix+re-review cycles, present remaining findings to the user. See "Fix Cycle Cap" in CLAUDE.md.
</HARD-GATE>

### Phase 5: Hand Off to Plating

After reviews pass:

1. Commit any remaining changes from Phase 4 fixes
2. Announce: "All done cooking — let me plate this up."
3. Record the current HEAD SHA (pre-plating marker)
4. Dispatch plating agent: `Agent(subagent_type: general-purpose, model: sonnet)`
   - Plating prompt includes: scope rules (in/out from plating SKILL.md), base branch name, project coding standards, reviewer findings table format, apply rules, commit format
   - Agent autonomously: scopes changeset, reviews, applies, commits
5. Wait for plating agent to return.
   - **`STATUS: PLATING_COMPLETE`** — proceed to step 6.
   - **`STATUS: PLATING_NOTHING`** — zero findings, no changes made. Skip steps 6-10, proceed to Phase 5b.
   - **`STATUS: PLATING_BLOCKED`** — plating couldn't complete. Check for partial commits (diff pre-plating SHA against HEAD). If partial changes exist, revert them. Follow Agent Failure Recovery in CLAUDE.md — re-dispatch with a tighter prompt. After 1 re-dispatch attempt (2 total dispatches), skip plating and proceed to Phase 5b.
   - **Empty, garbled, or no output** — same as PLATING_BLOCKED.
6. Get plating diff: `git diff <pre-plating-SHA>..HEAD`. If the diff is empty, plating didn't commit despite claiming PLATING_COMPLETE — treat as a failed dispatch per Agent Failure Recovery.
7. Dispatch **fresh food-critic agent** (`subagent_type: general-purpose`, `model: sonnet`) with plating diff + **plating review** context block from `food-critic-prompt.md`
8. Food critic returns a structured report focused on logic errors only (narrow plating scope), ending with a Verdict line. One-shot, done. Parse per Verdict Parsing in CLAUDE.md.
9. **If the agent returns empty, garbled, no output, or has no parseable Verdict line:** follow Agent Failure Recovery and Verdict Parsing in CLAUDE.md.
10. **If PASS:** proceed to Phase 5b
11. **If logic errors flagged:** revert the specific flagged changes, then commit the revert with message `revert: plating changes that introduced logic errors`. Plating is cosmetic — reverting is always safe and preferable to patching. Do NOT attempt to fix plating errors.

### Phase 5b: Final Commit Gate

<HARD-GATE>
Before moving to Phase 6, ALL changes must be committed. Never leave uncommitted work behind.
</HARD-GATE>

1. Run `git status` to check for any uncommitted changes (staged or unstaged, including untracked files)
2. **If clean:** Proceed to Phase 6
3. **If uncommitted changes exist:**
   - Stage and commit all remaining changes with a descriptive message (e.g., `feat: <plan-name> — final implementation`)
   - Never push — see "Never Push" in CLAUDE.md
4. Run `git status` again to confirm the working tree is clean before proceeding

### Phase 6: Menu Check

After the commit gate passes, check if this plan is part of a multi-plan menu.

1. **Use the menu file path extracted in Phase 1** (from the plan header's `**Menu:**` field). If Phase 1 didn't find one, check `~/.claude/plans/*-menu.md` for a menu that references the current plan file.
2. **If no menu found:** Mark Phase 6 as `completed` with subject "Phase 6: Menu Check (no menu)". Done — skip to Phase 7.
3. **If menu found:**
   a. Update the menu file: mark the current plan as `done` (regardless of whether it was `in-progress` or `pending`), record the branch name (use `Edit` tool)
   b. Check for remaining `pending` or `in-progress` plans
   c. **If no pending plans remain:** Mark menu status as `complete` in the frontmatter. Announce: "All courses served — menu complete!" Mark Phase 6 as `completed`. Skip to Phase 7.
   d. **If pending plans exist:** Show the menu status (which plans are done, which is next, the next plan's goal). Mark Phase 6 as `completed`. Proceed to Phase 6b — context propagation happens before the stop/continue decision.

### Phase 6b: Menu Context Propagation

<HARD-GATE>
If the menu has pending plans after Phase 6, this phase is mandatory. Do not skip it. Implementation learnings that aren't propagated to future plans are lost when the session ends.
</HARD-GATE>

**If no menu was found in Phase 6, or no pending plans remain:** Mark Phase 6b as `completed` with subject "Phase 6b: Menu Context Propagation (no pending plans)". Skip to Phase 7.

**If pending plans exist:**

1. **Gather implementation learnings relevant to future plans.** Review what cooking discovered during implementation and identify information that future plans need but wouldn't have from the existing menu context. Look for:
   - **Interface contracts established** — APIs, data formats, event signatures, or public surfaces created by this plan that future plans will consume or extend
   - **Patterns and conventions established** — naming, structure, data flow, or architectural patterns that future plans in the same area should follow
   - **Dependencies created** — new systems, files, or behaviors that future plans now depend on or must account for
   - **Deferred work items** — things explicitly skipped or stubbed during implementation that a future plan must complete (e.g., "hardcoded value here, Plan 3 should make this configurable")
   - **Gotchas and constraints discovered** — unexpected limitations, edge cases, or technical constraints that surfaced during implementation and affect future plans
   - **Scope items the user deferred** — things the user said "not now" to during fix triage or food-critic review that map to a specific future plan

2. **Match learnings to specific plans.** For each pending plan, identify which learnings are relevant to that plan's goal and scope. Not every learning applies to every plan — be precise.

<HARD-GATE>
The user must confirm proposed context additions before any writes happen. Present the additions first, get approval, then write.
</HARD-GATE>

3. **Present the proposed additions to the user.** For each pending plan that has relevant learnings, show:
   - The plan name and goal (for reference)
   - The specific additions you propose to append to its Context field
   - Why each addition is relevant to that plan

4. **Ask for confirmation via `AskUserQuestion`:**

```
AskUserQuestion:
  question: "These learnings from implementation are relevant to future plans. Approve the updates?"
  header: "Menu context"
  options:
    - label: "Approve all"
      description: "Add all proposed context to the future plans"
    - label: "Edit first"
      description: "I want to adjust what gets added"
    - label: "Skip"
      description: "Don't update future plans"
```

5. **Handle the response:**
   - **"Approve all"** — append the proposed additions to each plan's Context field in the menu file using `Edit`.
   - **"Edit first"** — let the user specify what to change, adjust, re-present, and re-ask.
   - **"Skip"** — proceed without updating.

6. **Announce next plan.** Tell the user which plan is next and give them the command to continue when ready. Print exactly:

   ```
   Plan {{N}} ({{plan title}}) is up next.
   When you're ready, clear your context and run:
   /menu continue ~/.claude/plans/<menu-file>.md
   ```

   Then STOP responding — do not add further commentary or ask what the user wants to do.

7. Mark Phase 6b as `completed`.

### Phase 7: Deferred Design Decisions

**If no deferred design decisions were recorded during Phase 4:** skip this phase entirely.

**If design decisions were deferred:**

1. Present the full list of deferred decisions to the user:
   - Finding number (from the food-critic review)
   - What the food-critic flagged
   - What the "fix" would have been
   - Why it was classified as a design decision (not a bug fix)

2. Use `AskUserQuestion`:

```
AskUserQuestion:
  question: "These design decisions came up during cooking. Want to route them through order to decide how to handle them?"
  header: "Deferred design decisions"
  options:
    - label: "Route to order"
      description: "Start a fresh order to figure out the right approach for these"
    - label: "Skip for now"
      description: "I'll handle these separately later"
```

3. **"Route to order"** — invoke `oven:order`. The deferred decisions become the task prompt — order will orient, classify, interview, and route as usual.
4. **"Skip for now"** — print the list of deferred decisions so the user has a record, then done.

## When to Stop and Ask for Help

**STOP executing immediately when:**
- You're stuck on a task and can't make progress
- Multiple tasks failing in sequence (plan might be wrong)
- Food-critic flags critical issues
- You don't understand something in the plan

**Ask for clarification rather than guessing.**

## Red Flags — STOP

See "Universal Red Flags" in CLAUDE.md for cross-skill red flags. Skill-specific flags below:

| Thought | Reality |
|---------|---------|
| "I'll skip the reviews, everything went smoothly" | Reviews catch what self-review misses. Never skip. |
| "I'll fix my own concerns before the food critic sees them" | Concerns go to review. Report, don't fix. |
| "I'll use a worktree for isolation" | Direct implementation doesn't need isolation. Direct commits are simpler. |
| "I'll reuse a previous agent instead of dispatching fresh" | One-shot agents only. Each food-critic dispatch gets full cumulative context. |
| "I'll push through this blocker" | Stop. Ask. Don't guess. |
| "I'll just remove this, it's the easiest fix" | If the plan specified the behavior, removing it is a design decision. Defer it. |
| "This fix changes the API but it's the right call" | Design decisions don't belong in cooking. Defer to order. |
| "Reviews can wait, let me start the next feature" | Reviews are part of cooking. Not optional. |

## Key Principles

- **Direct implementation** — main agent reads code and implements each task
- **Cumulative context** — each food-critic dispatch gets prior findings + fixes + current diff
- **Direct commits** — commit directly to the feature branch after each task
- **Self-review without self-fix** — preserves honest assessment for reviewers
- **Food-critic review at the end** — comprehensive check against plan and self-review concerns
- **Single plating agent** — autonomous scope/review/apply/commit
- **Revert over fix for plating errors** — plating is cosmetic, reverting is always safe
- **Follow plan exactly** — don't interpret, don't improvise
- **Bug fixes only** — cooking fixes incorrect implementations, not inconvenient designs. Design decisions defer to order.
- **Stop when blocked** — ask, don't guess

## Integration

**Required workflow skills:**
- **oven:recipe** — Creates the plan this skill executes
- **oven:plating** — Single plating agent handles polish autonomously
- **oven:mise-en-place** — Main agent follows mise-en-place discipline per task
- **oven:proof** — Verify work before claiming done. Run it, confirm output, then report status.

**Related skills:**
- **oven:taste-response-guidelines** — Behavioral discipline for processing human/external review feedback on cooking output (not for Phase 4 food-critic processing)

**Supporting files:**
- **`food-critic-prompt.md`** — Food-critic review agent prompt template

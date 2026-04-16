---
name: order
description: "Use for ANY user prompt that involves doing something in a codebase — building, fixing, exploring, understanding, changing, adding, removing, refactoring, debugging, or any other action. This is the universal entry point for all task prompts; when in doubt, use this skill."
---

# Taking the Order

## Overview

Order is the front door for any action prompt. It orients in the codebase, interprets the user's request, classifies the work, and routes to the right skill with a clean, sealed handoff. The user always sees how their request was understood before anything moves forward.

**Core principle:** The user's intent must survive the translation from casual request to structured handoff. Every interpretation, assumption, and routing decision is shown to the user before anything moves forward. If the user wouldn't recognize their request in the handoff, the order failed.

**Announce at start:** "Let me take your order." Then announce each phase transition as you enter it — the user should always know what step you're on and what comes next. Use short, clear announcements like:
- "Orienting in the codebase..."
- "This looks like a [classification] — I'll structure the interview that way."
- "Starting the interview — scope first."
- "All parts confirmed. Here's the summary for your approval."
- "Routing to [skill]..." (immediately before invoking the skill)

<HARD-GATE>
Order is pure intake. It produces a sealed handoff for another skill to execute. Do NOT invoke implementation skills, write code, or take implementation actions — with one exception: **simple/quick** requests (no ambiguity, <3 files, clear starting point) may be executed directly by order, but ONLY after completing the full interview flow (orientation → classification → interview → confirmed summary) AND the user explicitly opts into direct execution over the full prep flow. The interview is never skipped. The user's choice is never assumed.
</HARD-GATE>

## When to Use

Any user prompt that calls for action or understanding:
- Building, adding, changing, or implementing something
- Reporting a bug, error, or unexpected behavior
- Asking how a system works or wanting to explore architecture
- Resuming a menu item from a previous session

**The only things order does NOT catch:**
- Simple factual questions that don't need codebase context ("what's a command pattern?")
- Conversation that isn't a task (greetings, feedback, meta-discussion)

## Main Agent Context Budget

Order is a lightweight intake skill. The main agent reads just enough of the codebase to orient — file names, class declarations, folder structure. Deep exploration is prep's job.

**What the main agent builds during intake:**
- Area summary (which systems/areas are relevant)
- Vocabulary map (codebase terms mapped to user's language)
- Starting points (file paths and areas for the target skill)
- User's confirmed interpretation of their request
- Menu file contents (when resuming)

## The Process

<HARD-GATE>
Every request follows the same flow, no exceptions:

**Orient → Classify → Interview → Present → Route**

No step can be skipped. No route bypasses the interview. No handoff happens without a confirmed summary. If a reclassification occurs at any point, loop back to the classification step and re-present in the correct format.
</HARD-GATE>

```
Step 1: Intake, Orient & Classify
       1a: Orient (Glob, Grep, Read — ~5 tool calls)
       1b: Classify (bug, exploration, mixed, simple, or implementation)
       ↓
Step 2: Clarification Interview (ALWAYS — no exceptions)
       Phase A: Scope (what's in, what's out — confirm first, it shapes everything)
       Phase B: Per-part interview (one at a time)
       Phase C: Confirmed summary (format matches classification)
       ↓
       User reclassifies? → loop back to Step 1b, re-classify, redo Phase C
       ↓
Step 3: Route (sealed handoff)
       ├─ Bug/failure ───→ smoke-check
       ├─ Exploration ───→ shop
       ├─ Mixed intent ──→ shop first, then re-enter for implementation
       ├─ Simple/quick ──→ order executes directly (post-interview)
       └─ Implementation → continue to Step 4
       ↓
Step 4: Decomposition Check (implementation only)
       ├─ single plan → Step 5
       └─ multi plan → Decompose → Menu Creation → Menu Confirmation → Step 5 (Plan 1)
       ↓
Step 5: Handoff to prep
```

### Step 1: Intake, Orient & Classify

**Purpose:** Get just enough codebase orientation to understand the user's request, then classify what type of work this is. This is NOT deep exploration — that's the target skill's job.

**Menu Resume:** If the user referenced a menu file (directly, via `/menu`, or with a message like `continue <path>`):
1. Read the menu file from `~/.claude/plans/`
2. Find the next plan to work on:
   - First check for any plan with status `in-progress` (resume a crashed/interrupted session)
   - If none, find the next `pending` plan (respect dependency order, then list order)
3. If the plan is `pending`, mark it as `in-progress` in the menu file (use `Edit` tool). If already `in-progress`, leave it as-is and note you're resuming.
4. Announce: "Picking up Plan N: [name] — [goal]"
5. **Confirm stored context against current state.** Present the plan's Context and Scope fields to the user and explicitly ask:
   - Does this context still match reality? Previous plans may have changed file structures, renamed systems, or shifted boundaries.
   - Are the stored details (file paths, system descriptions, dependencies) still accurate?
   - Have any decisions changed since the menu was created?
   If the user flags stale context, update the menu file before proceeding. If significant exploration is needed to verify, the orientation step below will handle it — but surface the stored assumptions first so the user can correct obvious drift.
6. Use the plan's goal and confirmed context as the feature request — proceed to the orientation step below, then classify in Step 1b (this will be "implementation" for menu plans). The full flow applies: orient → classify → interview → present → route.

**Fresh request (normal flow):**

1. Acknowledge the user's request
2. Note any starting points the user provided (file paths, module names, codebase areas). If they didn't provide any, that's fine — you'll find them.

**Orientation:** Use `Glob`, `Grep`, and `Read` to quickly orient in the codebase. The goal is vocabulary and area identification, not deep understanding.

- `Glob` for relevant file patterns (e.g., `**/*Inventory*.cs`, `**/UI/**`)
- `Grep` for key terms the user mentioned (class names, system names, feature keywords)
- Read 1-2 file headers or class declarations if needed for vocabulary (just the first ~30 lines, not full files)

**Keep orientation under ~5 tool calls.** This is intake, not exploration.

**If orientation finds nothing** (searches return no relevant matches), tell the user and ask:
```
AskUserQuestion:
  question: "I couldn't find anything matching your request in the codebase. Can you point me in the right direction?"
  options:
    - label: "Here's a starting point"
      description: "I'll give you a file path or area to look at"
    - label: "This is new — nothing exists yet"
      description: "There's no existing code for this, we're building from scratch"
```

If the user provides a starting point, run a few more targeted searches from there. If it's net-new work, proceed to the interview with no vocabulary map — note this gap so prep knows to explore broadly.

**What orientation produces:**
- **Area summary** — which systems/areas are relevant (names, not code). 2-5 bullet points.
- **Vocabulary map** — key terms and concepts the user used, mapped to actual codebase names. Helps interpret ambiguous requests.
- **Starting points** — specific file paths and areas the target skill should explore in depth.

**What orientation does NOT produce:**
- Full system maps, flow diagrams, or file tables — that's the target skill's job
- Design questions or architectural analysis — that's prep's job

**Prior context awareness:** If the conversation already contains exploration output (e.g., from a `shop` session with flow diagrams, file tables, dependency maps), leverage that context rather than re-exploring the same files. Do a quick scan to fill gaps relevant to the new request, but don't duplicate work already done.

#### 1b: Classify

After orientation, make a **committed classification** of the request. This determines the interview's scope question framing and the Phase C summary format. It may change later if the user reclassifies or the interview reveals a mismatch, but there is always a clear current classification driving the process.

| Classification | Signals | Destination |
|----------------|---------|-------------|
| **Bug/failure** | "fix", "broken", "error", "crash", "not working", stack traces, behavior that *should* work but doesn't | smoke-check |
| **Exploration** | "how does X work", "explain", "understand", "map", "architecture", "what connects to", "bird's eye" | shop |
| **Mixed** | Both exploration AND implementation signals — "understand X and then change Y" | shop first, then re-enter for implementation |
| **Simple** | No ambiguity, <3 files, clear starting point from user | order executes directly (after user confirms — see Step 3) |
| **Implementation** | "add", "build", "implement", "create", "change", feature descriptions, behavioral modifications | prep |

**When ambiguous:** default to asking the user, not guessing. Use `AskUserQuestion` with the candidate classifications as options.

**Announce the classification** to the user before proceeding to Step 2: "This looks like a [classification] — I'll structure the interview that way."

The classification can change later if the interview reveals a mismatch (see Phase C reclassification loop).

### Step 2: Clarification Interview

<HARD-GATE>
The interview runs on EVERY request — no exceptions. Bug reports, exploration questions, simple fixes, and complex features all go through the same process. The interview is how order confirms understanding. Skipping it means skipping the skill's core purpose.
</HARD-GATE>

<HARD-GATE>
Every question in the interview — Phase A scope, Phase B per-part, and Phase C final confirmation — MUST use the `AskUserQuestion` TOOL with structured options. Not a plain text question in chat. Not a markdown question with bullet points. The actual `AskUserQuestion` tool call. Plain text questions remove the clickable options that make the interview efficient and violate the skill's contract.

**Presentation vs. confirmation are always two separate steps.** Present context, interpretations, scope details, and summaries as regular chat text FIRST. Then call `AskUserQuestion` with a SHORT confirmation prompt — just the question, no context repeated. The question field is never a vehicle for detailed content; the user already read it above. Cramming context into the question field makes the popup unreadable.
</HARD-GATE>

**Purpose:** Walk the user through your interpretation of their request — scope first, then each part one at a time. Only after everything is confirmed do you present the handoff summary for final approval.

**Why an interview, not a presentation:** Dumping everything at once asks the user to validate it all simultaneously. An interview catches misunderstandings one at a time before they compound. It also gives the user natural moments to add context they forgot to mention.

**Menu resume adaptation:** When resuming from a menu file, the user didn't "say" anything — they're resuming stored context. Throughout the interview, adapt the format: instead of "You said X," use "The plan says X" or "Last session captured X." The goal is the same — confirm the interpretation is still correct — but the framing acknowledges that context may be stale.

#### Phase A: Scope

**Present scope first** — it shapes everything that follows. If the user expands or narrows scope, it changes which parts need to be interviewed and how they're interpreted.

Based on your classification from Step 1b, present the scope boundary **as regular chat text**:
- **What's in:** what this request covers (systems, behaviors, areas)
- **What's out:** what this request does NOT cover (adjacent systems, future work, out-of-scope concerns)

Then ask a short confirmation via `AskUserQuestion`. The question field is ONLY the prompt — the scope details were already shown as text above.

```
AskUserQuestion:
  question: "Does this scope look right?"
  options:
    - label: "That's right"
      description: "Move on to the details"
    - label: "Wider — I also want..."
      description: "I'll tell you what else is in scope"
    - label: "Narrower — drop some of that"
      description: "I'll tell you what to cut"
    - label: "Wrong classification"
      description: "This isn't a [classification] — let me clarify"
```

**Handling each response:**
- **"That's right"** — lock in scope, proceed to Phase B.
- **"Wider"** — incorporate the user's additions. If the expansion changes the classification (e.g., what was a simple fix now spans multiple systems → implementation), announce: "That changes this from a [old] to a [new]." Update the classification, re-present scope, re-ask.
- **"Narrower"** — remove the specified items. Re-present scope, re-ask.
- **"Wrong classification"** — let the user explain. Re-classify per Step 1b's table. Announce the new classification. Re-present scope in the new framing, re-ask.

#### Phase B: Per-Part Interview — One Question at a Time

Decompose the user's request (within the confirmed scope) into distinct parts. Each part is something the user said or implied that needs its own interpretation. For example, "add undo to the editor and make it feel snappy" has two parts: the undo feature and the responsiveness requirement.

For simple requests (bug reports, exploration questions, quick fixes), this may be a single part. That's fine — a one-part interview is still an interview.

For each part, prepare:
- **You said:** quote or closely paraphrase the specific thing the user said
- **I understood:** what you think they meant, grounded in codebase vocabulary from orientation (use system/class names)
- **Assumptions:** anything you're inferring that the user didn't explicitly say
- **Player experience** (if user-facing): what changes from the player's perspective — what they see, feel, or interact with differently. Always include this for anything that affects the game experience, UI, or player-visible behavior. For purely internal/tooling changes, omit it.

Walk through each part sequentially. Each part is a **two-step** process — output text first, then ask a short confirmation via `AskUserQuestion`. Do NOT combine them into one step.

**Step 1 — Present the interpretation as regular chat text:**

> **You said:** "add undo to the editor"
>
> **I understood:** Implement undo/redo for `LevelEditor` edit actions, using a command stack pattern that intercepts `EditAction` before it reaches `StateManager`
>
> **Assumptions:**
> 1. Redo is included (undo without redo is incomplete)
> 2. Only `LevelEditor` actions, not `AssetEditor`
>
> **Player experience:** Pressing Ctrl+Z instantly reverts the last edit action. A brief visual indicator confirms the undo.

**Step 2 — Ask a short confirmation via `AskUserQuestion`:**

The question field is ONLY the confirmation prompt — do NOT put the interpretation, context, or any detailed text in the question. All that context was already shown in Step 1.

```
AskUserQuestion:
  question: "Does this match what you meant?"
  options:
    - label: "That's right"
      description: "Move on to the next part"
    - label: "Close, but..."
      description: "I'll clarify what's different"
    - label: "No, that's not what I meant"
      description: "Let me re-explain this part"
    - label: "I also want..."
      description: "I'll add something I forgot to mention"
    - label: "I have a question about the systems"
      description: "I want to understand the codebase before confirming"
```

**Handling each response:**
- **"That's right"** — lock in this interpretation, move to the next part.
- **"Close, but..."** — incorporate the user's feedback, re-present this part with the update, and re-ask. If the change affects a part you already confirmed, flag it: "This changes my understanding of [earlier part] too — let me re-check that one after." If it changes scope, loop back to Phase A.
- **"No, that's not what I meant"** — reset this part's interpretation entirely. Let the user explain, re-interpret, re-ask.
- **"I also want..."** — the user is adding a new requirement. If it's within the confirmed scope, add it as a new part at the end of the queue. If it's outside scope, loop back to Phase A to expand scope first. Acknowledge which case applies and continue.
- **"I have a question about the systems"** — answer using the vocabulary map and area summary from orientation. If the user needs deeper understanding, run a few more `Glob`/`Grep`/`Read` calls or dispatch a follow-up Explore agent (`model: sonnet`) for the specific area. Then re-present this part (it may need updating) and re-ask.

**Cascading changes:** If the user's correction to one part invalidates or changes a part you already confirmed, loop back to re-confirm the affected part. Don't silently update it — show the user what changed and why.

**Batching related parts:** If two parts are tightly coupled (e.g., "add a button" and "style the button"), you may present them together as a single interview question. Use judgment — batch when splitting would feel artificial, but don't cram unrelated concerns together.

#### Phase C: Confirmed Summary

<HARD-GATE>
Every route requires a confirmed summary before routing. The summary must be presented as a visible artifact and the user must approve it via `AskUserQuestion`. No handoff happens without this confirmation — not for bugs, not for exploration, not for simple fixes. No exceptions.
</HARD-GATE>

After all parts are confirmed, assemble a summary of the confirmed understanding using the format that matches the classification from Step 1b.

**For implementation requests (→ prep):**

Present the assembled prep prompt as a visible, labeled section (e.g., "## Prep Prompt" or a fenced block). The user is approving THIS text — if they can't see the exact prompt that prep will receive, the artifact is incomplete.

Write the actual prompt that prep will receive. This is the interpreted goal in precise language — not the user's raw words, but a clear directive that incorporates:
- All confirmed interpretations from the interview
- Codebase vocabulary from orientation
- Scope boundary from Phase A
- Starting points and area summary from orientation
- Specific questions prep should answer during exploration
- **Player experience framing** — the confirmed player experience descriptions from each interview question. This seeds prep's design interview with UX context from the start.

**Letter each distinct directive or question** (A, B, C...) so the user can reference them (e.g., "drop C" or "reword B").

It should read as a clear, standalone task description that someone unfamiliar with the conversation could execute.

**For bug/failure requests (→ smoke-check):**

Present a **problem brief**:

| Field | Content |
|-------|---------|
| **Problem** | Confirmed interpretation of what's broken |
| **Expected behavior** | What should happen instead |
| **Starting points** | File paths and areas from orientation |
| **Assumptions** | Any remaining assumptions confirmed during interview |
| **Player experience** | What the player sees when the bug occurs (if user-facing) |

**For exploration requests (→ shop):**

Present an **exploration brief**:

| Field | Content |
|-------|---------|
| **Question** | Confirmed interpretation of what the user wants to understand |
| **Relevant areas** | Systems/modules from orientation |
| **Starting points** | File paths |
| **Suggested depth** | Just this module / include neighbors / full chain |
| **Assumptions** | Any remaining assumptions confirmed during interview |

**For mixed intent (→ shop first, then implementation):**

Present both artifacts:
1. The **exploration brief** (same format as above, including Assumptions) — this is the sealed handoff for shop
2. The **implementation goal** — a summary of what will be built after exploration completes, including any confirmed assumptions and player experience framing

Make it clear: shop runs first with the exploration brief. After shop completes, the user starts a new conversation that re-enters order with the implementation goal. That second pass is a completely fresh flow — shop output feeds orientation via prior context awareness, but classification, interview, and summary all run from scratch.

**For simple requests (→ order executes directly):**

Present a summary of: what you'll change, which files you'll touch, and what the expected result is.

---

**Final confirmation (all routes, no exceptions):**

Use `AskUserQuestion`:
```
AskUserQuestion:
  question: "Here's the confirmed summary. Is this correct?"
  header: "Your order"
  options:
    - label: "Yes — go"
      description: "That's right, proceed"
    - label: "No — needs changes"
      description: "I'll point out what's off"
    - label: "Wrong classification"
      description: "This should be a different type of task"
```

- **"Yes"** — proceed to Step 3 (Route).
- **"No"** — the user points out what's wrong. Update, re-present, re-ask. If the change is substantial enough to invalidate an earlier interview answer, loop back to Phase B for the affected parts. If it changes scope, loop back to Phase A.
- **"Wrong classification"** — the user is reclassifying the request. Let them explain, re-classify per Step 1b's table, announce the new classification, and **re-present Phase C in the correct format** for the new classification. The Phase A scope and Phase B confirmations carry over unless the reclassification invalidates them — if it does, loop back to the affected phase.

### Step 3: Route

<HARD-GATE>
Step 3 only executes after the user has confirmed the Phase C summary. Do not route without confirmation. The confirmed summary IS the sealed handoff — the target skill works from this artifact, not from earlier conversation context.
</HARD-GATE>

**Purpose:** Execute the handoff to the target skill based on the confirmed classification.

**Route: Bug/failure → smoke-check**

Invoke `oven:smoke-check`, passing the confirmed problem brief as a sealed handoff.

**Route: Exploration → shop**

Invoke `oven:shop`, passing the confirmed exploration brief as a sealed handoff.

**Route: Mixed intent → shop first, then implementation**

Invoke `oven:shop`, passing the exploration brief from Phase C as a sealed handoff. The implementation goal from Phase C is not handed to shop — it's what the user brings back when they re-enter order after shop completes (see Phase C's mixed intent format for the full mechanics).

If the user indicated during the interview that they already understand the system (e.g., scope narrowed to implementation only in Phase A), the classification should already be "implementation" not "mixed" — re-classify if this hasn't happened.

**Route: Simple → order executes directly (requires user opt-in)**

<HARD-GATE>
Order NEVER executes a simple request without explicit user approval. The Phase C summary tells the user this was classified as simple, and the routing confirmation gives them the choice to accept direct execution or escalate to the full prep flow. If the user doesn't explicitly choose direct execution, route to prep.
</HARD-GATE>

All three criteria must still be met: no ambiguity, <3 files, clear starting point. If any criterion isn't met after the interview, re-classify as implementation and loop back to Phase C to present a prep prompt instead.

**Phase C for simple requests** already presents what you'll change, which files, and the expected result. The final confirmation for simple requests uses a different set of options than other routes:

```
AskUserQuestion:
  question: "I think this is small enough to handle directly — want me to just do it, or would you prefer the full prep flow?"
  header: "Your order"
  options:
    - label: "Just do it"
      description: "I'll make the changes right now"
    - label: "Use prep instead"
      description: "Route through the full prep→recipe→cooking flow"
    - label: "Needs changes"
      description: "The summary isn't right — I'll point out what's off"
```

- **"Just do it"** — proceed with direct execution below.
- **"Use prep instead"** — re-classify as implementation. Re-present Phase C as a prep prompt. Route to prep via Step 4/5.
- **"Needs changes"** — same as other routes: update, re-present, re-ask.

**Execution steps (only after user chose "Just do it"):**
1. Announce: "Handling this directly."
2. Ask the user using `AskUserQuestion`:

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

3. **Respect the answer.** If the user picks "Stay on {{current branch}}", proceed — even if it's main.
4. If the user picks "New branch", suggest a name and create it before making changes.
5. Make the changes using `Edit`/`Write` tools
6. Verify the result — read the changed files back and confirm the change is correct
7. Commit the work with a descriptive message
8. Report what was done

**Route: Implementation → prep**

Announce: "Routing to prep." Then call `EnterPlanMode` — the entire order→prep→recipe workflow stays in plan mode until the final plan is approved. Proceed to Step 4.

### Step 4: Decomposition Check

After routing to implementation, evaluate whether this is one plan or many.

**Assessment criteria — look for:**
- Multiple distinct features or behavioral changes that could each be built and tested independently
- Independent subsystems with their own boundaries (not just different files in one system)
- Requests that combine unrelated work items ("add X and also refactor Y")
- Multiple bullet points or listed items in the request that describe separate deliverables

**Sizing guidance:** Each plan should target **10-20 file changes** with **1-2 clear overarching goals**. Don't split into plans under 5 files — merge those into a related group. A single large goal that can't be decomposed further is fine as one big plan.

**If single-scope:** Skip to Step 5.

**If multi-scope — decompose into a menu:**

**4a: Present the decomposition using the Presenting Suggestions format.**

For each proposed sub-plan, provide a detailed breakdown — not just a name and one-liner:
- **Name** — short, descriptive
- **Goal** — one sentence, standalone and testable
- **Scope** — what systems, files, and concerns are in this plan's boundary. Be specific: "IAP purchase flow from button tap through receipt validation" not "IAP stuff"
- **Estimated scale** — rough file count and areas touched
- **Depends on** — which other sub-plans (if any) must come first, and why
- **Boundary** — what's explicitly NOT in scope for this plan

Present the full breakdown as regular text, then use `AskUserQuestion` with concise labels referencing the breakdown above.

**4b: Validate sizing.**

Each menu item represents a full prep→recipe→cooking cycle. That overhead is only justified for substantial work:
- Target **10-20 file changes** per plan with **1-2 clear overarching goals**
- If a proposed sub-plan is under 5 files or has a single trivial goal ("add a field", "rename a method"), merge it into the plan it's closest to
- If a single goal is genuinely large and can't be decomposed further, it's fine as one big plan — don't force artificial splits
- When in doubt, err toward **fewer, larger plans** over many small ones

**4c: User approval of the decomposition.**

Use `AskUserQuestion`:
- "Approve decomposition" — proceed with writing the menu
- "Adjust" — user provides feedback on the breakdown
- "Keep as one plan" — proceed without decomposing (flag the risk of a larger, harder-to-review plan)

**Iterate until the user approves.** Adjust sub-plan boundaries, merge/split plans, reorder as the user directs. Re-present the full breakdown and re-ask after each adjustment.

**4d: Write the menu file** (see Menu File Format below).
- Path: `~/.claude/plans/<project-name>-menu.md` (must end with `-menu.md`)
- Mark Plan 1 as `in-progress`, all others as `pending`
- **Every plan gets a Context field** — including Plan 1. Capture all relevant conversation decisions and orientation findings per plan.
- **Context must include the confirmed interpretations from Step 2** — for each plan, show which parts of the user's original request map to this plan's scope and how they were interpreted (including any corrections the user made during the interview). A future session reading this context should understand not just *what* to build but *why* the user wanted it and *how* the scope was decided.

**4e: Present the menu to the user for confirmation.**

Before continuing, show the user the full menu with:
- Each plan's name, goal, scope, and context
- **What was captured** from the conversation — call out specific decisions, constraints, and design choices that were embedded in the context fields
- **What was omitted or deferred** — if you left anything out of the menu that was discussed, flag it and explain why (out of scope, superseded by a later decision, etc.)
- Dependency order — confirm the user agrees with the proposed sequencing
- Whether Plan 1 is the right starting point
- Any cross-plan concerns (shared interfaces, data formats, ordering constraints) that need to stay consistent across plans

Use `AskUserQuestion`:
- "Looks good — continue with Plan 1" — proceed to Step 5
- "Needs changes" — user provides corrections to context, ordering, or scope

**Iterate until the user confirms the menu is accurate.** Context loss is the primary failure mode of menus — this checkpoint exists to catch it.

#### Menu File Format

When decomposing a multi-scope request, write a menu file to persist the sub-plan queue across sessions.

<HARD-GATE>
**Path:** `~/.claude/plans/<project-name>-menu.md` — must end with `-menu.md` (see "Menu File Naming" in CLAUDE.md).
</HARD-GATE>

**Template:**

```markdown
---
name: <project-name>
description: "<one-line browsable description of the overall project>"
date: <today's date>
status: active
---

# Menu: <Project Name>

**Goal:** <overall goal in 1-2 sentences>

**Original request:** <summary of what the user asked for>

## Plans

### 1. <Plan Name>
- **Goal:** <one sentence — standalone, testable>
- **Context:** <same rules as below — every plan gets context, including Plan 1. If the session crashes or the user resumes later, this is all they have.>
- **Scope:** <systems, files, and concerns in this plan's boundary>
- **Status:** in-progress
- **Plan file:** not yet created
- **Branch:** not yet created
- **Depends on:** none

### 2. <Plan Name>
- **Goal:** <one sentence — standalone, testable>
- **Context:** <capture everything a future session needs to start this plan without re-asking the user. Include: the user's original description, design decisions made during conversation, rejected alternatives and why, constraints or requirements discussed, the confirmed interpretations from Step 2 that map to this plan's scope, and any relevant orientation findings (area summary, vocabulary, starting points). When ANY upfront conversation happened before the menu was created, this field is MANDATORY — goals alone lose nuance. Omit ONLY if the plan was created with zero prior discussion and the goal is fully self-explanatory.>
- **Scope:** <systems, files, and concerns in this plan's boundary>
- **Status:** pending
- **Plan file:** not yet created
- **Branch:** not yet created
- **Depends on:** Plan 1
```

**Plan statuses:** `pending` | `in-progress` | `done` | `skipped`

**Menu status (frontmatter):** `active` | `complete` | `abandoned`

**The menu file is updated by multiple skills:**
- **Order** — creates it (on decompose), marks plans `in-progress` (on resume from menu)
- **Prep** — appends design findings to future plans' Context fields (Phase 9)
- **Recipe** — records the plan file path after approval
- **Cooking** — marks plans `done`, records the branch name, appends implementation learnings to future plans' Context fields (Phase 6b)

**Dependencies are informational, not enforced.** If the user picks a plan whose dependency isn't done, show a heads-up but don't block.

### Step 5: Handoff to Prep

<HARD-GATE>
Every handoff from order is a sealed artifact — the target skill works from the handoff, not from earlier conversation context. This is the context boundary. See "Sealed Handoffs" in CLAUDE.md.
</HARD-GATE>

**Single-scope flow:**
Deliver the confirmed prep prompt from Step 2 (Phase C), along with:
- Scope boundary — what's in and what's out from Phase A
- Player experience framing — descriptions gathered during the interview
- Starting points and area summary from orientation
- Specific questions for prep to answer

**Multi-scope flow (after menu creation):**
Deliver the confirmed prep prompt scoped to **Plan 1 only**, along with:
- Scope boundary — what's in and what's out, scoped to Plan 1
- Player experience framing relevant to Plan 1
- Starting points and area summary scoped to Plan 1's relevant areas
- Specific questions for prep to answer, scoped to Plan 1
- The menu file path

**What prep receives:**
Prep always starts with a well-defined, single-scope prompt. It never deals with menus, decomposition, or scope routing — that's order's job. Prep's input is:
- The confirmed prep prompt (lettered directives from Phase C)
- Scope boundary — what's in and what's out
- Player experience framing — descriptions gathered during the interview
- Starting points and area summary (where to start exploring)
- Specific questions for prep to answer
- Menu file path (optional — if part of a multi-plan menu, so recipe/cooking can update it)

<HARD-GATE>
After assembling the handoff, you MUST invoke `oven:prep` using the Skill tool immediately. Do not stop after presenting the summary or announcing the handoff — the skill invocation is the deliverable. If you say "routing to prep" but don't call the Skill tool, the handoff did not happen.
</HARD-GATE>

Invoke `oven:prep`, passing these as context.

## Red Flags — STOP

See "Universal Red Flags" in CLAUDE.md for cross-skill red flags. Skill-specific flags below:

| Thought | Reality |
|---------|---------|
| "The user's request is clear enough" | Show them the interpretation anyway. Assumptions kill intent. |
| "I don't need to walk through each part" | The interview IS the skill. Skip it and you've skipped the point. |
| "I can skip the scope question" | Scope comes first. It shapes every question after it. |
| "I'll present the summary without asking" | Every route requires a confirmed summary via AskUserQuestion. No exceptions. |
| "I can route directly, the user already confirmed the parts" | Parts ≠ summary. The assembled summary must be presented and approved. |
| "This is obviously one plan" | Check the criteria. Obvious is often wrong. |
| "I'll cram all these features into one plan" | Separate goals need separate plans. Decompose via menu. |
| "The context field doesn't need all that" | If a future session can't start this plan cold, the context failed. |
| "The user will remember what they said" | They won't. The menu is all they'll have. |
| "This is simple, I can skip the interview" | Orient → Classify → Interview → Present → Route. Every time. No shortcuts. |
| "I'll just ask in plain text" | Use the `AskUserQuestion` TOOL. Every interview question, every confirmation — tool call, not chat text. |
| "This is a bug, I don't need the full interview" | Same flow. A one-part interview is still an interview. |
| "Orientation already gave me enough" | Orientation gave you vocabulary. The user gives you intent. Confirm both. |
| "The user knows these systems" | Maybe they don't. Give them space to ask. |
| "This is a bug, I'll just fix it" | Route to smoke-check. You're the front door, not the mechanic. |
| "I said I'm routing to prep, so I'm done" | Saying it isn't doing it. You must invoke the Skill tool. The handoff isn't real until the skill runs. |
| "This is simple, I'll just handle it" | Simple still needs the user's explicit opt-in. Ask first. They may want the full flow. |
| "The user can tell what I'm doing" | Announce every phase transition. Silence breeds confusion. |
| "They just want to understand X, I can explain" | Route to shop. It has the exploration pipeline. |
| "They want to understand X and build Y, I'll go straight to prep" | Mixed intent. Shop first, then implementation. Understanding informs the build. |
| "Orientation says this is actually a bug, but the user said 'add'" | Re-classify. Your findings override keyword matching. Tell the user why. |

## Key Principles

- **Order is the universal front door** — every action prompt enters here. Order orients, classifies, interviews, presents, and routes.
- **The flow is mandatory** — Orient → Classify → Interview → Present → Route. No step can be skipped. No route bypasses any step. This applies equally to bugs, exploration, simple fixes, and complex features.
- **Scope first** — the scope question comes before per-part questions. Scope changes cascade to everything below.
- **Classification is committed** — after orientation, commit to a classification (bug, exploration, mixed, simple, implementation). It can change if the user reclassifies or the interview reveals a mismatch, but there's always a clear current classification driving the format.
- **The confirmed summary is the deliverable** — order produces a sealed artifact for each route. The interview builds it piece by piece; the summary assembles it; the user confirms it.
- **Sealed handoffs for every route** — the target skill receives only the confirmed summary, not the full conversation. What's not in the handoff doesn't exist downstream.
- **Intent preservation is the primary job** — if the user's intent doesn't survive the translation from request to handoff, everything downstream is wrong
- **Show your work** — the user must confirm scope, each part, and the final summary. Three layers of confirmation.
- **Give space for understanding** — the user may be prompting for systems they don't fully know. Let them ask questions and learn before confirming.
- **Keep orientation shallow** — enough to orient and classify, not a deep system dive. That's prep's job.
- **Reclassification loops back, not forward** — if the classification changes, re-present Phase C in the correct format. Don't force the old format onto the new classification.
- **Context is permanent, conversation is not** — anything not written into the menu's context fields is gone after the session ends
- **Fewer, larger plans** — menu overhead is expensive. Don't split what doesn't need splitting.
- **Decompose over-scoped requests** — but only when the goals are genuinely independent

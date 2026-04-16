---
name: prep
description: "Use after oven:order to deep-dive into the codebase, design the architecture, and produce a complete design ready for oven:recipe"
---

# Deep Planning

## Overview

Turn a scoped prompt into a thoroughly researched design through exploration, synthesized system mapping, and iterative clarification.

**Core principle:** Prep always receives a well-defined, single-scope prompt from `oven:order`. It never deals with intake, scope routing, or menu creation — that's order's job. The main agent drives the entire process: it spawns Explore agents for codebase deep-dives, synthesizes their reports into system maps, evaluates architectural approaches, and interviews the user to refine the design.

**Announce at start:** "I'm ready to start prepping — let me gather the ingredients."

<HARD-GATE>
Prep is never the entry point. If invoked without a scoped prompt from order (e.g., user calls `/prep` directly, or starts with a raw feature request), redirect to `oven:order`: "Let me take your order first so I know exactly what to explore."

This is not optional. Order handles intake, interpretation, routing, and produces the sealed handoff that prep works from.
</HARD-GATE>

## Context Boundary

Prep works exclusively from order's sealed handoff — not from earlier conversation context.

**What prep receives from order:**
- **Confirmed prep prompt** — the refined, confirmed task description with lettered directives (A, B, C...) translating the user's intent into precise language with codebase vocabulary
- **Scope boundary** — what's in and what's out, confirmed during order's Phase A
- **Player experience framing** — the confirmed player experience descriptions from order's interview questions, seeding prep's design work with UX context
- **Starting points and area summary** — file paths and relevant systems/areas from order's orientation
- **Specific questions for prep to answer** — questions order identified during intake that prep should resolve during exploration
- **Menu file path** (optional) — if this plan is part of a multi-plan menu

**What prep does NOT use:**
- Earlier conversation turns before the confirmed prep prompt was finalized
- Order's raw orientation notes (only what order incorporated into the handoff)
- The user's earlier drafts or corrections (only the final confirmed version)
- Order's internal classification reasoning or interview mechanics

The confirmed prep prompt is prep's ground truth. If it seems incomplete, that's a signal to explore deeper in Phase 1 — not to reach back into conversation history.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until the design is complete and the user has approved it. This applies regardless of perceived simplicity.
</HARD-GATE>

## No Silent Scope Decisions

<HARD-GATE>
Never decide to include, exclude, or defer features without asking the user. This is the most common prep failure mode — the agent discovers capabilities in a reference system or related codebase and silently decides which ones are "in scope" and which are "deferred to v2" or "out of scope." These are design decisions that belong to the user.

**What counts as a silent scope decision:**
- Deferring a feature to a later version without asking ("sub-pages deferred to v2")
- Excluding a capability found in a reference system without asking ("console panel is PT-internal")
- Deciding a feature isn't needed without asking ("Show/Hide is backend-internal only")
- Choosing between feature variants without asking ("we'll use X instead of Y")
- Marking anything as "out of scope" that wasn't already out of scope in order's handoff

**What to do instead:** Surface every discovered feature/capability as a design question during Phase 5. Present what it does, what including it would cost, and recommend include or defer — but let the user decide.

**If you catch yourself writing "deferred to v2", "excluded because", or "not needed for v1" without having asked the user** — STOP. That's a decision you're making for them. Turn it into a question.

**After presenting your design questions in Phase 5, disclose all decisions you made.** Before asking "Anything else on your mind?", list every feature or capability you encountered during exploration that you considered excluding, deferring, or handling differently than the reference implementation. Present them as: "I also found these capabilities in the existing system that I haven't asked about yet — do any of these matter for this feature?" This is the safety net. Even if you missed surfacing something as a proper design question, this disclosure step catches it.
</HARD-GATE>

## The Process

<HARD-GATE>
Every prep run follows the same flow, no exceptions:

**Explore --> Validate Scope --> Architecture --> Present --> Design Interview --> Compare --> Edge Cases --> Summary --> Menu Context Propagation --> Handoff**

No phase can be skipped. If a reclassification or loop-back occurs, the flow returns to the specified phase — it never jumps forward past an unvisited phase.
</HARD-GATE>

```
Phase 1: Explore & Synthesize
       |
Phase 2: Scope Validation
       |                                               ___
Phase 3: Architecture Analysis                          |
       |                                                |
Phase 4: Present System Map + Approach Selection        |
       |                                                |-- Loop-back zone
       |   "None of these work" --> back to Phase 3     |
       |                                                |
Phase 5: Design Interview                               |
       |                                                |
       |   "This changes the approach" --> back to Phase 3
       |                                               _|_
Phase 6: Before/After Comparison
       |
       |   "This approach doesn't fit" --> back to Phase 3 (decisions carry over)
       |
Phase 7: Edge Case Interview
       |
       |   Gaps found? --yes--> Targeted re-explore --> re-synthesize --> back to Phase 4
       |
       no
       |
Phase 8: Design Summary
       |
Phase 9: Menu Context Propagation (if menu with pending plans exists)
       |
Handoff to oven:recipe
```

## Progress Tracker

<HARD-GATE>
See "Progress Tracker Pattern" in CLAUDE.md for the standard rules.

**At the very start of prep, create exactly these 9 tasks — no more, no fewer.** Use the exact subjects below verbatim. Do NOT renumber, rename, merge, or add phases. The numbering matches the flow diagram and phase detail headings — "Phase 2" is Scope Validation, not "Phase 1.5".

```
TaskCreate: subject="Phase 1: Explore & Synthesize", description="Spawn Explore agents, collect reports, synthesize into 8 deliverables"
TaskCreate: subject="Phase 2: Scope Validation", description="Confirm exploration findings match order's scope boundary"
TaskCreate: subject="Phase 3: Architecture Analysis", description="Evaluate approaches based on synthesis and code patterns"
TaskCreate: subject="Phase 4: System Map + Approach", description="Present system map and approach options to user"
TaskCreate: subject="Phase 5: Design Interview", description="Refine design details with user, one question at a time"
TaskCreate: subject="Phase 6: Before/After Comparison", description="Present current vs proposed system side by side"
TaskCreate: subject="Phase 7: Edge Cases", description="Interview user on edge cases, one at a time"
TaskCreate: subject="Phase 8: Design Summary", description="Assemble design artifacts, present summary"
TaskCreate: subject="Phase 9: Menu Context Propagation", description="Propagate design findings to future menu plans, then handoff to oven:recipe"
```

**Rules:**
- **Create once, update always.** These 9 tasks are created at the start and never recreated. To track progress, use `TaskUpdate` on the existing task — do not call `TaskCreate` for a phase that already has a task.
- Mark each task `in_progress` when starting the phase, `completed` when done.
- If looping back (e.g., approach reclassification in Phase 5 --> re-enter Phase 3), mark the re-entered phase `in_progress` again so the user sees where you are.
- Every phase runs. No phase is skipped.
</HARD-GATE>

## Phase Transition Gates

<HARD-GATE>
Three explicit gates govern phase transitions. Each gate has a precondition that must be met before the next phase can begin.

| Gate | Between | Precondition |
|------|---------|-------------|
| **Scope Gate** | Phase 2 --> Phase 3 | User has confirmed scope via AskUserQuestion |
| **Approach Gate** | Phase 4 --> Phase 5 | User has selected an approach (or hybrid) from Phase 4 |
| **Comparison Gate** | Phase 6 --> Phase 7 | User has responded to the before/after comparison AskUserQuestion |

No gate can be bypassed. If a loop-back returns to an earlier phase, the downstream gates must be satisfied again before proceeding past them.
</HARD-GATE>

## Main Agent Context Budget

The main agent in prep reads Explore agent reports and may read targeted code sections for architecture analysis. It does NOT do broad file-by-file exploration — that's what Explore agents are for.

**What the main agent works with:**
- Confirmed prep prompt from oven:order (confirmed user intent with lettered directives)
- Scope boundary from oven:order (what's in, what's out)
- Player experience framing from oven:order (UX context for design decisions)
- Starting points and area summary from oven:order
- Specific questions from oven:order (questions to answer during exploration)
- Explore agent reports (raw findings from 2-4 agents)
- Synthesized deliverables (produced by main agent from explore reports)
- Architecture approaches table (produced by main agent)
- User's chosen approach
- Design question answers
- Before/After comparison (constructed from synthesis + decisions)
- Edge case resolutions

## Presenting Suggestions

Follow the **Presenting Options Format** in CLAUDE.md. Key additions for prep:

- Every suggestion needs: what it is (behavior first, code refs in parentheticals), specific pros, specific cons, and a recommendation signal
- Present the detailed breakdown as regular text BEFORE the `AskUserQuestion` popup
- Popup labels should be concise references to the breakdown above
- Vague labels like "use events" or "add a flag" are not acceptable — describe the solution fully

## Phase Details

### Phase 1: Explore & Synthesize (Internal — No User Output)

<HARD-GATE>
Phase 1 is internal synthesis only. Do NOT present the deliverables to the user during this phase. Each deliverable is presented in the phase where it's relevant:

| Deliverable | Presented in |
|-------------|-------------|
| Data/control flow diagram | Phase 4 (system map) |
| File responsibility table | Phase 4 (system map) |
| Dependency map | Phase 4 (system map) |
| Design questions | Phase 5 (design interview, one at a time) |
| Edge case candidates | Phase 7 (edge case interview, one at a time) |
| System primer | Phase 4 (leads the presentation) |
| Scope validation | Phase 2 (scope confirmation) |
| Player impact summary | Phase 4 (with system map), Phase 6 (before/after) |

Dumping all 8 deliverables in Phase 1 forces the user to read everything twice — once as a raw wall, once in context where it matters. Synthesize silently, present contextually.
</HARD-GATE>

The main agent drives exploration directly. Spawn **2-4 Explore agents** (`subagent_type: Explore`, `model: sonnet`), each with different starting points from order's handoff. Collect their reports and synthesize them into the eight deliverables below. Hold all deliverables internally — they are presented in later phases.

See "Agent Output Protocol" in CLAUDE.md for output rules on dispatched agents.

**Dispatching Explore agents:**
- Give each agent a different slice of the codebase to explore (e.g., one starts from the UI layer, another from the data layer, another from related systems)
- Each agent receives: the confirmed prep prompt, its assigned starting points, and a clear list of what to look for
- Include order's specific questions so agents can gather evidence to answer them
- Agents can be dispatched in parallel

**What Explore agents look for:**
- How the relevant systems currently work
- What patterns are used (MVVM layers, commands, state, views)
- What files would need to change
- What other systems depend on or feed into these
- Existing similar implementations to follow as reference

**What each Explore agent returns** (specify this in the agent prompt):
- Files found (paths and brief responsibility descriptions)
- Patterns observed (naming conventions, architectural style, data flow)
- Dependencies (what connects to what)
- Relevant code signatures and structures (not full file dumps — key interfaces, class shapes, method signatures)

**After all agents return,** synthesize their reports into the eight deliverables below. This is the main agent's job — compress the raw reports into a coherent system picture. Do not output the deliverables — hold them for later phases.

**The eight deliverables:**

**1. Data/control flow diagram (ASCII):**
```
UserInput --> ViewModel --> Command --> Handler --> State
                |                                   |
              View <-- Model <-- StateChanged <------+
```

**2. File responsibility table:**

| File | Responsibility | Touches |
|------|---------------|---------|
| `path/to/File.cs` | Handles X | Model, View |

**3. Dependency map:**
Which systems connect to which — shows blast radius of the proposed change.

**4. Design questions:**
Things the user needs to decide. Each question with options must follow the **Presenting Suggestions** format: concrete description of what each option actually does (behavior first, code references in parentheticals), specific pros, specific cons, and a recommendation with reasoning. Vague labels like "use events" or "add a flag" are not acceptable — describe the solution fully.

**5. Edge case candidates:**
Organized by category (see Phase 7 table). Include anything the explore agents flagged as potentially tricky.

**6. System primer:**
Plain-English explanations of how each relevant system works, aimed at someone unfamiliar with it. Not a file listing — a readable walkthrough of concepts, data flow, and key constraints. For each system:
- **What it is** — one sentence overview
- **How it works** — the core mechanics, data structures, and lifecycle. Explain like you're onboarding a teammate who's never touched this code
- **Key constraints for this feature** — what matters specifically for what we're about to build (e.g., "pools are generic and component types aren't known at compile time, which complicates serialization")
- **Entry points** — where you'd start reading if you wanted to understand it yourself (file paths)

For external libraries not yet in the project, include: what the library does, how it's typically integrated, and any constraints or requirements (e.g., source generators, attributes, type restrictions).

The primer is the deliverable that makes prep useful even when the user doesn't know the systems. The file table tells you *where* things are; the primer tells you *how they work*.

**7. Scope validation:**
Confirm that the exploration stayed within the scope defined by order's scope boundary. Flag if:
- Exploration found systems or dependencies outside the expected boundary
- The scope appears larger or smaller than what order described
- Exploration discovered that the scoped prompt missed something important

This is NOT the decomposition step (that's `oven:order`'s job). This is a sanity check that the exploration matched the expected scope.

**8. Player impact summary:**
Synthesize the player experience framing from order's handoff with what exploration actually found. This connects the UX intent to the technical reality:
- What the player currently sees/experiences in the relevant area
- How the proposed change would alter the player's experience (based on what exploration revealed about the systems involved)
- Any gaps between order's player experience framing and what the codebase actually supports
- UX constraints discovered during exploration (animation systems, state transitions, loading sequences, etc.)

### Phase 2: Scope Validation

<HARD-GATE>
Scope must be confirmed by the user before architecture analysis begins. Even when scope looks clean, present findings and get explicit confirmation — do not silently proceed.
</HARD-GATE>

After synthesizing the Explore agent reports, present the scope validation deliverable (#7 from Phase 1) to the user. Compare what exploration found against order's scope boundary.

**Always present scope findings:**

Show the user:
- **Order's scope boundary** — what was in and out per order's handoff
- **Exploration findings** — what systems and dependencies exploration actually found
- **Match assessment** — whether the findings align with, exceed, or fall short of the expected scope
- **Any surprises** — systems, dependencies, or complexity that wasn't anticipated

Use `AskUserQuestion`:
```
AskUserQuestion:
  question: "Here's how exploration maps to the scope from order. Does this look right?"
  options:
    - label: "Scope confirmed"
      description: "Exploration matches — proceed to architecture"
    - label: "Re-scope needed"
      description: "Go back to oven:order to adjust the prompt and file targets"
    - label: "Expand scope here"
      description: "Absorb the additional scope into this plan (only if the expansion is small)"
```

**Handling each response:**
- **"Scope confirmed"** — lock in scope, proceed to Phase 3. The Scope Gate is satisfied.
- **"Re-scope needed"** — redirect to `oven:order` with findings. Prep pauses.
- **"Expand scope here"** — absorb the expansion, note the updated boundary, proceed to Phase 3. Only offer this option if the expansion is genuinely small. If it's substantial, recommend re-scoping through order.

### Phase 3: Architecture Analysis (Internal — No User Output)

<HARD-GATE>
Phase 3 is internal analysis only. Do NOT present the approaches table, explanations, or any Phase 3 output to the user during this phase. All presentation happens in Phase 4, where the user gets system context first, then approaches, then the question — in one coherent flow.
</HARD-GATE>

The main agent performs architecture analysis using the synthesized deliverables from Phase 1. Read targeted code sections as needed to verify patterns — use `Read` on specific files from the file table, don't do broad exploration (that's what Phase 1 was for).

**What to do:**
1. Review the synthesized deliverables (flow diagram, file table, dependency map, design questions, edge case candidates, system primer, scope validation, player impact summary)
2. Read key source files from the file table to verify architectural patterns (focus on interfaces, base classes, and composition roots — not full implementations)
3. Identify current architectural patterns in use across the relevant systems
4. Evaluate problem shape — what patterns genuinely fit this feature?
5. Produce a ranked approaches table (2-4 rows) — hold it for Phase 4

**Architectural preferences:**
- **Preferred when the problem fits:** MVVM (ViewModels own presentation logic, Views are dumb, Models are plain data), Pure DI (constructor injection, composition roots, no service locators)
- **But recognizes when other patterns are better:** command pattern, state machines, observer/events, procedural code, domain-specific patterns
- **Rule:** Evaluate problem shape first, then recommend. MVVM/DI get preference when multiple patterns could work equally well, but are never forced where they don't belong
- **Design for isolation:** Favor smaller units with clear boundaries and well-defined interfaces. Each piece should be independently testable. Smaller, focused files help Claude reason more effectively during implementation — prefer splitting responsibilities across files over packing multiple concerns into one.
- **DRY (Don't Repeat Yourself):** Watch for duplication across the proposed design. If two components would share the same logic, factor it out into a shared utility or base class. Flag existing duplication in the codebase that the new design could consolidate. Duplication in architecture leads to duplication in code.

**Approaches table format** (presented in Phase 4, not here):

| # | Approach | Summary | Matches Current | Moves Toward Preferred | Scope | Risk | Player Experience | Rec |
|---|----------|---------|-----------------|----------------------|-------|------|-------------------|-----|
| 1 | Follow existing patterns | ... | High | Low | Small | Low | ... | |
| 2 | Best-fit architecture | ... | Varies | Varies | Med | Med | ... | * |
| N | Hybrid | ... | Med | Med | Med | Low | ... | |

The **Player Experience** column summarizes how each approach affects the player's experience — responsiveness, visual feedback, transitions, or other UX-relevant tradeoffs. Omit this column only for purely internal/tooling changes with no player-facing impact.

Each row gets 2-3 sentences below the table explaining: what changes, why it's ranked there, and tradeoffs.

**Constraints:**
- Read-only — does not modify files
- Does not make design decisions — presents options for the user to choose
- Always includes at least one "match existing patterns" approach and at least one "best-fit" approach
- 2-4 rows max (no analysis paralysis)
- Starred recommendation (`*` in the Rec column) with reasoning

### Phase 4: Present System Map + Approach Selection (Main Agent)

Phase 4 is the single presentation point — system context and approach selection in one coherent flow. The user should never see approaches without the system context that makes them meaningful.

1. **Lead with the system primer** — present the plain-English explanations of how each relevant system works. This is the "here's what these systems actually do" context that makes the technical map meaningful, especially when the user is unfamiliar with the systems involved.
2. **Then present the system map** (diagram, file table, dependency map) as a visual "here's how it connects today" reference that complements the primer.
3. Present the ranked approaches table (from Phase 3) with per-approach explanations
4. Use `AskUserQuestion` with the approaches as options. Include the starred recommendation as the first option with "(Recommended)" in the label. Add a "None of these work" option.

```
AskUserQuestion:
  question: "Which approach fits best?"
  options:
    - label: "Approach N: [name] (Recommended)"
      description: "[summary]"
    - label: "Approach N: [name]"
      description: "[summary]"
    - label: "Hybrid of approaches"
      description: "I'll describe the combination I want"
    - label: "None of these work"
      description: "I'll explain what's missing — re-analyze with different constraints"
```

5. **Handling each response:**
   - **Approach selected** — the chosen approach becomes the architectural foundation for Phase 5. The Approach Gate is satisfied.
   - **Hybrid** — user describes the combination. Synthesize and confirm the hybrid before proceeding.
   - **"None of these work"** — user explains what's missing or what constraints were overlooked. Loop back to Phase 3 with the new constraints. Scope confirmation and any prior decisions carry over — only the architecture analysis is redone.

**If the user flags something wrong with the map:** spawn 1-2 Explore agents (`subagent_type: Explore`, `model: sonnet`) to re-explore the specific areas that are off. Re-synthesize the updated findings and re-do the architecture analysis. But don't proactively ask — let the user raise it.

### Phase 5: Design Interview (Main Agent)

The user has already chosen an architectural approach in Phase 4. Do NOT present high-level approaches again — Phase 3 already handled that. Instead, refine details *within* the chosen approach.

Work through the design questions from Phase 1 + your own judgment:

- **One question at a time** — never 2+ in one message
- **Multiple choice preferred** — use AskUserQuestion with options when possible
- **Follow the Presenting Suggestions format** — explain each option in full detail (what it is, pros, cons, recommendation) as regular text BEFORE the AskUserQuestion popup. The popup labels should be concise references to the detailed breakdown above.
- **Include player impact where user-facing** — when a design question affects something the player sees, feels, or interacts with, include the player experience tradeoffs in the question. How does each option change what the player experiences?
- **YAGNI ruthlessly** — push back on scope creep
- **Add a "This changes the approach" escape hatch** — every design question's AskUserQuestion includes an option:
  ```
  - label: "This changes the approach"
    description: "This question reveals the chosen approach doesn't fit — re-evaluate"
  ```
  If selected: loop back to Phase 3 with all answered design questions carrying over. The new architecture analysis accounts for the design insight that triggered the loop-back.

Cover:
- What exactly should change (behavior, not implementation)
- Which approach fits existing patterns best
- What the user expects to see/feel (UX)

**Capability disclosure (mandatory):** Before asking the open-ended question below, present a list of every feature, capability, or system behavior you discovered during exploration that you haven't yet asked about. Frame it as: "I also found these capabilities in the existing system — do any of these matter for this feature?" For each item, include: what it does, what including it would cost (rough complexity), and your recommendation. Let the user decide include/defer for each one. Work through any that the user wants to discuss as individual design questions (one at a time, same rules as above).

After the capability disclosure and any follow-up questions, ask: **"Anything else on your mind before we move on?"** — give the user space to raise concerns or questions the exploration didn't anticipate. Work through any new questions one at a time before proceeding.

### Phase 6: Before/After Comparison (Main Agent)

Once all design questions are resolved, present a **side-by-side comparison** of the current system vs the proposed design. This is the user's chance to see the full picture before moving to edge cases.

**Format:**

**Current system** — reuse the system map from Phase 4 (flow diagram, file table, dependency map). This is the "before."

**Proposed system** — build a new system map reflecting all design decisions made in Phases 3-5. Same format as the current system map:
1. Updated data/control flow diagram (ASCII) showing the new paths
2. Updated file responsibility table — which files change, which are new, which are untouched
3. Updated dependency map — how the blast radius shifts

**Player experience delta** — describe what changes from the player's perspective:
- **Before:** what the player currently sees/experiences (drawn from the Phase 1 player impact summary)
- **After:** what the player will see/experience with the proposed design (incorporating all design decisions)

Present both maps and the player experience delta together so the user can compare. Highlight what's changing: new files, modified responsibilities, new or removed dependencies.

**Do not ask for confirmation of the comparison itself** — present it and move toward edge cases. The Comparison Gate is satisfied once the user responds to the following AskUserQuestion:

```
AskUserQuestion:
  question: "Here's the before/after. Ready to move to edge cases?"
  options:
    - label: "Looks good — continue"
      description: "Move to edge case interview"
    - label: "Something's off"
      description: "I'll point out what needs fixing"
    - label: "This approach doesn't fit"
      description: "Seeing it laid out, this approach isn't right — re-evaluate"
```

- **"Looks good"** — proceed to Phase 7.
- **"Something's off"** — address the issue, update the comparison, re-present, and re-ask via AskUserQuestion. The Comparison Gate requires a clean response.
- **"This approach doesn't fit"** — loop back to Phase 3. All confirmed design decisions from Phase 5 carry over as constraints for the new architecture analysis. Scope confirmation from Phase 2 is preserved.

### Phase 7: Edge Case Interview (Main Agent)

First, present the full edge case table so the user sees the landscape:

| Category | What to Check |
|----------|--------------|
| **Boundaries** | Empty state, max values, first-time user, zero items |
| **UX flows** | What does the user see at each step? Dead ends? Loading states? |
| **Logic gaps** | Contradictions in the proposed approach? Missing transitions? |
| **Scope creep** | Are we adding things that aren't needed for the core feature? |
| **Dependencies** | What breaks if we change X? What needs to change together? |
| **State** | What state changes? Serializable? Race conditions? Undo? |
| **Error paths** | What fails? How does the user recover? |
| **Player impact** | How do edge cases affect the player? Jarring transitions? Lost progress? Confusing feedback? |

Then **interview the user on each unresolved edge case, one at a time** — same rules as Phase 5:
- **One question at a time** — never batch edge case questions
- **Multiple choice preferred** — use AskUserQuestion with options when possible
- **Follow the Presenting Suggestions format** — explain each option in full detail (what it is, pros, cons, recommendation) as regular text BEFORE the AskUserQuestion popup. The popup labels should be concise references to the detailed breakdown above.
- **Frame in terms of player impact** — when an edge case is user-facing, describe what the player would experience for each resolution option. "If the inventory is full when the reward triggers, the player sees..." is better than "if the list is at capacity, the system..."
- **YAGNI ruthlessly** — if an edge case is out of scope, say so and recommend skipping it
- Don't just ask "does this look right?" — ask "what should happen when X?" with concrete options

Work through all edge cases that need a decision. Skip ones that are already resolved by decisions from Phase 4 or Phase 5. Mark each as resolved or explicitly out of scope.

**If gaps or unknowns surface:** spawn 1-2 Explore agents (`subagent_type: Explore`, `model: sonnet`) targeted at the specific unknowns. Give each agent the specific question to answer and the area to explore. Synthesize their findings, then loop back to Phase 4 to re-present the updated system map and approach before continuing. This is a full loop-back — not a patch within Phase 7.

### Phase 8: Design Summary

Assemble the complete design summary from all prior phases:

- **System map** — current and proposed (Phase 6)
- **Ranked approaches table** — the full table (Phase 3 — user's chosen approach marked)
- **Design decisions** — all answers from the interview (Phase 5)
- **Edge case resolutions** — all resolved edge cases with their chosen options (Phase 7)
- **Player experience summary** — the complete player experience picture: current state, proposed state, and the delta (synthesized from Phases 1, 5, 6, and 7)

**Branching strategy** — ask the user before assembling:

```
AskUserQuestion:
  question: "Do you want to create a new branch for this work, or stay on the current branch?"
  header: "Branching strategy"
  options:
    - label: "New branch"
      description: "Create a feature branch before implementation starts"
    - label: "Current branch"
      description: "Work directly on the current branch ({{current branch name}})"
```

Record the user's choice. If they pick "New branch", ask for a branch name or suggest one based on the feature (e.g., `feat/<feature-name>`).

- **Menu file path** (if applicable)

Present the assembled summary to the user. Every individual piece was already confirmed in prior phases (scope, approach, design decisions, edge cases). The summary assembles confirmed artifacts; it does not need its own confirmation gate. Proceed to Phase 9.

### Phase 9: Menu Context Propagation

<HARD-GATE>
If a menu file exists with pending plans, this phase is mandatory. Do not skip it. Do not hand off to recipe without completing it. Design findings that aren't propagated to future plans are lost when the session ends.
</HARD-GATE>

1. **Check for a menu file.** Use the menu file path from the handoff (if provided). If none, check `~/.claude/plans/*-menu.md` for a menu referencing this work. If no menu exists or no pending plans remain, skip to the handoff step below.

2. **Gather findings relevant to future plans.** Review what prep discovered and identify information that future plans need but wouldn't have from the original menu context alone. Look for:
   - **Design decisions that constrain future plans** — architectural choices, patterns selected, interface contracts that downstream plans must follow
   - **System relationships discovered** — dependencies, shared state, ordering requirements between the current plan's systems and future plans' systems
   - **Edge case resolutions with cross-plan impact** — decisions made here that affect how future plans should handle similar cases
   - **Patterns and conventions established** — naming, structure, data flow patterns that future plans in the same area should match
   - **Scope items explicitly deferred** — things the user said "not now, later" to during the design interview that map to a specific future plan

3. **Match findings to specific plans.** For each pending plan in the menu, identify which findings are relevant to that plan's goal and scope. Not every finding applies to every plan — be precise about which plan each finding belongs to.

<HARD-GATE>
The user must confirm proposed context additions before any writes happen. Present the additions first, get approval, then write.
</HARD-GATE>

4. **Present the proposed additions to the user.** For each pending plan that has relevant findings, show:
   - The plan name and goal (for reference)
   - The specific additions you propose to append to its Context field
   - Why each addition is relevant to that plan

5. **Ask for confirmation via `AskUserQuestion`:**

```
AskUserQuestion:
  question: "These findings from prep are relevant to future plans. Approve the updates?"
  header: "Menu context"
  options:
    - label: "Approve all"
      description: "Add all proposed context to the future plans"
    - label: "Edit first"
      description: "I want to adjust what gets added"
    - label: "Skip"
      description: "Don't update future plans"
```

6. **Handle the response:**
   - **"Approve all"** — append the proposed additions to each plan's Context field in the menu file using `Edit`.
   - **"Edit first"** — let the user specify what to change, adjust, re-present, and re-ask.
   - **"Skip"** — proceed without updating. The user may have their own reasons.

7. **Handoff to recipe.** Invoke `oven:recipe` immediately — passing the design summary from Phase 8 as context.

## Red Flags — STOP

See "Universal Red Flags" in CLAUDE.md for cross-skill red flags. Skill-specific flags below:

| Thought | Reality |
|---------|---------|
| "Skip exploration, I can plan from the prompt" | Plans without exploration miss dependencies. |
| "One big question covers it" | One question at a time. Always. |
| "Edge cases can wait until implementation" | Edge cases found late = rework. Find them now. |
| "This is too small to explore" | If it touches >2 files, explore. |
| "I'll map the systems in my head" | If you can't draw it, you don't understand it. |
| "The exploration phase is overkill" | Undiscovered dependencies are the #1 cause of plan rewrites. |
| "The user will understand what I mean" | Vague labels aren't decisions. Follow the Presenting Suggestions format. |
| "The scope from order is enough context" | Order gave you a prompt, not a system map. Synthesize properly. |
| "Let me check the earlier conversation" | Work from the handoff. If it's not in the confirmed prep prompt, explore for it. |
| "Scope looks fine, I'll skip validation" | Every scope gets presented and confirmed. Clean scope still needs the gate. |
| "I can skip the design summary" | The confirmed summary IS the handoff. No summary, no handoff. |
| "I'll just go straight to recipe" | Every phase runs. Explore --> Validate Scope --> Architecture --> Present --> Design Interview --> Compare --> Edge Cases --> Summary & Handoff. |
| "The approach is obvious, skip the options" | Present options. The user decides, not you. |
| "Let me present the synthesis" | Phase 1 is internal. Deliverables appear in the phase where they're relevant. |
| "Let me show the approaches table now" | Phase 3 is internal. Present everything together in Phase 4. |
| "This feature can be deferred to v2" | You don't decide what's deferred. Ask the user. |
| "This capability is internal/not needed" | If it exists in the reference system, surface it as a question. |
| "I'll just exclude this, it's minor" | Minor features are still scope decisions. Ask. |

## Key Principles

- **Prep starts with a sealed handoff** — the confirmed prep prompt from order is the ground truth. Earlier conversation doesn't exist.
- **The flow is mandatory** — Explore --> Validate Scope --> Architecture --> Present --> Design Interview --> Compare --> Edge Cases --> Summary --> Menu Context Propagation --> Handoff. No phase can be skipped.
- **Player experience threads through everything** — from the initial impact summary (Phase 1) through approach tradeoffs (Phase 3), design questions (Phase 5), before/after comparison (Phase 6), and edge case framing (Phase 7). The player's experience is never an afterthought.
- **Design summary is the handoff** — Phase 8 assembles all confirmed artifacts and presents them. Phase 9 propagates relevant findings to future menu plans (if any), then hands off to recipe. What's not in the summary doesn't exist downstream.
- **Explore agents do the heavy lifting** — spawn them for broad exploration. Main agent reads code only for targeted architecture verification, not broad sweeps.
- **Visual mapping is mandatory** — flowcharts, tables, dependency graphs
- **One question at a time** — respect the user's attention
- **YAGNI** — see "Plugin-Wide Principles" in CLAUDE.md
- **Iterative clarification** — loop until unknowns are zero
- **Evidence over assumptions** — see "Plugin-Wide Principles" in CLAUDE.md
- **No silent scope decisions** — never decide to include, exclude, or defer features without asking. If it exists in the reference system, surface it as a design question. Disclose all discovered capabilities before leaving Phase 5.
- **Scope validation, not decomposition** — if exploration finds scope issues, flag them. Decomposition is order's responsibility.
- **Loop-backs preserve progress** — when reclassifying approaches, confirmed scope and answered design questions carry over. Only the invalidated work is redone.

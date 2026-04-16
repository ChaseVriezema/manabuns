---
name: design
description: "Use after /prep to interview the user about their desired feature through visual questions, edge cases, and gameplay flow design"
---

# Design

## Overview

Flesh out exactly what the user wants through conversational interview with heavy visual support. Framed entirely in game design terms -- gameplay, player experience, visual/audio feedback. Engineering decisions happen later.

**Core principle:** No agents. The main agent runs this directly with both prep deliverables in context. Architecture Notes inform which questions to ask and which edge cases are relevant, but are never shown to the user.

**Announce at start:** "Now let's design what you want to build."

## When to Use

- After `/prep` completes and the Functionality Map is confirmed
- When you have both deliverables (Functionality Map + Architecture Notes) in context

**When NOT to use:**
- Before prep — you need the codebase map first
- For bug fixes or refactoring

## Execution

No agents. Main agent runs this directly. Both prep deliverables are already in context.

## The Process

```
Step 1: Restate the Request (before/after flow diagram)
       ↓
Step 2: One Question at a Time (player experience focus)
       ↓
Step 3: Visuals on Every Applicable Question
       ↓
Step 4: Edge Case Presentation (7 categories, each with visual)
       ↓
Step 5: Design Output (stays in context for recipe)
       ↓
Handoff to oven-design:recipe
```

───────────────────────────────────────────────────────────────
### Step 1: Restate the Request
───────────────────────────────────────────────────────────────

Present a before/after flow diagram showing where the new feature fits into the existing Functionality Map.

"Here's what I think you're asking for:"

**Before** — the relevant portion of the current Functionality Map:

```
[Current player flow from prep]
```

**After** — the same flow with the new feature integrated:

```
[Updated player flow showing where the new feature fits]
```

Ask: "Is this what you have in mind, or should I adjust?"

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 2: One Question at a Time
───────────────────────────────────────────────────────────────

Questions focus on **player experience and game design**, never engineering:

Good questions:
- "What happens when the player does X?"
- "Should this be accessible from the main menu or only during gameplay?"
- "What should the player see if they haven't unlocked this yet?"
- "What visual/audio feedback should the player get when this triggers?"
- "How does this interact with the existing [system] loop?"

**NOT** engineering questions:
- "Should we use a singleton or dependency injection?"
- "Do you want this as a ScriptableObject or a MonoBehaviour?"
- "Should I use an event bus or direct references?"
- "What data structure should store this?"

<HARD-GATE>
NEVER ask the user engineering questions. All questions must be framed in terms of what the player sees, does, or experiences. Engineering decisions are made silently during the recipe phase using the Architecture Notes.
</HARD-GATE>

**Rules:**
- One question at a time — never batch multiple questions
- Use the Architecture Notes internally to inform what questions to ask (e.g., if you know a queue system exists, you can ask about timing without explaining why)
- If the user's answer implies an engineering choice, note it internally and move on

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 3: Visuals on Every Applicable Question
───────────────────────────────────────────────────────────────

Every question that can benefit from a visual MUST include one. Types of visuals:

**ASCII wireframes** — for UI/menu questions:
```
┌─────────────────────────┐
│  ★ Power-Up Shop ★      │
├─────────────────────────┤
│  🔥 Fire Boost    50g   │
│  ⚡ Speed Rush    30g   │
│  🛡️ Shield       75g   │
├─────────────────────────┤
│     [ Buy ]  [ Back ]   │
└─────────────────────────┘
```

**Flow diagrams** — for "what happens when" questions:
```
Player taps item → Confirm dialog → Purchase → Play effect → Update inventory
                        ↓
                   Cancel → Back to shop
```

**State diagrams** — for things with multiple states:
```
┌──────────┐    collect    ┌──────────┐    timer    ┌──────────┐
│  Locked  │──────────────→│  Active  │────────────→│ Cooldown │
└──────────┘               └──────────┘             └──────────┘
                                                         │
                                                    timer expires
                                                         │
                                                         ▼
                                                    ┌──────────┐
                                                    │  Ready   │
                                                    └──────────┘
```

**Before/after comparisons** — when modifying existing flows:
```
Before:                          After:
┌────────┐    ┌────────┐        ┌────────┐    ┌──────────┐    ┌────────┐
│ Battle │───→│ Result │        │ Battle │───→│ Loot Drop │───→│ Result │
└────────┘    └────────┘        └────────┘    └──────────┘    └────────┘
```

**Side-by-side options** — for multiple choice questions:
```
"When the player collects a power-up, what should happen?"

Option A:                        Option B:
┌────────────────────┐          ┌────────────────────┐
│  Collect           │          │  Collect           │
│  └→ Flash effect   │          │  └→ Flash effect   │
│  └→ Sound          │          │  └→ Sound          │
│  └→ Apply instant  │          │  └→ Show in HUD    │
└────────────────────┘          │  └→ Tap to activate │
                                └────────────────────┘
```

**Timeline diagrams** — for sequences with animation/audio/visual feedback:
```
Time ──→
  0ms     100ms    300ms    500ms    1000ms
  │        │        │        │        │
  ▼        ▼        ▼        ▼        ▼
  Tap    Flash    Bounce   Sound    Particles
         starts   starts   plays    fade out
```

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 4: Edge Case Presentation
───────────────────────────────────────────────────────────────

After understanding the core flow, proactively surface edge cases as visual scenarios. Cover all 7 categories:

| Category | What to Ask |
|----------|-------------|
| **Empty states** | "What does this look like before the player has earned anything?" |
| **Error/failure** | "What if the network drops mid-transaction?" |
| **Boundary** | "What if the player has 999 of these?" |
| **Timing** | "What happens if this triggers mid-animation or during a scene transition?" |
| **Permission/progression** | "Can all players access this or only after reaching level X?" |
| **Interruption** | "What if the player backgrounds the app during this flow?" |
| **Conflict** | "What if two systems try to show feedback at the same time?" |

**Rules:**
- Present each edge case one at a time
- Include a visual showing the scenario and proposed handling
- Use the Architecture Notes to determine which edge cases are technically relevant (e.g., if the codebase has no save system, skip interruption-during-save scenarios)
- Skip edge cases that aren't relevant to this feature
- For each case, propose a default handling and ask the user to confirm or adjust

Example edge case presentation:

```
"What if the player hasn't earned any power-ups yet?"

┌─────────────────────────┐
│  ★ Power-Up Shop ★      │
├─────────────────────────┤
│                         │
│   No power-ups yet!     │
│   Complete a level to   │
│   earn your first one.  │
│                         │
├─────────────────────────┤
│        [ Back ]         │
└─────────────────────────┘

I'd suggest showing a friendly message pointing the player toward
how to earn power-ups. Does this work, or would you prefer something
different?
```

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 5: Design Output
───────────────────────────────────────────────────────────────

After all questions and edge cases are resolved, compile the complete feature design. This stays in conversation context for the recipe phase:

1. **Player flow diagram** (ASCII) — the final "after" flow incorporating all decisions
2. **Scene/state inventory** — every scene, screen, or state the feature touches, with descriptions
3. **Visual/audio feedback notes** — what the player sees and hears at each interaction point
4. **Edge case decisions** — how each relevant edge case is handled, with the user's confirmation
5. **"Done" criteria** — in plain language, what the player experiences when this feature is complete

Present this as: "Here's the complete design for your feature. Once you're happy with it, I'll put together the build plan."

## Handoff Document

After the user confirms the Design Output (Step 5), update the handoff
document before invoking recipe.

1. Read `.oven/HANDOFF.md` with the Read tool
2. Locate the DESIGN section between `<!-- SECTION:DESIGN -->` and
   `<!-- /SECTION:DESIGN -->`
3. **If the section is empty (first run):**
   Write the full design output using these exact sub-headings:
   - `### Player Flow` — final "after" ASCII flow diagram
   - `### Scenes & States` — scene/state inventory
   - `### Feedback` — visual/audio feedback at each interaction point
   - `### Edge Cases` — organized by category with confirmed resolutions
   - `### Done Criteria` — plain-language checklist of what "done" looks like
4. **If the section has content (re-run):**
   Compare existing decisions against this session's conversation:
   - Decisions from THIS session are authoritative (override conflicts)
   - Decisions in the existing doc not discussed this session stay as-is
   - New decisions from this session get added
   Write the reconciled result.
5. Replace only the DESIGN section. Leave all other sections untouched.
6. Update the **Last updated** date in the header.
7. Stage and commit:
   - `git add .oven/HANDOFF.md`
   - `git commit -m "oven: design handoff — [feature name]"`

## Handoff

After updating the handoff document, invoke `oven-design:recipe` — passing:
- Both prep deliverables (Functionality Map + Architecture Notes)
- The complete design output from Step 5

## Architecture Notes Usage

The Architecture Notes from prep inform this phase silently:
- **Question selection** — knowing what systems exist helps ask the right "how does this interact with..." questions
- **Edge case relevance** — knowing the codebase architecture helps determine which edge cases are technically possible
- **Feasibility awareness** — if something the user wants would require massive rearchitecting, the design phase can gently steer toward simpler alternatives (in player terms: "that would change a lot of how your game works — would a simpler version that does X work instead?")

**Never surface Architecture Notes to the user.** The user should feel like they're in a design conversation, not a technical review.

## Red Flags — STOP

| Thought | Reality |
|---------|---------|
| "I'll batch these questions to save time" | One question at a time. Always. |
| "This question doesn't need a visual" | If a visual could help, include one. |
| "I'll ask about the data model" | Player experience only. Engineering is your job. |
| "Edge cases can wait" | Edge cases found late = rework. Find them now. |
| "The user seems technical, I can use engineering terms" | Player-experience vocabulary always. No exceptions. |
| "I'll skip straight to the recipe" | The design output must be confirmed before planning begins. |

## Key Principles

- **Player-experience vocabulary always** — the user is a game designer, not an engineer
- **One question at a time** — respect the user's attention
- **Visuals on every applicable question** — show, don't just tell
- **All 7 edge case categories** — proactive, not reactive
- **Architecture Notes inform, never surface** — the user never sees engineering details
- **Confirm design before recipe** — no planning until the design is locked

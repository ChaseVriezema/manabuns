---
name: shop
description: "Use when you need to understand a system, map its architecture, find structural flaws, or get a big-picture view of how code is organized -- not tied to any implementation task"
---

# Shopping -- System Mapping & Architecture Analysis

## Overview

Turn "how does this work?" or "what's wrong here?" into a complete system map with architecture observations, using agent-team exploration.

**Core principle:** A single synthesizer agent owns exploration and compression, main agent presents to the user and drives follow-up. The main agent never reads code. Understanding is the deliverable.

**Announce at start:** "Let me check the shelves -- I'll map out what we're working with."

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, or propose changes. This skill produces understanding, not action plans. If the user wants to act on findings, hand off to the appropriate skill after the map is complete.
</HARD-GATE>

## When to Use

- User asks "how does X work?"
- User wants a system, module, or feature explained
- User suspects an architectural flaw but isn't sure where
- User wants to understand dependencies before deciding what to change
- User asks for a "big picture" or "bird's eye view"
- User wants to audit or review architecture quality

**When NOT to use:**
- User already knows what to build -> use oven:order
- User has a specific bug to fix -> use oven:smoke-check
- Simple "what does this function do?" questions -> just answer them

## Context Boundary (when invoked from order)

Shop may be invoked directly or via order's routing. When invoked from order, it receives a **sealed exploration brief**:

| Field | Content |
|-------|---------|
| **Question** | Confirmed interpretation of what the user wants to understand |
| **Relevant areas** | Systems/modules from orientation |
| **Starting points** | File paths |
| **Suggested depth** | Just this module / include neighbors / full chain |
| **Assumptions** | Confirmed assumptions from interview |

For mixed-intent routing, the brief also includes:
- **Implementation goal** — what the user wants to build after understanding
- Implementation re-enters order as a fresh flow after shop completes

When invoked directly (no order handoff), shop gathers context from the conversation itself.

## Main Agent Context Budget

See "Context Budget Rule" in CLAUDE.md — the main agent NEVER reads code files.

**What the main agent sees:**
- System map (compact visuals from synthesizer)
- Architecture observations (from synthesizer)
- User's follow-up questions
- Targeted re-exploration results

## Presenting Suggestions

Follow the **Presenting Options Format** in CLAUDE.md. Key additions for shop:

- Every observation or option needs: what it is (behavior first, code refs from system map), specific pros/cons/impact, and a recommendation signal
- Present the detailed breakdown as regular text BEFORE the `AskUserQuestion` popup
- Popup labels should be concise references to the breakdown above

## The Process

```
Phase 1: Intake (main)
       |
Phase 2: Explore & Synthesize (synthesizer agent)
       |
Phase 3: Quality Check (main evaluates map completeness)
       |
  Map sufficient? --no--> Targeted re-explore --> back to Phase 3
       |
       yes
       |
Phase 4: Present Map (main presents to user)
       |
  Map wrong? ------yes--> Targeted re-explore --> back to Phase 3
  Dig deeper? -----yes--> Targeted re-explore --> back to Phase 4
  Act on findings? yes--> Hand off to oven:order or oven:smoke-check
       |
       no (done)
       |
  Done
```

### Phase 1: Intake (Main Agent)

1. Acknowledge the user's request
2. **If the user's message already clearly states their goal** (e.g., "how does the skill loading system work?"), confirm the mapping instead of re-asking: "Sounds like you want to understand how a system works -- that right?" Only use the full AskUserQuestion if the goal is ambiguous:
   ```
   AskUserQuestion:
     question: "What are you trying to understand?"
     header: "Goal"
     options:
       - label: "How a system works"
         description: "I want a full map of a module, feature, or subsystem"
       - label: "Find architectural issues"
         description: "I suspect something is off and want a structural critique"
       - label: "Understand dependencies"
         description: "I want to know what connects to what before making changes"
       - label: "General exploration"
         description: "I want a bird's-eye view of an area of the codebase"
   ```
3. **Scope calibration** -- probe the boundary of what the user wants mapped:
   ```
   AskUserQuestion:
     question: "How wide should the map be?"
     header: "Scope"
     options:
       - label: "Just this module/feature"
         description: "Map only the specific system I mentioned, stop at its boundaries"
       - label: "Include direct neighbors"
         description: "Map the system plus the systems it directly talks to"
       - label: "Full picture"
         description: "Follow the chain as far as it goes -- I want to see everything connected"
   ```
4. Ask about starting points:
   ```
   AskUserQuestion:
     question: "Are there any files or areas of the codebase I should start from? If so, type the paths -- use backticks (e.g. `Assets/.../File.cs`), NOT @mentions."
     header: "Starting points"
     options:
       - label: "Yes, I have specific files"
         description: "I'll type file paths or areas for you to start exploring from"
       - label: "Yes, I have a general area"
         description: "I know the module/system but not exact files"
       - label: "No, explore on your own"
         description: "Search the codebase from scratch based on my request"
   ```
   - If the user selects "Yes" options, wait for them to provide paths, then confirm: "Got it. Anything else, or should I start exploring?"
   - If the user selects "No, explore on your own", proceed directly to Phase 2.
5. **You (the main agent) do NOT read files, do NOT spawn explore agents directly.** Pass everything to the synthesizer agent.

### Phase 2: Explore & Synthesize (Single Agent)

Launch a **single agent** via the `Agent` tool (`subagent_type: general-purpose`) -- the **synthesizer**. It owns the entire exploration and synthesis pipeline. The main agent never sees raw explore data.

See "Subagent Dispatch Rules" and "Agent Output Protocol" in CLAUDE.md for dispatch and output rules.

**What to pass the synthesizer:**
- The user's question / area of interest
- The user's goal and scope boundary (from Phase 1)
- Any files or areas the user pointed to
- The five deliverables listed below (paste them into the synthesizer prompt so it knows exactly what to produce)
- Explicit instruction: **"Your final response text IS your deliverable. Structure your response with the five sections below using the exact names and formats shown. Do not save to files -- return everything as text."**

**The synthesizer internally:**
1. **Scales agent count to codebase size.** For small targets (fewer than ~10 files in the area of interest), the synthesizer may explore directly without spawning sub-agents. For medium targets, 1-2 Explore agents (`subagent_type: Explore`, `model: sonnet`). For large targets, 2-4 Explore agents (`subagent_type: Explore`, `model: sonnet`) with different starting points.
2. Agents explore from user-provided files AND search the codebase independently
3. Each agent reports back: files found, patterns observed, dependencies, data flow, state involved
4. Synthesizer collects all raw reports and compresses them into its final response

**What explore agents look for:**
- How the relevant systems currently work (data flow, control flow)
- What patterns are used (MVVM, commands, state machines, events, etc.)
- What files are involved and what each one does
- What other systems depend on or feed into these
- Pattern consistency -- are the same patterns used throughout or is it mixed?
- Complexity hotspots -- files/classes doing too much, deep nesting, god objects
- Coupling concerns -- tight coupling, circular dependencies, hidden dependencies

**Synthesizer deliverables:**

**1. Data/control flow diagram (ASCII):**
```
UserInput -> ViewModel -> Command -> Handler -> State
                |                              |
              View <- Model <- StateChanged <--+
```

**2. File responsibility table:**

| File | Responsibility | Depends On | Depended By |
|------|---------------|------------|-------------|
| `path/to/File.cs` | Handles X | Model, Config | View, Controller |

**3. Dependency map (ASCII):**
Which systems connect to which -- shows how information and control flows between boundaries.
```
+------------------+       +------------------+
|   SkillLoader    |------>|  PluginRegistry  |
+------------------+       +------------------+
        |                          |
        v                          v
+------------------+       +------------------+
|  FileSystem (R)  |       |  SkillValidator  |
+------------------+       +------------------+

Arrow = depends on / calls into
(R) = read-only access
```

**4. Architecture patterns catalog:**
What patterns are in use across the explored area. Note consistency -- is the same pattern used everywhere, or are there mixed approaches?

**5. Observations:**
Things that stand out. Organized by type. **Observations describe what IS, not what SHOULD BE.** "File X handles both discovery and loading (250 lines)" is a map observation. "File X should be split" is a planning suggestion -- don't do that.

| Type | What to Flag |
|------|-------------|
| **Inconsistency** | Mixed patterns for similar problems |
| **Coupling** | Tight/circular dependencies, god objects |
| **Complexity** | Deep nesting, large files, unclear flow |
| **Missing boundaries** | Logic that spans layers it shouldn't |
| **Strengths** | Clean separations, good patterns worth preserving |

**Goal-specific emphasis:**
- **"How a system works"** -> Emphasize flow diagrams and file table clarity
- **"Find architectural issues"** -> Emphasize observations, especially inconsistencies and coupling
- **"Understand dependencies"** -> Emphasize dependency map and blast radius
- **"General exploration"** -> Balanced across all deliverables

### Phase 3: Quality Check (Main Agent)

Before presenting to the user, evaluate whether the synthesizer's map is sufficient:

- **Does the flow diagram cover the scope the user asked for?** If the user asked for "include direct neighbors" but the diagram only shows the core module, re-explore.
- **Does the file table have actual file paths?** Vague entries like "some config file" mean the synthesizer didn't dig deep enough.
- **Are the observations grounded in specifics?** "There might be coupling issues" is not enough -- observations need file names and concrete descriptions.
- **Is the map proportional to the codebase?** A 50-row file table for a 5-file area is too broad. A 2-row table for a 30-file system is too shallow.

If the map falls short, spawn a targeted synthesizer agent via the `Agent` tool (`subagent_type: general-purpose`) to fill the specific gaps (include the same output protocol instruction), then re-evaluate.

### Phase 4: Present Map (Main Agent)

Present the full system map to the user:

1. Start with the flow diagram -- give the big picture first
2. File responsibility table -- what each piece does
3. Dependency map -- how things connect
4. Architecture patterns -- what's in use
5. Observations -- what stands out (tailored to user's goal from Phase 1)

After presenting, ask for feedback:

```
AskUserQuestion:
  question: "How does the map look?"
  header: "Feedback"
  options:
    - label: "Looks right"
      description: "The map matches my understanding -- I'm done or want to dig into a specific area"
    - label: "Something's off"
      description: "Part of the map doesn't match what I know -- I'll tell you what's wrong"
    - label: "Too shallow"
      description: "I need more depth in certain areas"
    - label: "I want to act on this"
      description: "I see something I want to fix, build, or change"
```

**Handling each response:**
- **"Looks right"** -- ask if they want to dig deeper into any specific area, or if they're done.
- **"Something's off"** -- the map is wrong. Ask what's incorrect, then spawn a targeted synthesizer agent (with output protocol instruction) to re-explore the specific areas that are off. Loop back to Phase 3 (quality check the corrected map before re-presenting).
- **"Too shallow"** -- spawn a targeted synthesizer agent (with output protocol instruction) for the areas that need more depth. Loop back to Phase 4.
- **"I want to act on this"** -- present handoff options:
  ```
  AskUserQuestion:
    question: "What kind of action?"
    header: "Handoff"
    options:
      - label: "Build or change something"
        description: "Hand off to oven:order with this map as starting context"
      - label: "Fix a bug or flaw"
        description: "Hand off to oven:smoke-check with this map as starting context"
  ```
  **What to pass on handoff:** The flow diagram, file responsibility table, dependency map, and any relevant observations. The receiving skill gets the full map so it doesn't need to re-explore from scratch.

## Red Flags -- STOP

See "Universal Red Flags" in CLAUDE.md for cross-skill red flags. Skill-specific flags below:

| Thought | Reality |
|---------|---------|
| "The user probably wants to fix this" | Shop produces understanding, not action plans. Ask first. |
| "Let me suggest how to refactor X" | You're mapping, not planning. Flag the observation and move on. |
| "This is too small to map" | If the user asked for a map, give them a map. Scale the agent count down, not the process. |
| "Let me skip to the interesting part" | Present the full map. The user decides what's interesting. |
| "I should enter plan mode for this" | Shop doesn't use plan mode. It's exploration only. |
| "File X should be split into two" | Observations describe what IS, not what SHOULD BE. State the fact, not the fix. |

## Key Principles

- **Main agent never reads code** -- synthesizer owns exploration
- **Visual mapping is mandatory** -- flowcharts, tables, dependency graphs
- **Understanding is the deliverable** -- don't drift into planning or implementation
- **Goal-aware synthesis** -- tailor emphasis to what the user is trying to learn
- **Scale to the problem** -- 1 agent for 5 files, 4 agents for 50 files
- **Quality before presentation** -- evaluate the map before showing it to the user
- **Iterative depth** -- start broad, drill down where the user asks
- **Evidence over assumptions** -- see "Plugin-Wide Principles" in CLAUDE.md

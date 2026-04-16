# Oven Plugin

This is a Claude Code plugin primarily targeting **Unity developers working in C#**. Skills, plans, and workflows should default to Unity conventions while still supporting general development when the project isn't Unity/C#.

## Skill Priority

<HARD-GATE>
When both oven and superpowers are installed, **always prefer oven skills**. Do not invoke superpowers skills unless the user explicitly asks for them by name (e.g., "use superpowers:brainstorming").

| Instead of | Use |
|------------|-----|
| `superpowers:brainstorming` | `oven:order` |
| `superpowers:writing-plans` | `oven:recipe` |
| `superpowers:executing-plans` | `oven:cooking` |
| `superpowers:test-driven-development` | `oven:mise-en-place` |
| `superpowers:verification-before-completion` | `oven:proof` |
| `superpowers:requesting-code-review` | `oven:taste` |
| `superpowers:receiving-code-review` | `oven:taste-response-guidelines` |
| `superpowers:systematic-debugging` | `oven:smoke-check` |
| `superpowers:subagent-driven-development` | `oven:cooking` |

Superpowers skills with no oven equivalent (`superpowers:dispatching-parallel-agents`, `superpowers:using-git-worktrees`, `superpowers:finishing-a-development-branch`, `superpowers:writing-skills`) may still be used freely — there is no oven replacement for these.

This applies to implicit skill selection too. When deciding which skill fits a task, check oven's skills first. Only fall through to superpowers if no oven skill covers the need.
</HARD-GATE>

## Default Routing

<HARD-GATE>
Any user prompt that looks like a task — building, fixing, changing, exploring, debugging, refactoring, adding, removing, or any other action involving the codebase — MUST route through `oven:order` first. Order is the universal front door. If you're unsure whether a prompt is a task, it probably is — invoke order.

The only prompts that skip order:
- Simple factual questions with no codebase context needed ("what's a singleton?")
- Conversation that isn't a task (greetings, feedback, meta-discussion)
- Explicit skill invocations by name (e.g., "/menu", "/taste")
</HARD-GATE>

## Shell Command Rules

<HARD-GATE>
NEVER use compound or nested shell commands. Each Bash call must be a single, simple command. This means:
- No `&&`, `||`, or `;` chaining
- No `$()` or backtick subshells
- No piping (`|`) — run commands separately and use tool results
- No redirects unless the command itself requires one (e.g., `echo "x" > file` is fine)

Compound commands bypass the user's permission allow list and trigger manual approval prompts. Run each command as its own Bash invocation.
</HARD-GATE>

## Presenting Options Format

Whenever presenting options, suggestions, tradeoffs, or observations to the user, follow this visual format:

- **Problem/context in a `╔═══╗` banner** with the title in backticks for color contrast
- **`📌 ═══` separator-headers** with option title in backticks — e.g., `` 📌 ═══ `Option A: Title here` ═══ ``
- **Pros/cons in a markdown table** — two columns: emoji icon (`✅` / `❌` / `⚠️`) and detail text
- **`\*` spacer lines** between each section (banner, each option, recommendation) for visual breathing room
- **`💡` recommendation** after all options, prefixed with lightbulb emoji
- **No blockquotes (`>`)** for the breakdown — use plain text with the structure above

Individual skills reference this format as "Presenting Suggestions format."

## Prefer Built-in Tools Over Scripts

Do not write and execute scripts (Python, Ruby, Node, etc.) when a built-in tool can accomplish the same task. Built-in tools like Grep, Glob, Read, and Edit are faster, safer, and don't require runtime approval.

For example, use `Grep` with a regex like `\s+$` to find trailing whitespace — don't write a Python script to do it.

## Context Budget Rule

<HARD-GATE>
For skills that use heavy subagent delegation (plating, shop), the main agent NEVER reads raw code files. All file access is delegated to subagents, which compress findings into structured summaries before returning.

**Order** reads code directly for lightweight orientation (shallow exploration to classify and route).

**Prep** spawns Explore agents for broad exploration but the main agent reads targeted code sections for architecture analysis. Keep broad sweeps in Explore agents — main agent reads only specific files to verify patterns.

**Recipe** reads code directly — it needs exact patterns, signatures, and imports to write complete implementation code. Uses prep's file table as a map for targeted reads.

Skills where the main agent reads files directly: order, prep (targeted), recipe, cooking, smoke-check, mise-en-place, proof, taste-response-guidelines, fast-food.

Skills where the main agent delegates all file access: plating, shop.
</HARD-GATE>

## Subagent Dispatch Rules

<HARD-GATE>
When dispatching any subagent, NEVER include:
- Session history or conversation turns
- Internal deliberation or thought process
- Concerns from unrelated tasks
- Raw conversation context from before the current skill's handoff

Subagents receive only their task-specific inputs. Construct prompts precisely — less is more. This keeps agents focused and preserves the main agent's context for coordination.
</HARD-GATE>

## Agent Output Protocol

<HARD-GATE>
Every agent dispatched via the `Agent` tool must follow this protocol. The agent's **final response text** is its deliverable — that text is returned verbatim to the caller as the tool result. If the agent doesn't write a structured final response, the caller receives nothing useful.

**Rules for every dispatched agent:**

1. **Your response IS your deliverable.** Do not assume the caller can see your intermediate work, tool calls, or thought process. Only your final response text is returned. Structure it with the sections the caller requested.
2. **Write artifacts to your response, not to files** — unless the skill explicitly says to save to disk (e.g., "save the plan to `~/.claude/plans/`"). When in doubt, return it as text.
3. **Use the exact output structure the caller specified.** If the caller asked for "a file responsibility table and a flow diagram," your response must contain those sections with those names. Don't rename, reorganize, or omit sections.
4. **End with a status line** when the skill defines status codes (e.g., `PLATING_COMPLETE`, `PLATING_BLOCKED`, `Verdict: PASS`). The status line must be the last thing in your response so the caller can parse it reliably.
5. **If you can't complete the work,** say so explicitly in your response with what's missing. A silent failure (no response, empty response, or a response that doesn't address the task) is the worst outcome — the caller will re-dispatch you, wasting time and context.

**Terminology:** Skills refer to agents by role name (food-critic, plating, reviewer). These are all dispatched via the `Agent` tool — the role name describes the job, not a special agent type. Use `subagent_type` to select the agent capability (`Explore` for codebase search, `general-purpose` for everything else).
</HARD-GATE>

## Agent Failure Recovery

When a dispatched agent returns empty, incomplete, garbled output, or doesn't return at all:

1. **Don't retry blindly.** Check: was the prompt too large? Too vague? Missing context the agent needed?
2. **Re-dispatch with a tighter prompt.** Strip unnecessary context, add explicit output structure, reduce scope if needed.
3. **If the agent was supposed to save to disk,** check if it partially saved before failing — resume from the partial artifact rather than starting over.
4. **If the agent tool call itself fails or returns no output,** treat it the same as an empty response — diagnose and re-dispatch.
5. **After 2 failed dispatches for the same task,** escalate to the user. Something structural is wrong.

## Verdict Parsing

<HARD-GATE>
When a food-critic agent returns a response, parse the `Verdict:` line:

- **`Verdict: PASS`** — proceed to the next phase.
- **`Verdict: NEEDS FIXES`** — enter the fix flow.
- **No Verdict line, or ambiguous verdict** — treat as a failed dispatch. Re-dispatch with a tighter prompt per Agent Failure Recovery. Do not guess the intent.
- **Verdict contradicts body** (e.g., says PASS but lists Critical findings) — treat as NEEDS FIXES. The findings are the ground truth, not the label.

This applies to every food-critic dispatch: cooking Phase 3, Phase 4 re-review, Phase 5 plating review, standalone plating Phase 5, and taste.
</HARD-GATE>

## Sealed Handoffs

<HARD-GATE>
Every handoff between oven skills is a sealed artifact — the receiving skill works from the handoff, not from earlier conversation context. What's not in the handoff doesn't exist downstream.

This applies to all skill-to-skill transitions: order→prep (via enhanced prompt), order→shop (via exploration brief), order→smoke-check (via problem brief), prep→recipe (via design artifacts), recipe→cooking (via plan file).
</HARD-GATE>

## Always Commit, Never Push

<HARD-GATE>
Every skill that makes changes to the codebase MUST commit all work before finishing. No skill leaves uncommitted changes behind — if files were modified, they get committed. This applies universally: cooking, plating, smoke-check, and any other skill that touches code.

Skills NEVER push to remote. The user handles pushing.
</HARD-GATE>

## Food-Critic Severity Response

When acting on food-critic findings, use the **Review Triage Flow** for interactive contexts (cooking Phase 4, taste). Plating is autonomous and does NOT use this flow — plating handles findings internally per its own rules.

### Review Triage Flow

Walk through findings by severity, highest first. Every item is numbered (the food-critic numbers them sequentially across all severities). Each category gets a gate question, then each item gets an action question.

**Step 1 — Category gate:** For each non-empty severity (critical → important → minor), use `AskUserQuestion`:

- Question: "Want to go through the {N} {severity} item(s)?"
- Options: "Yes, go through them" / "Skip this category"
- If the user skips, move to the next category

**Step 2 — Per-item action:** For each item in the category, use `AskUserQuestion`:

- Question: "{number}. [{file:line}] {description}"
- Options: "Fix it" (tab to add context on how) / "Skip it" (tab to note why)

The user can tab on either option to amend extra context that gets incorporated into the fix.

**Step 3 — Execute fixes:** After walking all categories, the main agent fixes all "Fix it" items directly, incorporating any user-provided context. After all fixes are applied, dispatch a fresh food-critic agent with cumulative context (prior findings, what was fixed, updated diff) for re-review.

**Disagree with a finding?** Push back with technical reasoning before presenting the item — reviewers can be wrong. Present your reasoning inline, then let the user decide via the normal Fix/Skip options.

## Fix Cycle Cap

<HARD-GATE>
If issues persist after 2 fix+re-review cycles, present remaining findings to the user. Do not enter a third cycle. Repeated fix cycles indicate the fixes are creating new problems — the user needs to make a judgment call.
</HARD-GATE>

## Universal Red Flags

These red flags apply across ALL oven skills. If you catch yourself thinking any of these, STOP:

| Thought | Reality |
|---------|---------|
| "I'll just read the files myself" | Delegate to agents. Keep your context clean. (plating, shop) |
| "I already know this codebase" | Agents find what you miss. Explore/delegate anyway. |
| "I'll skip the review/verification" | Reviews and verification are never optional. |
| "While I'm here, I'll also..." | Scope creep. Do what was asked, nothing more. |
| "Evidence isn't needed, I'm confident" | Confidence is not evidence. Verify. |
| "I'll just wire it up directly" | If a pattern exists for this, follow it. No shortcuts. |

Individual skills have additional skill-specific red flags beyond these universals.

## Progress Tracker Pattern

When a skill uses phase-based progress tracking:

1. **Create all phase tasks upfront** at the start of the skill using `TaskCreate`. Use the exact subjects the skill specifies — do not rename, renumber, or paraphrase them.
2. **Never recreate tasks.** Once all phase tasks are created, use `TaskUpdate` to change their status. If a task already exists for a phase, do not call `TaskCreate` for it again — this creates duplicates that clutter the tracker.
3. Mark each task `in_progress` when starting the phase, `completed` when done
4. If a phase is skipped, mark it `completed` and append "(skipped)" to the subject
5. If looping back to a phase, mark it `in_progress` again so the user sees current position

Do NOT create individual sub-tasks for items within a phase — the task tools don't support nesting. Track sub-progress via the phase task's `activeForm` and `subject` fields.

## Follow Architectural Intent

<HARD-GATE>
When a codebase has established patterns for how a type of feature or system is built, follow those patterns exactly. No shortcuts, no novel alternatives, no "just get it working" compromises.

**How to measure intent:** Compare code that follows a clear architectural pattern (consistent structure, proper separation, using the same abstractions as similar features) against code that was written to get something done quickly (coupling things together, skipping layers, avoiding nearby patterns that exist for a reason). The first is architectural intent. The second is a shortcut.

**The rule:**
- If similar features follow a pattern, new features of that type follow the same pattern
- If a system has clear layers or abstractions, new code uses those layers — it does not bypass them for convenience
- If nearby code demonstrates a convention (naming, structure, data flow), match it — don't invent a parallel convention
- When no clear pattern exists, build small composable systems with clear inputs/outputs rather than coupling directly to existing internals

**When uncertain:** If you can't tell whether a pattern is intentional architecture or accidental, investigate before deciding. Look at multiple examples across the codebase. "I think this is just how it ended up" is not evidence — check.
</HARD-GATE>

## Plugin-Wide Principles

These principles apply across all oven skills:

- **YAGNI** — Don't build for hypothetical future needs. Cut scope before it creeps. If a feature isn't needed now, don't add it.
- **DRY** — If two tasks or components would produce similar logic, extract it into a shared utility. Flag existing duplication that new work could consolidate. Never copy-paste code between files.
- **Evidence over assumptions** — "I think" means "I need to explore more." Don't guess when you can check.

## Menu File Naming

<HARD-GATE>
Menu files MUST end with `-menu.md` (e.g., `my-project-menu.md`).

This naming convention is what makes the `*-menu.md` glob pattern work for menu discovery. A stray name breaks the menu scanning system.
</HARD-GATE>

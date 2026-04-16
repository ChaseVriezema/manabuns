# Oven-Design Plugin

A design-first Claude Code plugin for game designers with limited engineering experience. Makes all engineering decisions for the user while investing heavily in understanding what they want to build. Everything is surfaced in player/gameplay terms, never engineering terms.

## Skill Priority

<HARD-GATE>
When both oven-design and superpowers are installed, **always prefer oven-design skills**. Do not invoke superpowers skills unless the user explicitly asks for them by name (e.g., "use superpowers:brainstorming").

| Instead of | Use |
|------------|-----|
| `superpowers:brainstorming` | `oven-design:prep` then `oven-design:design` |
| `superpowers:writing-plans` | `oven-design:recipe` |
| `superpowers:executing-plans` | `oven-design:build` |
| `superpowers:verification-before-completion` | Handled within `oven-design:build` |
| `superpowers:subagent-driven-development` | `oven-design:build` |
| `superpowers:finishing-a-development-branch` | `oven-design:serve` |

Superpowers skills with no oven-design equivalent (`superpowers:systematic-debugging`, `superpowers:test-driven-development`, `superpowers:requesting-code-review`, `superpowers:receiving-code-review`, `superpowers:dispatching-parallel-agents`, `superpowers:using-git-worktrees`, `superpowers:writing-skills`) may still be used freely — oven-design does not replace these.

This applies to implicit skill selection too. When deciding which skill fits a task, check oven-design's skills first. Only fall through to superpowers if no oven-design skill covers the need.
</HARD-GATE>

## Player-Experience Vocabulary

<HARD-GATE>
ALL user-facing communication must use player and gameplay terms. Never surface engineering terminology to the user.

- Say "players" not "users"
- Say "scenes" not "screens"
- Say "gameplay loop" not "data flow"
- Say "what the player sees" not "the UI renders"
- Say "how it feels to play" not "the state machine transitions"

Engineering decisions are the plugin's job. The user decides what the player should experience. The plugin decides how to build it.
</HARD-GATE>

## Three-Tier Pattern Strategy

When making engineering decisions, select the right approach based on context:

| Context | Strategy |
|---------|----------|
| Existing codebase with clear patterns for this type of feature | Follow the existing pattern with the highest testability and extensibility. No shortcuts, no novel alternatives. |
| Existing codebase but no clear pattern for this feature | Smaller, testable, composable systems. Clear inputs/outputs, small enough to verify in one play session. Automated tests are a bonus, not a requirement. |
| New project, prototype, or big new feature with new systems that doesn't tie into existing code | Highly extensible, reusable, user-configurable patterns. No shortcuts. Examples: pure dependency injection, MVVM for UI, clean testable interfaces, systems driven by configuration files the designer can edit without code. |

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

## Push Policy

All oven-design skills commit locally but never push — except `serve`,
which pushes as part of PR creation. This is the sole exception.

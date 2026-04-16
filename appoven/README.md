# Oven

A Claude Code plugin for structured development workflows — primarily targeting Unity/C# projects but applicable to any codebase.

## Plugins

This repo contains two plugins:

| Plugin | Path | Purpose |
|--------|------|---------|
| **oven** | `/` (repo root) | Full implementation pipeline — prep, recipe, cooking, review, and more |
| **oven-design** | `/oven-design` | Design-first prototyping for game designers — visual interviews, automatic engineering decisions, autonomous builds |

## Installation

```

```

## Skills

### oven (full pipeline)

| Skill | Description |
|-------|-------------|
| `oven:order` | Universal entry point — classifies and routes any task prompt |
| `oven:prep` | Deep-dive the codebase, design architecture, produce a complete design ready for recipe |
| `oven:recipe` | Turn a design into a detailed implementation plan |
| `oven:cooking` | Execute a plan inline with food-critic review and single-agent plating |
| `oven:mise-en-place` | Define expected behavior before coding |
| `oven:proof` | Verify work before claiming done |
| `oven:taste` | Standalone code review outside the cooking pipeline |
| `oven:taste-response-guidelines` | Process external review feedback with rigor |
| `oven:plating` | Polish recently changed code for clarity and consistency |
| `oven:smoke-check` | Systematic debugging before proposing fixes |
| `oven:shop` | Map architecture, find structural flaws, big-picture exploration |
| `oven:menu` | Manage multi-plan projects with tracked progress |

### oven-design (design-first prototyping)

| Skill | Description |
|-------|-------------|
| `oven-design:prep` | Map what the game currently does — functionality overview for the user, architecture notes held internally |
| `oven-design:design` | Visual interview — one question at a time with ASCII wireframes, flow diagrams, and edge case walkthroughs |
| `oven-design:recipe` | Batched implementation plan with player experience summary, pattern references, and task sizing |
| `oven-design:build` | Autonomous batch execution with food-critic review and complexity escape valve |
| `oven-design:serve` | Push branch, create PR, and clean up handoff files when a feature is ready for review |


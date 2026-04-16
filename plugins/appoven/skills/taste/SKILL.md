---
name: taste
description: "Use when you need a code review outside of the cooking pipeline — before merge, after ad-hoc work, when stuck, or after a complex bug fix"
---

# Review

Dispatch a food-critic review agent outside of the cooking pipeline.

**This is NOT a replacement for cooking Phase 3.** Use this for standalone reviews when work wasn't done through cooking.

## When to Use

- Before merge to main (mandatory for non-trivial changes)
- After ad-hoc work that didn't go through cooking
- When stuck and wanting a fresh perspective
- After fixing a complex bug
- Before major refactoring (baseline check — review documents current state, not a diff of changes)

## When NOT to Use

- Inside cooking — Phase 3 handles review dispatch
- For trivial changes (typo fixes, single-line edits)

## How to Dispatch

1. **Get git SHAs for the review range:**

   Base SHA (`{BASE_SHA}`):
   ```bash
   git merge-base main HEAD
   ```
   Head SHA (`{HEAD_SHA}`):
   ```bash
   git rev-parse HEAD
   ```

2. **Dispatch the food-critic** using the standalone context block from `skills/cooking/food-critic-prompt.md`:

   - Agent type: general-purpose
   - Model: sonnet
   - Use the **Standalone Review (ad-hoc)** context block
   - Fill in: `{BASE_SHA}`, `{HEAD_SHA}`, `{DESCRIPTION}`, `{PLAN_OR_REQUIREMENTS}` (if no plan, use "No formal plan. Review for general quality.")
   - Include the full git diff in the prompt

3. **Wait for the review to complete.** Do not proceed with merge until you have the verdict.

## Acting on Feedback

After the food-critic returns, follow the **Review Triage Flow** in CLAUDE.md ("Food-Critic Severity Response > Review Triage Flow") exactly.

## What the Reviewer Gets

The food-critic receives the full review checklist (Correctness, Conventions, Code Org, Scope Discipline, Testing, Production Readiness) and returns structured findings with a PASS / NEEDS FIXES verdict. See `food-critic-prompt.md` for the complete template.

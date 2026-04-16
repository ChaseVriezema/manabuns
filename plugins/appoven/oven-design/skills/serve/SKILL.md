---
name: serve
description: "Use when the feature is ready for review — reads the handoff doc, pushes the branch, creates a PR, and removes the handoff file"
---

# Serve

## Overview

Turn the handoff document into a PR and clean up. This is the final step in the oven-design pipeline — it publishes the work and removes the internal tracking file.

**Core principle:** The handoff document has been maintained by every prior stage. Serve consumes it, formats a PR, and deletes it so it never lands on main.

**Announce at start:** "Let me get this served up for review."

## When to Use

- After `oven-design:build` completes successfully
- When the feature is ready for engineer review
- When the user wants to create a PR from their feature branch

**When NOT to use:**
- Mid-build — wait until build is done
- On main/master — you need a feature branch
- When there's uncommitted work — commit or stash first

## The Process

```
Step 1: Preflight (branch check, handoff doc exists, clean tree)
       ↓
Step 2: Read and format PR content from handoff doc
       ↓
Step 3: Confirm with user (show PR title + body preview)
       ↓
Step 4: Push branch to origin
       ↓
Step 5: Create PR via gh
       ↓
Step 6: Delete handoff doc, commit deletion
       ↓
Step 7: Push the deletion commit
       ↓
Step 8: Report PR URL to user
```

───────────────────────────────────────────────────────────────
### Step 1: Preflight
───────────────────────────────────────────────────────────────

Run these checks before anything else:

1. **Branch check:** `git branch --show-current`
   - On `main` or `master` → use `AskUserQuestion`:
     - Question: "You're on `{branch}` — serve needs a feature branch. What would you like to do?"
     - Suggestions: "Create a new branch" (tab to name it) / "Switch to existing branch" (tab to name it) / "Cancel"
     - If creating/switching: execute the branch change, then continue preflight
     - If cancel: stop the skill

2. **Handoff doc check:** Read `.oven/HANDOFF.md`
   - If the file does not exist → use `AskUserQuestion`:
     - Question: "No handoff doc found. What would you like to do?"
     - Suggestions: "Create PR with manual description" (tab to provide it) / "Cancel"
   - If it exists, proceed.

3. **Clean working tree:** `git status`
   - Uncommitted changes → use `AskUserQuestion`:
     - Question: "There are uncommitted changes. How should I handle them?"
     - Suggestions: "Commit them" (tab to add a message) / "Stash them" / "Cancel"
     - Execute the chosen action, then continue preflight

4. **Existing PR check:** `gh pr list --head <branch-name> --state open`
   - PR already exists → use `AskUserQuestion`:
     - Question: "PR #{number} already exists for this branch. Update its description instead of creating a new one?"
     - Suggestions: "Yes, update it" / "Cancel"

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 2: Format PR Content
───────────────────────────────────────────────────────────────

Read `.oven/HANDOFF.md` and assemble the PR body from the handoff sections:

**PR title:** Use the **Feature** line from the handoff header.

**PR body format:**

```markdown
## What this builds

[Done Criteria from DESIGN section]

## How it plays

[Player Flow diagram from DESIGN section]

## Design decisions

[Key edge case rulings from DESIGN section]

## What changed

[Batches completed from BUILD section]
[Deviations, if any]

## Review notes

[Food-critic verdict from BUILD section]
```

**Rules:**
- Pull content directly from handoff sections using the sentinel comments to locate each section
- If a section is empty or missing, omit that PR body section rather than showing placeholders
- Keep player-experience vocabulary — the PR is for the engineer but the context is valuable

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 3: User Confirmation
───────────────────────────────────────────────────────────────

Present the PR title and body preview to the user before publishing.

"Here's the PR I'll create — take a look and let me know if you'd like to adjust anything."

Show:
- PR title
- Full PR body

Wait for user confirmation before proceeding. If they request changes, revise and re-present.

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 4: Push Branch
───────────────────────────────────────────────────────────────

<HARD-GATE>
Serve is the ONLY oven-design skill permitted to push. This is explicitly allowed because the user invoked serve specifically to publish a PR, which requires pushing the branch.
</HARD-GATE>

Push the branch to origin:

```
git push -u origin <branch-name>
```

If the push fails (e.g., remote rejection, auth issue), surface the error to the user and stop.

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 5: Create PR
───────────────────────────────────────────────────────────────

Create the PR using `gh`:

```
gh pr create --title "<title>" --body "<body>" --base main
```

Use a heredoc for the body to preserve formatting.

**If updating an existing PR** (detected in Step 1):

```
gh pr edit <pr-number> --body "<body>"
```

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 6: Delete Handoff Doc
───────────────────────────────────────────────────────────────

Remove the handoff document so it never lands on main:

1. `git rm .oven/HANDOFF.md`
2. Commit: `git commit -m "oven: remove handoff doc after PR creation"`

If `.oven/` is empty after removal, leave it — git handles empty directory cleanup automatically.

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 7: Push Deletion
───────────────────────────────────────────────────────────────

Push the deletion commit:

```
git push
```

· · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·

───────────────────────────────────────────────────────────────
### Step 8: Report
───────────────────────────────────────────────────────────────

Present the PR URL to the user:

"Your PR is live — [PR URL]. The handoff doc has been cleaned up so it won't land on main."

## Red Flags — STOP

| Thought | Reality |
|---------|---------|
| "I'll push without asking" | Always confirm the PR content with the user first. |
| "I'll leave the handoff doc for later" | Delete it now. It should never land on main. |
| "I'll skip the existing PR check" | Duplicate PRs waste reviewer time. Always check. |
| "The tree is dirty but I'll push anyway" | Clean tree required. Ask the user to commit or stash. |
| "I'll create the PR on main" | Serve requires a feature branch. Stop if on main. |

## Key Principles

- **Preflight everything** — branch, handoff doc, clean tree, existing PRs
- **User confirms before publish** — show the PR content, wait for approval
- **Only skill that pushes** — explicit exception to the no-push rule
- **Clean up after yourself** — delete handoff doc, push the deletion
- **Graceful fallbacks** — no handoff doc? offer manual description. Existing PR? offer update.

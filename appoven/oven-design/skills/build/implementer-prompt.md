# Batch Implementer Agent Prompt Template

Use this template when dispatching an implementer agent for a batch.

```
Agent tool (general-purpose):
  description: "Implement Batch N: [batch summary]"
  model: sonnet
  prompt: |
    You are implementing Batch N: [batch summary]

    You are working directly on the current feature branch. Commit your
    work when all tasks in this batch are done.

    ## Batch Tasks

    [FULL TEXT of ALL tasks in this batch — paste them, don't make the
    agent read a file. Include size, files, expected behavior, implementation
    spec, and verification for each task.]

    ## Pattern Reference

    [The Pattern Reference section from the recipe — three-tier strategy,
    existing patterns, key files, conventions, where new code goes]

    ## Context

    [Scene-setting: which batches came before, what they built, how this
    batch connects to prior work]

    ## Your Job

    Implement all tasks in this batch sequentially:

    1. For each task:
       a. Read the implementation spec and pattern reference
       b. Read the actual source files you'll be working with
       c. Implement the task, adapting the recipe's blueprint to the actual
          codebase state — resolve imports, match local conventions, integrate
          with existing code
       d. Verify the task works using the specified verification method

    2. After all tasks are implemented:
       a. Self-review the entire batch (see below)
       b. Commit all work in a SINGLE commit with a descriptive message
       c. Do NOT push — only commit locally
       d. Report back

    ## Code Organization

    - Follow the Pattern Reference — use the patterns it specifies
    - Each file should have one clear responsibility
    - If a file you're creating grows beyond the plan's intent, STOP and
      report as DONE_WITH_CONCERNS
    - Follow established patterns in the codebase. Improve code you're
      touching, but don't restructure things outside your batch scope.

    ## When You're in Over Your Head

    It is always OK to stop and say "this is too hard." Bad work is worse
    than no work.

    STOP and escalate when:
    - A task requires architectural decisions the plan didn't anticipate
    - You need to understand code beyond what was provided
    - You feel uncertain about your approach
    - The task involves restructuring existing code unexpectedly
    - Following the specified pattern isn't feasible

    How to escalate: Report back with status BLOCKED or NEEDS_CONTEXT.
    Describe specifically what you're stuck on, what you've tried, and
    what help you need.

    ## Self-Review (Report Only — Do NOT Fix)

    After completing all tasks, review your work with fresh eyes. For each
    concern, add it to your report — do NOT fix it yourself.

    Check:

    Completeness:
    - Did you implement everything in all tasks?
    - Requirements missed? Edge cases unhandled?

    Quality:
    - Names clear and accurate?
    - Code clean and maintainable?

    Pattern Adherence:
    - Did you follow the three-tier strategy from the Pattern Reference?
    - Does your code match existing patterns in the codebase?

    Discipline:
    - YAGNI — only built what was requested?
    - DRY — no duplicated logic? Similar code extracted to shared utility?
    - Followed plan's file boundaries?

    Verification:
    - Did you verify each task using its specified method?

    ## Report Format

    When done, report:
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - **Tasks implemented:** [list each with brief description of what was done]
    - **Verification results:** [what you tested and outcomes]
    - **Files changed:** [list]
    - **Commit:** [commit hash and message]
    - **Self-review concerns:** [list each with file:line and description, or "None"]

    Use DONE_WITH_CONCERNS if you completed the work but have doubts.
    Use BLOCKED if you cannot complete the batch.
    Use NEEDS_CONTEXT if you need information that wasn't provided.
```

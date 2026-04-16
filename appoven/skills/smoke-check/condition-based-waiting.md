# Condition-Based Waiting

## Overview

Flaky tests often guess at timing with arbitrary delays. This creates race conditions where tests pass on fast machines but fail under load or in CI.

**Core principle:** Wait for the actual condition you care about, not a guess about how long it takes.

## When to Use

**Use when:**
- Tests have arbitrary waits (`yield return new WaitForSeconds()`, `await UniTask.Delay()`)
- Tests are flaky (pass sometimes, fail under load)
- Tests timeout when run in parallel
- Waiting for async operations, scene loads, or state transitions to complete

**Don't use when:**
- Testing actual timing behavior (animation durations, cooldowns, scheduled events)
- Always document WHY if using an arbitrary timeout

## Core Patterns

### Coroutines

```csharp
// BAD: Guessing at timing
yield return new WaitForSeconds(0.5f);
Assert.IsTrue(manager.IsReady);

// GOOD: Waiting for condition
yield return new WaitUntil(() => manager.IsReady);
Assert.IsTrue(manager.IsReady);
```

### UniTask

```csharp
// BAD: Guessing at timing
await UniTask.Delay(500);
Assert.IsTrue(manager.IsReady);

// GOOD: Waiting for condition
await UniTask.WaitUntil(() => manager.IsReady);
Assert.IsTrue(manager.IsReady);
```

### With Timeout (prevent infinite waits)

```csharp
// Coroutine with timeout
yield return WaitForCondition(() => manager.IsReady, timeout: 5f, "manager to be ready");

// UniTask with cancellation timeout
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
await UniTask.WaitUntil(() => manager.IsReady, cancellationToken: cts.Token);
```

## Quick Patterns

| Scenario | Pattern |
|----------|---------|
| Wait for state | `yield return new WaitUntil(() => fsm.CurrentState == State.Ready)` |
| Wait for scene load | `yield return new WaitUntil(() => SceneManager.GetActiveScene().name == "GameScene")` |
| Wait for component | `yield return new WaitUntil(() => FindObjectOfType<GameManager>() != null)` |
| Wait for count | `yield return new WaitUntil(() => inventory.Items.Count >= 5)` |
| Wait for event fired | `yield return new WaitUntil(() => eventFired)` |
| Complex condition | `yield return new WaitUntil(() => player.IsAlive && level.IsLoaded)` |

## Helper Implementation

Generic condition waiter with timeout and error messages:

```csharp
/// <summary>
/// Waits for a condition to be true, with timeout and descriptive error.
/// Use in PlayMode tests or coroutines.
/// </summary>
public static IEnumerator WaitForCondition(
    Func<bool> condition,
    float timeout = 5f,
    string description = "condition")
{
    float elapsed = 0f;
    while (!condition())
    {
        elapsed += Time.deltaTime;
        if (elapsed > timeout)
        {
            throw new TimeoutException(
                $"Timeout waiting for {description} after {timeout}s");
        }
        yield return null; // Wait one frame
    }
}

// Usage in PlayMode test:
[UnityTest]
public IEnumerator BoardInitializes()
{
    var board = CreateBoard();
    board.Initialize(config);

    yield return WaitForCondition(
        () => board.State == BoardState.Ready,
        timeout: 3f,
        description: "board to reach Ready state");

    Assert.AreEqual(BoardState.Ready, board.State);
}
```

### UniTask Version

```csharp
/// <summary>
/// Waits for a condition with timeout. Throws on timeout with descriptive message.
/// </summary>
public static async UniTask WaitForConditionAsync(
    Func<bool> condition,
    float timeout = 5f,
    string description = "condition",
    CancellationToken ct = default)
{
    using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
    cts.CancelAfter(TimeSpan.FromSeconds(timeout));

    try
    {
        await UniTask.WaitUntil(condition, cancellationToken: cts.Token);
    }
    catch (OperationCanceledException) when (!ct.IsCancellationRequested)
    {
        throw new TimeoutException(
            $"Timeout waiting for {description} after {timeout}s");
    }
}
```

## Common Mistakes

**Bad: No timeout** -- loop forever if condition never met
**Fix:** Always include timeout with clear error message

**Bad: Polling every frame in Update()** for test assertions
**Fix:** Use `WaitUntil` or the helpers above -- they handle the loop

**Bad: Caching state before the wait loop**
**Fix:** Always evaluate the condition fresh each check (lambda captures handle this)

**Bad: `WaitForSeconds` then assert** (most common flaky test pattern)
**Fix:** `WaitUntil(() => condition)` then assert

## When Arbitrary Timeout IS Correct

```csharp
// Animation plays for exactly 0.5s -- need to verify mid-animation state
yield return new WaitUntil(() => animator.GetCurrentAnimatorStateInfo(0).IsName("Attack"));
yield return new WaitForSeconds(0.25f); // Half of known 0.5s animation
// Check mid-animation state -- this timing is documented and intentional
```

**Requirements:**
1. First wait for triggering condition
2. Based on known timing (not guessing)
3. Comment explaining WHY

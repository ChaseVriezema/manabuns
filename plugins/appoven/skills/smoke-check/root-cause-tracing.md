# Root Cause Tracing

## Overview

Bugs often manifest deep in the call stack (wrong scene loaded, null reference in a handler, file created in wrong location). Your instinct is to fix where the error appears, but that's treating a symptom.

**Core principle:** Trace backward through the call chain until you find the original trigger, then fix at the source.

## When to Use

**Use when:**
- Error happens deep in execution (not at entry point)
- Stack trace shows long call chain
- Unclear where invalid data originated
- Need to find which test/code triggers the problem

## The Tracing Process

### 1. Observe the Symptom
```
NullReferenceException: Object reference not set to an instance of an object
  at GameManager.StartRound () in Assets/Scripts/GameManager.cs:47
```

### 2. Find Immediate Cause
**What code directly causes this?**
```csharp
// GameManager.cs:47
_currentPuzzle.Initialize(config);  // _currentPuzzle is null
```

### 3. Ask: What Called This?
```
GameManager.StartRound()          // _currentPuzzle is null here
  <- GameManager.OnStateChanged() // called when state transitions
  <- GameState.TransitionTo()     // triggers state change
  <- LevelLoader.LoadLevel()      // initiates the transition
```

### 4. Keep Tracing Up
**What value was passed?**
- `_currentPuzzle` was supposed to be set in `PrepareRound()`
- `PrepareRound()` was never called -- `LoadLevel()` skipped it
- The skip happens because `isReady` was already `true` from a previous round

### 5. Find Original Trigger
**Where did the stale state come from?**
```csharp
// LevelLoader.cs
public void LoadLevel(int level)
{
    if (isReady) return;  // BUG: isReady never reset between rounds
    PrepareRound();
    isReady = true;
}
```

## Adding Stack Traces

When you can't trace manually, add instrumentation:

```csharp
// Before the problematic operation
public void StartRound()
{
    Debug.Log($"[TRACE] StartRound called. _currentPuzzle: {_currentPuzzle}" +
              $"\nCaller: {new System.Diagnostics.StackTrace()}");

    _currentPuzzle.Initialize(config);
}
```

**In Unity tests use `Debug.Log()`** -- it shows in the Test Runner output.

**Run and check console:**
- Look for the trace output
- Find the line number triggering the call
- Identify the pattern (same caller? same parameter?)

## Finding Which Test Causes Pollution

If something appears during tests but you don't know which test:

Use the bisection script `find-polluter.sh` in this directory:

```bash
./find-polluter.sh '.git' 'src/**/*.test.ts'
```

Runs tests one-by-one, stops at first polluter. See script for usage.

For **Unity PlayMode/EditMode tests**, you can isolate similarly by running test classes individually through the Test Runner until you find the polluter.

## Real Example: Stale State Between Rounds

**Symptom:** `NullReferenceException` in `StartRound()` on round 2+

**Trace chain:**
1. `_currentPuzzle.Initialize()` -- null reference
2. `StartRound()` called without `PrepareRound()`
3. `LoadLevel()` early-returned because `isReady == true`
4. `isReady` was set in round 1, never reset

**Root cause:** Missing state reset between rounds

**Fix:** Reset `isReady` in `CleanupRound()` or at start of `LoadLevel()`

**Also added defense-in-depth:**
- Layer 1: `LoadLevel()` always resets `isReady` at entry
- Layer 2: `StartRound()` validates `_currentPuzzle != null` with clear error
- Layer 3: EditMode test verifies multi-round lifecycle

## Key Principle

**NEVER fix just where the error appears.** Trace back to find the original trigger.

## Stack Trace Tips

**In Unity:** `Debug.Log()` with `new System.Diagnostics.StackTrace()` for full call chain
**Before operation:** Log before the dangerous operation, not after it fails
**Include context:** GameObject name, scene, state values, frame count
**Editor vs Runtime:** Check if the issue only happens in one context

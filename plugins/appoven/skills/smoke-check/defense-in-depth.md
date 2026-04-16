# Defense-in-Depth Validation

## Overview

When you fix a bug caused by invalid data, adding validation at one place feels sufficient. But that single check can be bypassed by different code paths, refactoring, or test mocks.

**Core principle:** Validate at EVERY layer data passes through. Make the bug structurally impossible.

## Why Multiple Layers

Single validation: "We fixed the bug"
Multiple layers: "We made the bug impossible"

Different layers catch different cases:
- Entry validation catches most bugs
- Business logic catches edge cases
- Environment guards prevent context-specific dangers
- Debug logging helps when other layers fail

## The Four Layers

### Layer 1: Entry Point Validation
**Purpose:** Reject obviously invalid input at API boundary

```csharp
public void LoadPuzzle(string puzzleId, PuzzleConfig config)
{
    if (string.IsNullOrEmpty(puzzleId))
        throw new ArgumentException("puzzleId cannot be null or empty");
    if (config == null)
        throw new ArgumentNullException(nameof(config));
    if (config.GridSize <= 0)
        throw new ArgumentOutOfRangeException(nameof(config.GridSize));
    // ... proceed
}
```

### Layer 2: Business Logic Validation
**Purpose:** Ensure data makes sense for this operation

```csharp
public void StartRound(PuzzleData puzzle)
{
    if (puzzle == null)
        throw new InvalidOperationException(
            "Cannot start round without puzzle data. Was PrepareRound() called?");
    if (_state != GameState.Ready)
        throw new InvalidOperationException(
            $"Cannot start round in state {_state}. Expected Ready.");
    // ... proceed
}
```

### Layer 3: Environment Guards
**Purpose:** Prevent dangerous operations in specific contexts

```csharp
public void ResetPlayerProgress()
{
    // In editor, warn before wiping save data
    #if UNITY_EDITOR
    if (!Application.isPlaying)
    {
        Debug.LogError("ResetPlayerProgress called outside Play mode -- refusing");
        return;
    }
    #endif
    // ... proceed
}
```

### Layer 4: Debug Instrumentation
**Purpose:** Capture context for forensics

```csharp
public void InitializeBoard(BoardConfig config)
{
    Debug.Log($"[Board] InitializeBoard called:" +
              $"\n  config: {config}" +
              $"\n  scene: {SceneManager.GetActiveScene().name}" +
              $"\n  frame: {Time.frameCount}" +
              $"\n  caller: {new System.Diagnostics.StackTrace()}");
    // ... proceed
}
```

## Applying the Pattern

When you find a bug:

1. **Trace the data flow** -- Where does bad value originate? Where used?
2. **Map all checkpoints** -- List every point data passes through
3. **Add validation at each layer** -- Entry, business, environment, debug
4. **Test each layer** -- Try to bypass layer 1, verify layer 2 catches it

## Key Insight

All four layers are often necessary. During testing, each layer catches bugs the others miss:
- Different code paths bypass entry validation
- Mocks bypass business logic checks
- Editor vs runtime needs environment guards
- Debug logging identifies structural misuse patterns

**Don't stop at one validation point.** Add checks at every layer.

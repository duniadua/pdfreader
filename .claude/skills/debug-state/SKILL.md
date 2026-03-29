# Debug State Issues

Systematically debug state-related problems in Flutter/Dart applications using a proven pattern.

## Workflow

### Phase 1: Identify All Initialization Points

1. **Search for duplicate initialization calls**
   - Grep for all instances of `.build()` methods in notifiers/providers
   - Grep for `setState` calls to find state mutation points
   - Check constructor chains for multiple initialization paths

2. **Check component lifecycle timing**
   - Verify widgets aren't being remounted unexpectedly
   - Look for `initState` or `build` methods being called multiple times
   - Check for provider dependencies that trigger rebuilds

### Phase 2: Trace State Mutations

3. **Map state flow**
   - Start from state initialization (usually `build()` method in notifiers)
   - Trace all paths that modify the state
   - Identify where state gets reset or overwritten

4. **Add diagnostic logging** (if needed)
   - Add console.log or AppLogger calls at state mutation points
   - Log entry/exit of initialization methods
   - Track component mount/unmount cycles

### Phase 3: Verify Root Cause

5. **Confirm the fix**
   - After identifying the issue, implement the fix
   - Run `flutter analyze` to ensure no analyzer errors
   - Test the specific scenario that was failing
   - Verify state persists correctly across lifecycle events

## Common Patterns

### Double-Initialization Bug
Symptoms: State resets unexpectedly, data disappears on rebuild

**Check for:**
- Provider `build()` methods called multiple times
- Widgets being recreated instead of updated
- Missing `const` constructors causing rebuilds

### Race Condition
Symptoms: Intermittent state corruption, timing-dependent failures

**Check for:**
- Async operations without proper await
- Multiple concurrent state updates
- Missing loading state flags

### State Not Persisting
Symptoms: Changes lost on navigation or rebuild

**Check for:**
- Missing Hive persistence calls
- State updates not saved to storage
- Incorrect notifyListeners usage

## Example Usage

```
User: /debug-state
Claude: I'll help debug the state issue. Let me start by searching for initialization points...

[Searches for .build() methods, traces state flow, identifies root cause]
```

## Context

Based on debugging patterns from this codebase where state reset issues were caused by:
- PdfChatNotifier.build() being called twice
- Component lifecycle timing problems
- Missing state persistence after mutations

## Success Criteria

- [ ] Root cause identified and documented
- [ ] Fix implemented and tested
- [ ] No analyzer errors (`flutter analyze` passes)
- [ ] State persists correctly across lifecycle events
- [ ] Specific failing scenario now works

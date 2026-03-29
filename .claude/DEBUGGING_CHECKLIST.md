# Debugging Session Checklist

Use this checklist to ensure complete debugging cycles and avoid session fragmentation.

## Pre-Session Planning

- [ ] **State the problem clearly** - What specifically is broken? What should happen vs. what actually happens?
- [ ] **Set success criteria** - What does "fixed" look like? How will we verify it works?
- [ ] **Estimate complexity** - Is this a quick fix (<15 min) or complex issue (>1 hour)?

## During Debugging

- [ ] **Run `/debug-state` skill** - Let Claude systematically trace the issue
- [ ] **Verify analyzer passes** - Run `flutter analyze` to catch any type errors
- [ ] **Test the fix** - Actually run the app and verify the bug is resolved
- [ ] **Check for regressions** - Did the fix break anything else?

## Before Considering It "Done"

- [ ] **Root cause identified** - Not just symptom patched, but actual cause found
- [ ] **Fix implemented** - Code changes applied and committed
- [ ] **Tests pass** - `flutter test` shows all tests passing
- [ ] **Manual verification** - You tested it yourself and confirmed it works
- [ ] **No analyzer errors** - `flutter analyze` shows zero issues
- [ ] **Edge cases covered** - Considered null inputs, empty lists, error states

## Session Completion

- [ ] **Document the fix** - Add a brief comment explaining WHY the bug occurred
- [ ] **Commit with clear message** - Use conventional commit format: `fix(scope): description`
- [ ] **Update checklist if needed** - If this is a recurring pattern, add to debugging skill

## Quick Reference Commands

```bash
# Run all checks in one go
flutter test && flutter analyze && dart format . && echo "✅ Ready to commit!"

# Common debugging workflow
/flutter-state  # Use the debug-state skill
git status      # Check what changed
flutter run     # Test the fix
```

## Common Anti-Patterns to Avoid

❌ **Don't**: Exit session after identifying root cause without implementing fix
❌ **Don't**: Apply fix without testing it actually works
❌ **Don't**: Commit without running `flutter analyze`
❌ **Don't**: Mark as "done" without manual verification

✅ **Do**: Stay in session until fix is verified working
✅ **Do**: Run full test suite before committing
✅ **Do**: Add comments explaining non-obvious bugs
✅ **Do**: Update documentation if this was a tricky issue

---

## Template for New Debugging Sessions

Copy this when starting a new debugging task:

```
## Debugging: [Brief description]

**Problem**: [What's broken?]

**Expected**: [What should happen?]

**Actual**: [What actually happens?]

**Success Criteria**: [How will we know it's fixed?]

- [ ] Run /debug-state
- [ ] Identify root cause
- [ ] Implement fix
- [ ] Run `flutter analyze`
- [ ] Test manually
- [ ] Run `flutter test`
- [ ] Commit with conventional message
- [ ] Verify fix deployed/staged
```

---

## Insights from Past Sessions

**Pattern 1: Double-Initialization Bug**
- **Symptom**: State resets unexpectedly, data disappears on rebuild
- **Root Cause**: Provider `build()` methods called multiple times
- **Fix**: Check for duplicate provider initialization, add singleton patterns
- **Reference**: PdfChatNotifier.build() being called twice

**Pattern 2: Race Conditions**
- **Symptom**: Intermittent state corruption, timing-dependent failures
- **Root Cause**: Multiple concurrent state updates without proper synchronization
- **Fix**: Add loading flags, use async/await properly, mutex locks if needed

**Pattern 3: Missing Persistence**
- **Symptom**: Changes lost on navigation or rebuild
- **Root Cause**: State updates not saved to Hive/storage
- **Fix**: Ensure all state mutations call repository save methods

---

Last updated: 2025-03-28
Based on insights from 4 sessions analyzing state debugging patterns

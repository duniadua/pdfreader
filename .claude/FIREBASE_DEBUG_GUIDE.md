# Firebase Debugging Quick Reference

## Using the Firebase Debug Script

The helper script at `.claude/scripts/firebase-debug.sh` provides quick access to common Firebase debugging operations.

### Available Commands

```bash
# View recent function logs (for debugging AI chat issues)
./.claude/scripts/firebase-debug.sh logs

# Check specific chat session state
./.claude/scripts/firebase-debug.sh state <session_id>

# List all deployed functions
./.claude/scripts/firebase-debug.sh functions

# Test authentication
./.claude/scripts/firebase-debug.sh test-auth

# Export chat sessions for analysis
./.claude/scripts/firebase-debug.sh export-data

# Overall health check
./.claude/scripts/firebase-debug.sh check-health
```

## Using in Claude Sessions

### Example 1: Debugging State Reset Issue

```
User: My chat sessions are losing state. Help me debug.
Claude: Let me check the Firebase Functions logs for errors.
[Runs: ./.claude/scripts/firebase-debug.sh logs]
[Runs: ./.claude/scripts/firebase-debug.sh check-health]
```

### Example 2: Investigating Specific Session

```
User: Chat session abc123 isn't loading messages.
Claude: Let me check the Firestore state for that session.
[Runs: ./.claude/scripts/firebase-debug.sh state abc123]
```

### Example 3: After Code Changes

```
User: I just updated the Genkit flow. Let me verify it works.
Claude: I'll check the function logs for any errors.
[Runs: ./.claude/scripts/firebase-debug.sh logs]
```

## Direct Firebase CLI Commands

For more advanced debugging, use Firebase CLI directly in Claude sessions:

```bash
# Real-time log monitoring
firebase functions:log --only chatGenkit

# Check specific function
firebase functions:log --limit 100

# View Firestore data
firebase firestore:get chatSessions/<id>

# Test function locally
firebase functions:shell
```

## Common Debugging Scenarios

### Scenario: Chat Messages Not Saving

**Symptoms**: Messages appear in UI but disappear on refresh

**Debugging steps**:
1. Check function logs: `./.claude/scripts/firebase-debug.sh logs`
2. Look for "saveMessage" or "chatGenkit" function errors
3. Verify Firestore writes: `./.claude/scripts/firebase-debug.sh state <session_id>`
4. Check for quota/rate limiting issues

**Common causes**:
- Firestore permission denied
- Missing or invalid session ID
- Function timeout (>60 seconds for Genkit)
- Malformed request data

### Scenario: AI Responses Not Generated

**Symptoms**: User message saved, but no AI response

**Debugging steps**:
1. Check logs for Genkit API errors
2. Verify API key is configured
3. Check function execution time (may be timing out)
4. Test Genkit flow locally: `firebase functions:shell`

**Common causes**:
- Invalid or missing Genkit API key
- Model quota exceeded
- Function cold start delay
- Malformed prompt or context

### Scenario: Authentication Failures

**Symptoms**: Users can't sign in or session invalid

**Debugging steps**:
1. Check auth status: `./.claude/scripts/firebase-debug.sh test-auth`
2. Verify Firebase Auth configuration
3. Check for CORS issues
4. Review auth token refresh logic

## Integration with Debugging Workflow

Combine Firebase debugging with your other automation tools:

1. **Run `/debug-state`** - Systematic Flutter/Dart investigation
2. **Check Firebase logs** - `./.claude/scripts/firebase-debug.sh logs`
3. **Verify analyzer passes** - Automatic via PostToolUse hook
4. **Test fix manually** - Run app and verify
5. **Use pre-session checklist** - Ensure completion

## Performance Monitoring

```bash
# Check function execution times
firebase functions:log | grep "Duration"

# Monitor cold starts
firebase functions:log | grep "cold start"

# Check memory usage
firebase functions:log | grep "memory"
```

## Export and Analysis

```bash
# Export chat sessions for state pattern analysis
./.claude/scripts/firebase-debug.sh export-data

# Analyze exported data
cat firebase_debug_export_*/chat_sessions.json | jq '.documents[] | select(.fields.state)'

# Look for state reset patterns
cat firebase_debug_export_*/chat_sessions.json | jq '.documents[] | .fields'
```

## Tips for Effective Debugging

1. **Always check logs first** - Most issues show up in function logs
2. **Use health check** - Quick overview before deep diving
3. **Export data** - Useful for finding patterns in state issues
4. **Combine with Flutter debugging** - Use `/debug-state` for client-side issues
5. **Document findings** - Add patterns to CLAUDE.md as you discover them

## Troubleshooting the Script

If the script doesn't work:

```bash
# Check Firebase CLI is installed
firebase --version

# Verify you're logged in
firebase login:list

# Check script permissions
ls -la .claude/scripts/firebase-debug.sh

# Make sure project is initialized
ls -la firebase.json
```

---

Last updated: 2025-03-28
Integrates with: /debug-state skill, PostToolUse hook, pre-session checklist

---
name: firebase-deploy
description: Deploy Firebase functions with comprehensive pre-deployment checks and safety measures
---

# Firebase Deployment Skill

Deploy Firebase Cloud Functions safely with comprehensive pre-deployment checks, verification, and rollback capabilities.

## Prerequisites

- Firebase project initialized
- `firebase-tools` installed (`npm install -g firebase-tools`)
- TypeScript configured in functions/
- User logged into Firebase (`firebase login`)

## Pre-Deployment Checklist

Before deploying, this skill verifies:

- ✅ Working directory is clean (no uncommitted changes)
- ✅ TypeScript compilation succeeds (`tsc --noEmit`)
- ✅ All unit tests pass (`npm test`)
- ✅ Code is properly formatted
- ✅ No critical linting errors
- ✅ Dependencies are up to date
- ✅ Build output exists and is valid
- ✅ Firebase project is accessible

## Steps

### Phase 1: Pre-Deployment Checks

1. **Verify working directory state**
   ```bash
   git status --porcelain
   ```
   - Warn if there are uncommitted changes
   - Ask for confirmation to proceed

2. **Check Firebase login status**
   ```bash
   firebase login --list
   ```
   - Verify user is logged in
   - Show target project

3. **Run TypeScript compilation check**
   ```bash
   cd functions && npx tsc --noEmit
   ```
   - Fails fast on type errors
   - Shows specific error location

4. **Run test suite**
   ```bash
   cd functions && npm test -- --coverage
   ```
   - Ensures all tests pass
   - Shows coverage report
   - Fails if any test fails

5. **Check code formatting**
   ```bash
   cd functions && npx prettier --check "**/*.{ts,js,json}"
   ```
   - Warns on formatting issues
   - Offers to auto-fix

6. **Run linter (if configured)**
   ```bash
   cd functions && npm run lint 2>/dev/null || npx eslint . --ext .ts
   ```
   - Checks for code quality issues
   - Shows warnings and errors

7. **Check dependencies**
   ```bash
   cd functions && npm outdated
   ```
   - Shows outdated packages
   - Warns about security vulnerabilities

8. **Build functions**
   ```bash
   cd functions && npm run build
   ```
   - Compiles TypeScript to JavaScript
   - Verifies build output exists
   - Shows build size

### Phase 2: Deployment

9. **Show deployment summary**
   - List functions to be deployed
   - Show target Firebase project
   - Estimate deployment time

10. **Request user confirmation**
    - Show "About to deploy..." message
    - Require explicit "yes" confirmation

11. **Deploy to Firebase**
    ```bash
    firebase deploy --only functions
    ```
    - Deploys all functions
    - Shows deployment progress
    - Captures deployment URL

### Phase 3: Post-Deployment Verification

12. **Verify deployment success**
    - Check deployment exit code
    - Show function URLs
    - List deployed functions

13. **Run smoke tests (if available)**
    ```bash
    npm run test:smoke 2>/dev/null || echo "No smoke tests configured"
    ```
    - Tests basic functionality
    - Verifies functions are accessible

14. **Show deployment summary**
    - Deployment status (success/failed)
    - Function URLs
    - Next steps

## Error Handling

If any step fails:
1. **Stop deployment immediately** - Do not proceed to next step
2. **Show specific error message** - Include error output
3. **Suggest fix** - Provide actionable solution
4. **Offer options**:
   - Fix and retry
   - Skip this check (risky)
   - Cancel deployment

## Rollback Plan

If deployment fails:
- **Previous functions remain active** - Firebase does atomic deployments
- **Show error logs** - Display deployment errors
- **Offer options**:
  - Retry deployment
  - Rollback to previous version
  - Abort and investigate

## Additional Safety Steps (Optional)

These steps can be added for extra safety:

1. **Run integration tests**
   ```bash
   npm run test:integration
   ```
   - Tests against staging environment
   - Verifies end-to-end functionality

2. **Check environment variables**
   ```bash
   firebase functions:config:get
   ```
   - Verifies required config exists
   - Warns about missing config

3. **Backup current deployment**
   ```bash
   firebase deploy --only functions --force 2>/dev/null || true
   ```
   - Keep record of current version
   - Enable quick rollback

4. **Notify team (Slack/Email)**
   - Send deployment notification
   - Include changelog
   - Provide rollback instructions

5. **Monitor error rates**
   - Check Firebase Console
   - Compare to baseline
   - Alert on anomalies

## Troubleshooting

### Common Issues

**TypeScript compilation fails**
- Check for type errors in output
- Fix reported issues
- Run `npm run build` to verify fix

**Tests fail**
- Run `npm test -- --verbose` for details
- Fix failing tests
- Consider `--bail` to stop on first failure

**Deployment fails**
- Check Firebase project access
- Verify `firebase-tools` version
- Check Firebase quota/limits

**Functions not accessible after deployment**
- Wait for cold start (first call can be slow)
- Check Firebase Console logs
- Verify region matches expectations

## Examples

### Quick deployment (development)
```bash
# Skip some checks for faster iteration
firebase deploy --only functions
```

### Full deployment (production)
```bash
# Run all checks before deploying
npm run deploy:prod  # Custom script that runs this skill
```

### Deploy single function
```bash
# Deploy only specific function
firebase deploy --only functions:summarizeFlow
```

## Related Commands

- `firebase logs --only functions` - View function logs
- `firebase functions:shell` - Test functions locally
- `firebase serve --only functions` - Serve functions locally

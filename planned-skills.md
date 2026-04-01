# Claude Code Skills Development Plan

## Executive Summary

Based on project history and workflow analysis, develop custom Claude Code skills to automate repetitive development tasks for the Flutter PDF Reader project with Firebase backend.

**Priority Skills to Create:**
1. **validate-build** - Pre-build validation (test + analyze + format)
2. **deploy-functions** - Firebase Functions deployment
3. **generate-code** - Code generation (build_runner)
4. **build-apk** - APK build automation
5. **run-tests** - Test execution with coverage

---

## Project Context

**Project**: Flutter PDF Reader with AI Chat
- Flutter 3.38.5 with Riverpod state management
- Firebase backend (Auth, Analytics, Cloud Functions)
- AI features with Google GenKit
- Clean Architecture pattern
- Strong testing culture (80%+ coverage required)

**Current Pain Points**:
- Manual multi-step pre-build validation
- Repetitive build_runner commands
- Complex Firebase deployment process
- Multiple APK build options to remember
- Time-consuming test execution workflows

---

## Skill Definitions

### 1. validate-build (High Priority)

**Purpose**: Automate mandatory pre-build checks to ensure code quality before building APK

**User Commands**:
- `/validate-build` or `/prebuild`
- `/validate-build --fix` (apply auto-fixes)

**What It Does**:
```bash
# 1. Run all tests
flutter test

# 2. Check for code issues
flutter analyze

# 3. Auto-fix issues (if --fix flag)
dart fix --apply

# 4. Format code
dart format .

# 5. Verify no issues remain
flutter analyze
```

**Implementation Approach**:
- Use Bash tool to run commands sequentially
- Stop if any step fails (especially tests)
- Provide clear feedback on each step
- Show summary at end (tests passed, issues found, files formatted)

**Error Handling**:
- Stop immediately if tests fail
- Show test failures with details
- Offer to run `dart fix --apply` if analyze finds issues

**Files to Create**:
- `.claude/skills/validate-build/skill.md`
- `.claude/skills/validate-build/skill.ts` (TypeScript implementation)

---

### 2. deploy-functions (High Priority)

**Purpose**: Deploy Firebase Functions with proper build and validation steps

**User Commands**:
- `/deploy-functions` or `/firebase-deploy`
- `/deploy-functions --test` (run tests first)

**What It Does**:
```bash
# 1. Change to functions directory
cd functions

# 2. Run tests (if --test flag)
npm test

# 3. Build TypeScript
npm run build

# 4. Deploy to Firebase
firebase deploy --only functions

# 5. Show deployment status
firebase functions:log --limit 5
```

**Implementation Approach**:
- Use Bash tool with directory changes
- Run Jest tests before deployment (optional)
- Handle deployment errors gracefully
- Show deployment summary (functions deployed, regions)

**Error Handling**:
- Stop if tests fail (when --test flag used)
- Handle TypeScript compilation errors
- Show Firebase deployment errors
- Offer to view logs if deployment fails

**Files to Create**:
- `.claude/skills/deploy-functions/skill.md`
- `.claude/skills/deploy-functions/skill.ts`

---

### 3. generate-code (Medium Priority)

**Purpose**: Run code generation for Riverpod and Freezed models

**User Commands**:
- `/generate-code` or `/build-runner`
- `/generate-code --delete-conflicts` (use --delete-conflicting-outputs flag)
- `/generate-code --watch` (use watch mode)

**What It Does**:
```bash
# 1. Check if build_runner is needed
# (detect changes in .g.dart files or model files)

# 2. Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# OR with --watch flag:
flutter pub run build_runner watch

# 3. Show summary (files generated, errors, warnings)
```

**Implementation Approach**:
- Check for model files (freezed, riverpod annotations)
- Run build_runner with appropriate flags
- Parse output for generated files
- Show summary of what was generated

**Error Handling**:
- Handle missing build_runner dependency
- Show generation errors clearly
- Offer to fix conflicts automatically

**Files to Create**:
- `.claude/skills/generate-code/skill.md`
- `.claude/skills/generate-code/skill.ts`

---

### 4. build-apk (Medium Priority)

**Purpose**: Build APK with sensible defaults and options

**User Commands**:
- `/build-apk` (debug build, arm64 only - fastest)
- `/build-apk --release` (release build)
- `/build-apk --split` (split by ABI for smaller size)
- `/build-apk --install` (install to connected device after build)

**What It Does**:
```bash
# Debug build (default):
flutter build apk --debug --target-platform android-arm64

# Release build:
flutter build apk --release --target-platform android-arm64

# Split ABI:
flutter build apk --release --split-per-abi

# Install after build:
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Implementation Approach**:
- Parse flags to determine build type
- Show progress during build
- Display APK location after build
- Install to device if --install flag used

**Output Location**: `build/app/outputs/flutter-apk/`

**Error Handling**:
- Check for connected device (if --install flag)
- Handle build failures
- Show APK size after build

**Files to Create**:
- `.claude/skills/build-apk/skill.md`
- `.claude/skills/build-apk/skill.ts`

---

### 5. run-tests (Medium Priority)

**Purpose**: Run tests with useful options and coverage reporting

**User Commands**:
- `/test` or `/run-tests` (all tests)
- `/test --unit` (unit tests only)
- `/test --widget` (widget tests only)
- `/test --integration` (integration tests)
- `/test --coverage` (with coverage report)
- `/test --feature {name}` (tests for specific feature)

**What It Does**:
```bash
# All tests:
flutter test

# Unit tests only:
flutter test test/unit/

# Widget tests only:
flutter test test/widget/

# Integration tests:
flutter test integration_test/

# With coverage:
flutter test --coverage

# Specific feature:
flutter test test/unit/features/{feature}/
```

**Implementation Approach**:
- Parse flags to determine test scope
- Show test results summary (passed, failed, skipped)
- Display coverage percentage if --coverage flag
- Show detailed failures if tests fail

**Coverage Output**: `coverage/lcov.info`

**Error Handling**:
- Show test failures with stack traces
- Offer to run failed tests only
- Suggest which files to fix based on failures

**Files to Create**:
- `.claude/skills/run-tests/skill.md`
- `.claude/skills/run-tests/skill.ts`

---

## Implementation Plan

### Phase 1: Core Skills (Priority 1)

**Skills to Implement**:
1. `validate-build` - Most critical for daily workflow
2. `deploy-functions` - Essential for backend updates

**Steps**:
1. Create skill directory structure
2. Implement skill.md (description + examples)
3. Implement skill.ts (TypeScript execution logic)
4. Test each skill with actual commands
5. Document usage in project README

**Estimated Time**: 2-3 hours

---

### Phase 2: Code Generation (Priority 2)

**Skills to Implement**:
3. `generate-code` - Speeds up Riverpod/Freezed development

**Steps**:
1. Implement code generation detection
2. Add watch mode support
3. Handle build_runner conflicts
4. Show generation summary

**Estimated Time**: 1-2 hours

---

### Phase 3: Build & Test Skills (Priority 3)

**Skills to Implement**:
4. `build-apk` - Release automation
5. `run-tests` - Test workflow improvement

**Steps**:
1. Implement APK build with flags
2. Add device installation
3. Implement test runner with filters
4. Add coverage reporting

**Estimated Time**: 2-3 hours

---

## File Structure

```
.claude/
├── skills/
│   ├── validate-build/
│   │   ├── skill.md          # Skill description
│   │   └── skill.ts          # TypeScript implementation
│   ├── deploy-functions/
│   │   ├── skill.md
│   │   └── skill.ts
│   ├── generate-code/
│   │   ├── skill.md
│   │   └── skill.ts
│   ├── build-apk/
│   │   ├── skill.md
│   │   └── skill.ts
│   └── run-tests/
│       ├── skill.md
│       └── skill.ts
└── settings.local.json       # Update with skill permissions
```

---

## Skill Template

### skill.md Format:
```markdown
# Validate Build

Runs mandatory pre-build validation checks to ensure code quality.

## Usage

```
/validate-build
/validate-build --fix
```

## What It Does

1. Runs all unit and widget tests
2. Analyzes code for issues
3. Auto-fixes issues (with --fix flag)
4. Formats code
5. Verifies no issues remain

## Examples

Validate before building release:
```
/validate-build
```

Validate and auto-fix issues:
```
/validate-build --fix
```

## Requirements

- Flutter SDK installed
- All dependencies installed (flutter pub get)
- Tests passing before building
```

### skill.ts Format:
```typescript
import { Skill } from '@claude-ai/sdk';

export default {
  name: 'validate-build',
  description: 'Run pre-build validation checks',

  async execute(context) {
    const { args } = context;

    // Run tests
    await context.bash('flutter test');

    // Analyze code
    await context.bash('flutter analyze');

    // Format if --fix flag
    if (args.includes('--fix')) {
      await context.bash('dart fix --apply');
    }

    // Format code
    await context.bash('dart format .');

    return {
      success: true,
      message: '✅ Build validation complete',
    };
  },
} satisfies Skill;
```

---

## Testing Strategy

### For Each Skill:
1. **Manual Testing**: Run skill with various flags
2. **Error Cases**: Test with failing tests, compile errors
3. **Output Verification**: Ensure clear, helpful messages
4. **Integration**: Test with actual project workflows

### Test Cases:
- ✅ Skill runs successfully
- ✅ Correct flags are parsed
- ✅ Errors are handled gracefully
- ✅ Output is clear and actionable
- ✅ Permissions are properly configured

---

## Verification Checklist

After implementing all skills:

- [ ] All 5 skills work independently
- [ ] Skills handle error cases properly
- [ ] Clear usage documentation for each skill
- [ ] Skills are listed in `/skills` command
- [ ] Project README updated with skill usage
- [ ] Team trained on skill usage

---

## Success Criteria

✅ **Skills are successfully implemented when:**
1. All 5 skills execute without errors
2. Skills save time vs manual command execution
3. Error messages are clear and actionable
4. Skills are discoverable via `/skills` command
5. Documentation is complete and accurate
6. Team adopts skills in daily workflow

---

**Estimated Total Time**: 5-8 hours
**Difficulty**: Medium (requires TypeScript and Bash scripting knowledge)
**Risk Level**: Low (skills are additive, don't modify core codebase)
